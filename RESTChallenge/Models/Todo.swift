//
//  Todo.swift
//  RESTChallenge
//

import Foundation

/// The two task states shown in the app, derived from the completed flag:
/// a task is pending unless it is completed.
enum TaskStatus: String, CaseIterable, Identifiable, Sendable {
    case pending = "Pending"
    case completed = "Completed"

    var id: String { rawValue }
}

/// A task record returned by the JSONPlaceholder `/todos` API.
/// `completed` is mutable so the user can change a task's status locally
/// before posting it back to the server.
struct Todo: Codable, Identifiable, Hashable, Sendable {
    let userId: Int
    let id: Int
    let title: String
    var completed: Bool

    /// The task's status: completed when the flag is set, pending otherwise.
    var status: TaskStatus {
        completed ? .completed : .pending
    }
}
