//
//  User.swift
//  RESTChallenge
//

import Foundation

/// An account record returned by the JSONPlaceholder `/users` API.
struct User: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
}
