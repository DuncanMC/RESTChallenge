//
//  TaskDashboardState.swift
//  RESTChallenge
//

import Foundation
import Observation

/// Filtering options for the task dashboard list: all tasks regardless of
/// state, or only completed or pending tasks.
enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case completed = "Completed"
    case pending = "Pending"

    var id: String { rawValue }

    /// The task status this filter matches, or nil for all tasks.
    var status: TaskStatus? {
        switch self {
        case .all: nil
        case .completed: .completed
        case .pending: .pending
        }
    }
}

/// State for the task dashboard screen.
@MainActor
@Observable
final class TaskDashboardState {
    var todos: [Todo] = []
    var filter: TaskFilter = .all

    /// When true (the default), only the signed-in user's tasks are shown.
    var showOnlyMyTasks = true

    /// True when the user has local task edits that haven't been posted.
    var isDirty = false

    /// Drives the "changes will be lost" confirmation before a refresh.
    var showDiscardWarning = false

    /// Drives the "posting not yet implemented" notice.
    var showPostNotice = false

    var isLoading = false

    /// Error text (API failures, network problems) shown at the bottom of
    /// the dashboard; nil when there is nothing to report.
    var errorMessage: String?
}
