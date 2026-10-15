//
//  TaskDashboardView.swift
//  RESTChallenge
//

import SwiftUI

/// The task dashboard: fetches tasks from the server, lets the user filter
/// them by status and ownership, drill into a task's details, refresh from
/// the API, and (eventually) post local edits back to the server.
struct TaskDashboardView: View {
    let viewModel: TaskDashboardViewModel

    var body: some View {
        @Bindable var state = viewModel.state

        List {
            Section {
                Picker("Status", selection: $state.filter) {
                    ForEach(TaskFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("statusFilterPicker")

                if viewModel.currentUserID != nil {
                    Toggle("My Tasks Only", isOn: $state.showOnlyMyTasks)
                        .accessibilityIdentifier("myTasksToggle")
                }
            }
            Section {
                ForEach(viewModel.filteredTodos) { todo in
                    NavigationLink(value: AppRoute.taskDetail(todo)) {
                        HStack {
                            Image(systemName: todo.status.systemImage)
                                .foregroundStyle(todo.status.tint)
                            Text(todo.title)
                                .lineLimit(1)
                        }
                    }
                    .accessibilityIdentifier("taskRow-\(todo.id)")
                }
            }
        }
        .overlay {
            if state.isLoading {
                ProgressView("Loading tasks…")
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let message = state.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("dashboardErrorMessage")
                }
                HStack {
                    Button("Refresh") {
                        Task { await viewModel.requestRefresh() }
                    }
                    .accessibilityIdentifier("refreshButton")
                    Spacer()
                    Button("Post Changes") {
                        viewModel.postChanges()
                    }
                    .disabled(!state.isDirty)
                    .accessibilityIdentifier("postChangesButton")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .alert("You have made changes but not posted them. Changes will be lost.",
               isPresented: $state.showDiscardWarning) {
            Button("Continue", role: .destructive) {
                Task { await viewModel.refresh() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Posting changes is not yet implemented. Changes will be lost on refresh.",
               isPresented: $state.showPostNotice) {
            Button("OK") {
                viewModel.acknowledgePostNotice()
            }
        }
        .navigationTitle("Task Dashboard")
        .task { await viewModel.loadTasksIfNeeded() }
    }
}

/// How each task status is drawn in the task list.
extension TaskStatus {
    var systemImage: String {
        switch self {
        case .pending: "clock.fill"
        case .completed: "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pending: .orange
        case .completed: .green
        }
    }
}

#Preview {
    NavigationStack {
        TaskDashboardView(viewModel: TaskDashboardViewModel())
    }
}
