//
//  SessionState.swift
//  RESTChallenge
//

import Foundation
import Observation

/// The user-facing authentication status shown on the login screen.
enum AuthStatus: Equatable {
    case signedOut
    case authenticating
    case authenticated
    case canceled
    case expired
    case unsuccessful(String)

    var message: String {
        switch self {
        case .signedOut:
            "Enter your username to log in."
        case .authenticating:
            "Logging in…"
        case .authenticated:
            "Logged in."
        case .canceled:
            "Login was canceled."
        case .expired:
            "Your session has expired. Please log in again."
        case .unsuccessful(let reason):
            "Login unsuccessful: \(reason)"
        }
    }
}

/// Session-wide state: login status and account info for the signed-in user.
/// Credentials themselves are owned by `AuthenticationManager` and are never
/// stored here.
@MainActor
@Observable
final class SessionState {
    /// The username entered on the login screen.
    var username = ""
    
    /// The current authentication status.
    var status: AuthStatus = .signedOut {
        didSet {
            switch status {
            case .unsuccessful(let reason):
                print("Login unsuccessful. Reason: \n \(reason)")
            default:
                break
            }
        }
    }

    /// Account info fetched from the `/users` API after login.
    var account: User?

    /// When the current session's tokens expire.
    var tokenExpiresAt: Date?

    var isAuthenticated: Bool {
        status == .authenticated
    }

    /// True when there is no live session or its tokens have expired.
    var isTimedOut: Bool {
        guard let tokenExpiresAt else { return true }
        return tokenExpiresAt <= Date()
    }

    /// Clears everything back to the signed-out state.
    func reset() {
        status = .signedOut
        account = nil
        tokenExpiresAt = nil
    }
}
