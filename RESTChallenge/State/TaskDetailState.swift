//
//  TaskDetailState.swift
//  RESTChallenge
//

import Foundation
import Observation

/// State for the task detail screen.
@MainActor
@Observable
final class TaskDetailState {
    var todo: Todo

    init(todo: Todo) {
        self.todo = todo
    }
}
