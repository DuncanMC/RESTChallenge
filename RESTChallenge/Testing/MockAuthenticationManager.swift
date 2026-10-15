//
//  MockAuthenticationManager.swift
//  RESTChallenge
//

#if DEBUG
import Foundation

/// Stand-in for `AuthenticationManager` used by UI tests. The real flow
/// collects the password on Auth0's hosted web page, which can't run in
/// automation, so the "typed" password is supplied by the test via the
/// UITEST_PASSWORD launch environment variable and validated against the
/// known test account.
actor MockAuthenticationManager: AuthenticationManaging {
    static let validEmail = "sincere@april.biz"
    static let validPassword = "Crashes.receded.bond"

    private var isLoggedIn = false
    private let attemptedPassword =
        ProcessInfo.processInfo.environment["UITEST_PASSWORD"] ?? ""

    func logIn(username: String) async throws -> Date {
        let email = username.trimmingCharacters(in: .whitespaces).lowercased()
        guard email == Self.validEmail,
              attemptedPassword == Self.validPassword else {
            throw AuthenticationError.unsuccessful("Wrong email or password.")
        }
        isLoggedIn = true
        return Date().addingTimeInterval(3600)
    }

    func logOut() async throws {
        isLoggedIn = false
    }

    func restoreSession() async throws -> Date {
        guard isLoggedIn else { throw AuthenticationError.noActiveSession }
        return Date().addingTimeInterval(3600)
    }

    func accessToken() async throws -> String {
        guard isLoggedIn else { throw AuthenticationError.noActiveSession }
        return "mock-access-token"
    }
}
#endif
