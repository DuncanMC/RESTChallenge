//
//  TaskDetailView.swift
//  RESTChallenge
//

import SwiftUI

/// Shows the details of a single task and lets the user change its status
/// between pending and completed.
struct TaskDetailView: View {
    @Bindable var viewModel: TaskDetailViewModel

    var body: some View {
        Form {
            Section("Task") {
                Text(viewModel.state.todo.title)
            }
            Section("Details") {
                LabeledContent("Task ID", value: "\(viewModel.state.todo.id)")
                LabeledContent("Assigned User", value: "\(viewModel.state.todo.userId)")
            }
            Section("Status") {
                Picker("Status", selection: $viewModel.status) {
                    ForEach(TaskStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(viewModel: TaskDetailViewModel(
            todo: Todo(userId: 1, id: 1, title: "Sample task", completed: false)
        ))
    }
}
