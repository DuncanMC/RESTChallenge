//
//  LoginView.swift
//  RESTChallenge
//

import SwiftUI

/// Navigation destinations pushed onto the app's single NavigationStack.
/// All destinations are registered at the stack root in `LoginView` —
/// registering value destinations on pushed screens (or mixing in
/// view-destination links) breaks the push order.
enum AppRoute: Hashable {
    case taskDashboard
    case taskDetail(Todo)
}

/// The initial login/logout screen. Collects a username, starts Auth0
/// authentication, shows the session status, and links to the task
/// dashboard once the user is authenticated.
struct LoginView: View {
    let viewModel: LoginViewModel

    var body: some View {
        @Bindable var session = viewModel.session

        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.badge.key")
                    .imageScale(.large)
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)

                if let account = session.account {
                    VStack(spacing: 4) {
                        Text(account.name)
                            .font(.headline)
                            .accessibilityIdentifier("accountName")
                        Text(account.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("accountEmail")
                    }
                } else {
                    TextField("Username", text: $session.username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("usernameField")
                }

                Text(viewModel.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("loginStatusMessage")

                Button(viewModel.loginButtonTitle) {
                    Task { await viewModel.logInOrOut() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier("loginButton")

                NavigationLink("Manage Tasks", value: AppRoute.taskDashboard)
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canManageTasks)
                    .accessibilityIdentifier("manageTasksButton")
            }
            .padding()
            .navigationTitle("Account")
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .taskDashboard:
                    TaskDashboardView(viewModel: viewModel.dashboardViewModel)
                case .taskDetail(let todo):
                    TaskDetailView(viewModel: TaskDetailViewModel(
                        todo: todo,
                        dashboardState: viewModel.dashboardViewModel.state
                    ))
                }
            }
            .task { await viewModel.restoreSession() }
        }
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel())
}
