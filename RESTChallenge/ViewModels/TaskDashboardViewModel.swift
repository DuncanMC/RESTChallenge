//
//  TaskDashboardViewModel.swift
//  RESTChallenge
//

import Foundation
import Observation

/// Business logic for the task dashboard screen: loads tasks from the
/// `/todos` API, applies the status and ownership filters selected in
/// `TaskDashboardState`, and tracks unposted local edits.
@MainActor
@Observable
final class TaskDashboardViewModel {
    let state = TaskDashboardState()

    private let session: SessionState?
    private let networkManager: NetworkManager

    init(session: SessionState? = nil,
         networkManager: NetworkManager = NetworkManager()) {
        self.session = session
        self.networkManager = networkManager
    }

    /// The signed-in user's JSONPlaceholder id, used by the My Tasks filter.
    var currentUserID: Int? { session?.account?.id }

    /// The task list with the ownership and status filters applied.
    var filteredTodos: [Todo] {
        var todos = state.todos
        if state.showOnlyMyTasks, let currentUserID {
            todos = todos.filter { $0.userId == currentUserID }
        }
        if let status = state.filter.status {
            todos = todos.filter { $0.status == status }
        }
        return todos
    }

    /// Loads tasks on first appearance only, so returning to the dashboard
    /// never silently discards local edits.
    func loadTasksIfNeeded() async {
        guard state.todos.isEmpty else { return }
        await refresh()
    }

    /// Called by the Refresh button: warns before discarding unposted
    /// edits, otherwise refreshes immediately.
    func requestRefresh() async {
        if state.isDirty {
            state.showDiscardWarning = true
        } else {
            await refresh()
        }
    }

    /// Replaces the task list with fresh data from the API, discarding any
    /// local edits.
    func refresh() async {
        state.isLoading = true
        state.errorMessage = nil
        do {
            state.todos = try await networkManager.fetchTodos()
            state.isDirty = false
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isLoading = false
    }

    /// Called by the Post Changes button. Posting isn't implemented yet,
    /// so this just surfaces the notice; the dirty flag is cleared when the
    /// user acknowledges it.
    func postChanges() {
        state.showPostNotice = true
    }

    func acknowledgePostNotice() {
        state.isDirty = false
    }
}
