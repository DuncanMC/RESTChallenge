//
//  TaskDetailViewModel.swift
//  RESTChallenge
//

import Foundation
import Observation

/// Business logic for the task detail screen. Status edits are written back
/// to the dashboard's state so the list reflects them, and the dashboard is
/// marked dirty so the user is warned before unposted edits are discarded.
@MainActor
@Observable
final class TaskDetailViewModel {
    let state: TaskDetailState
    private let dashboardState: TaskDashboardState?

    init(todo: Todo, dashboardState: TaskDashboardState? = nil) {
        self.state = TaskDetailState(todo: todo)
        self.dashboardState = dashboardState
    }

    /// The task's status, editable from the detail screen's segmented control.
    var status: TaskStatus {
        get { state.todo.status }
        set { setCompleted(newValue == .completed) }
    }

    private func setCompleted(_ completed: Bool) {
        guard state.todo.completed != completed else { return }
        state.todo.completed = completed
        guard let dashboardState,
              let index = dashboardState.todos.firstIndex(where: { $0.id == state.todo.id }) else {
            return
        }
        dashboardState.todos[index].completed = completed
        dashboardState.isDirty = true
    }
}
