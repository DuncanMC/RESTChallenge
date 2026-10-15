//
//  AuthenticationManaging.swift
//  RESTChallenge
//

import Foundation

/// Abstraction over the authentication layer so UI tests can substitute a
/// mock that bypasses the real Auth0 web flow.
protocol AuthenticationManaging: Actor {
    /// Authenticates and returns the session's token expiration date.
    func logIn(username: String) async throws -> Date

    /// Ends the session and removes stored tokens.
    func logOut() async throws

    /// Restores a stored session, returning its expiration date.
    func restoreSession() async throws -> Date

    /// Returns the stored access token for authorizing API calls.
    func accessToken() async throws -> String
}

extension AuthenticationManager: AuthenticationManaging {}
