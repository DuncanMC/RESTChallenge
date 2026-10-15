//
//  RESTChallengeApp.swift
//  RESTChallenge
//
//  Created by Duncan Champney on 10/15/26.
//

import SwiftUI

@main
struct RESTChallengeApp: App {
    @State private var loginViewModel = LoginViewModel()

    var body: some Scene {
        WindowGroup {
            LoginView(viewModel: loginViewModel)
        }
    }
}
