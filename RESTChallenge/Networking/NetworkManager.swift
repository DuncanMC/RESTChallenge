//
//  NetworkManager.swift
//  RESTChallenge
//

import Foundation

/// Errors thrown by `NetworkManager` when a request cannot be completed.
enum NetworkError: LocalizedError {
    case requestFailed(statusCode: Int)
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let statusCode):
            "The server returned status code \(statusCode)."
        case .decodingFailed(let underlying):
            "Could not decode the server response: \(underlying.localizedDescription)"
        }
    }
}

/// Makes RESTful GET calls to the JSONPlaceholder API for users and tasks.
actor NetworkManager {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(baseURL: URL = URL(string: "https://jsonplaceholder.typicode.com")!,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Fetches the list of users from the `/users` endpoint.
    func fetchUsers() async throws -> [User] {
        try await get("users")
    }

    /// Fetches the list of tasks from the `/todos` endpoint.
    func fetchTodos() async throws -> [Todo] {
        try await get("todos")
    }

    private func get<Value: Decodable>(_ path: String) async throws -> Value {
        let url = baseURL.appendingPathComponent(path)
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw NetworkError.requestFailed(statusCode: http.statusCode)
        }
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }
}
