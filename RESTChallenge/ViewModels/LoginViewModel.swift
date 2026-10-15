//
//  LoginViewModel.swift
//  RESTChallenge
//

import Foundation
import Observation

/// Business logic for the login/logout screen.
///
/// Drives `AuthenticationManager` for login/logout, updates `SessionState`
/// with the results, and exposes view-ready values derived from that state
/// so the view updates automatically as the session changes.
@MainActor
@Observable
final class LoginViewModel {
    let session: SessionState

    /// The dashboard's view model, owned here so the session and task state
    /// stay alive across navigation.
    let dashboardViewModel: TaskDashboardViewModel

    private let authManager: any AuthenticationManaging
    private let networkManager: NetworkManager

    init(session: SessionState? = nil,
         authManager: any AuthenticationManaging = AuthenticationManager(),
         networkManager: NetworkManager = NetworkManager()) {
        let resolvedSession = session ?? SessionState()
        self.session = resolvedSession
        self.dashboardViewModel = TaskDashboardViewModel(session: resolvedSession,
                                                         networkManager: networkManager)
        self.authManager = authManager
        self.networkManager = networkManager
    }

    // MARK: - View-facing state derived from SessionState

    var statusMessage: String { session.accountLoadError ?? session.status.message }

    var isLoggedIn: Bool { session.isAuthenticated }

    /// Manage Tasks is only available while authenticated and not timed out.
    var canManageTasks: Bool { session.isAuthenticated && !session.isTimedOut }

    var loginButtonTitle: String { isLoggedIn ? "Log Out" : "Log In" }

    var canSubmit: Bool {
        guard session.status != .authenticating else { return false }
        return isLoggedIn
            || !session.username.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    /// Restores a stored session from the keychain at launch, surfacing an
    /// expired status when the stored tokens have timed out.
    func restoreSession() async {
        do {
            let expiresAt = try await authManager.restoreSession()
            session.tokenExpiresAt = expiresAt
            session.status = .authenticated
            await loadAccount()
        } catch AuthenticationError.expired {
            session.reset()
            session.status = .expired
        } catch {
            session.reset()
        }
    }

    /// Logs in when signed out, logs out when signed in.
    func logInOrOut() async {
        if isLoggedIn {
            await logOut()
        } else {
            await logIn()
        }
    }

    private func logIn() async {
        session.status = .authenticating
        do {
            let expiresAt = try await authManager.logIn(username: session.username)
            session.tokenExpiresAt = expiresAt
            session.status = .authenticated
            await loadAccount()
        } catch AuthenticationError.canceled {
            session.reset()
            session.status = .canceled
        } catch AuthenticationError.expired {
            session.reset()
            session.status = .expired
        } catch {
            session.reset()
            session.status = .unsuccessful(error.localizedDescription)
        }
    }

    private func logOut() async {
        do {
            try await authManager.logOut()
            session.reset()
        } catch AuthenticationError.canceled {
            // The user dismissed the logout prompt; the session is still live.
            session.status = .authenticated
        } catch {
            session.status = .unsuccessful(error.localizedDescription)
        }
    }

    /// Fetches account info from the `/users` API after a successful login,
    /// matching the entered username where possible.
    private func loadAccount() async {
        session.accountLoadError = nil
        do {
            let users = try await networkManager.fetchUsers()
            let entered = session.username
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            session.account = users.first { $0.email.lowercased() == entered }
//            session.account = users.first { $0.username.lowercased() == entered }
//                ?? users.first { $0.email.lowercased() == entered }
//                ?? users.first
        } catch {
            // Authentication already succeeded; report the lookup failure
            // without invalidating the session.
            session.accountLoadError =
                "Could not load account info: \(error.localizedDescription)"
        }
    }
}
