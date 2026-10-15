//
//  RESTChallengeApp.swift
//  RESTChallenge
//
//  Created by Duncan Champney on 10/15/26.
//

import SwiftUI

@main
struct RESTChallengeApp: App {
    @State private var loginViewModel = makeLoginViewModel()

    var body: some Scene {
        WindowGroup {
            LoginView(viewModel: loginViewModel)
        }
    }
}

/// Builds the real view model, or one backed by mock authentication and
/// fixture network data when launched by the UI tests.
@MainActor
private func makeLoginViewModel() -> LoginViewModel {
#if DEBUG
    if ProcessInfo.processInfo.environment["UITEST_MODE"] == "1" {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return LoginViewModel(
            authManager: MockAuthenticationManager(),
            networkManager: NetworkManager(session: URLSession(configuration: configuration))
        )
    }
#endif
    return LoginViewModel()
}
