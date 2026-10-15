//
//  AuthenticationManager.swift
//  RESTChallenge
//

import Foundation
import Auth0
import SimpleKeychain

/// Errors surfaced by the authentication flow, mapped to user-facing states.
enum AuthenticationError: LocalizedError {
    case canceled
    case expired
    case unsuccessful(String)
    case noActiveSession

    var errorDescription: String? {
        switch self {
        case .canceled:
            "Authentication was canceled."
        case .expired:
            "Your session has expired. Please log in again."
        case .unsuccessful(let reason):
            "Authentication failed: \(reason)"
        case .noActiveSession:
            "No active session was found."
        }
    }
}

/// Manages Auth0 login/logout and secure token storage.
///
/// Uses the Auth0 package (configured via `Auth0.plist`) for web
/// authentication and stores the returned tokens in the keychain with
/// SimpleKeychain. Tokens never leave this actor; callers only receive the
/// session expiration date.
actor AuthenticationManager {
    private enum KeychainKey {
        static let accessToken = "auth0.accessToken"
        static let idToken = "auth0.idToken"
        static let refreshToken = "auth0.refreshToken"
        static let expiresAt = "auth0.expiresAt"
    }

    private let keychain = SimpleKeychain(service: "RESTChallenge")
    private let dateFormatter = ISO8601DateFormatter()

    /// Starts the Auth0 web authentication flow, passing the entered
    /// username as a login hint, and securely stores the returned tokens.
    /// - Returns: The date the new session's tokens expire.
    func logIn(username: String) async throws -> Date {
        do {
            let credentials = try await Auth0
                .webAuth()
                .useHTTPS()
                .parameters(["login_hint": username])
                .start()
            try storeTokens(from: credentials)
            return credentials.expiresAt
        } catch let error as WebAuthError where error == .userCancelled {
            throw AuthenticationError.canceled
        } catch {
            throw AuthenticationError.unsuccessful(error.localizedDescription)
        }
    }

    /// Ends the Auth0 web session and removes all stored tokens.
    func logOut() async throws {
        do {
            try await Auth0.webAuth().useHTTPS().logout()
        } catch let error as WebAuthError where error == .userCancelled {
            throw AuthenticationError.canceled
        } catch {
            throw AuthenticationError.unsuccessful(error.localizedDescription)
        }
        try clearTokens()
    }

    /// Restores a previously stored session from the keychain.
    /// - Returns: The stored session's expiration date.
    /// - Throws: `.noActiveSession` if no tokens are stored, or `.expired`
    ///   (after clearing the stale tokens) if the session has timed out.
    func restoreSession() throws -> Date {
        guard try keychain.hasItem(forKey: KeychainKey.expiresAt),
              let expiresAt = dateFormatter.date(
                from: try keychain.string(forKey: KeychainKey.expiresAt)
              ) else {
            throw AuthenticationError.noActiveSession
        }
        guard expiresAt > Date() else {
            try clearTokens()
            throw AuthenticationError.expired
        }
        return expiresAt
    }

    /// Returns the stored access token for authorizing API calls.
    /// - Throws: `.noActiveSession` if the user has not logged in.
    func accessToken() throws -> String {
        guard try keychain.hasItem(forKey: KeychainKey.accessToken) else {
            throw AuthenticationError.noActiveSession
        }
        return try keychain.string(forKey: KeychainKey.accessToken)
    }

    private func storeTokens(from credentials: Credentials) throws {
        try keychain.set(credentials.accessToken, forKey: KeychainKey.accessToken)
        try keychain.set(credentials.idToken, forKey: KeychainKey.idToken)
        if let refreshToken = credentials.refreshToken {
            try keychain.set(refreshToken, forKey: KeychainKey.refreshToken)
        }
        try keychain.set(dateFormatter.string(from: credentials.expiresAt),
                         forKey: KeychainKey.expiresAt)
    }

    private func clearTokens() throws {
        try keychain.deleteAll()
    }
}
