//
//  MockURLProtocol.swift
//  RESTChallenge
//

#if DEBUG
import Foundation

/// Intercepts all requests on the UI-test URLSession and serves the bundled
/// fixture payloads instead of hitting the network. The UITEST_USERS and
/// UITEST_TODOS launch environment variables select per-endpoint behavior:
/// "ok" (default), "malformed", or "timeout".
nonisolated final class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let environment = ProcessInfo.processInfo.environment
        let path = request.url?.path ?? ""

        let mode: String
        let payload: String
        if path.hasSuffix("/todos") {
            mode = environment["UITEST_TODOS"] ?? "ok"
            payload = TestFixtures.todosJSON
        } else if path.hasSuffix("/users") {
            mode = environment["UITEST_USERS"] ?? "ok"
            payload = TestFixtures.usersJSON
        } else {
            mode = "ok"
            payload = "[]"
        }

        switch mode {
        case "timeout":
            let timeout = NSError(domain: NSURLErrorDomain,
                                  code: NSURLErrorTimedOut,
                                  userInfo: [NSLocalizedDescriptionKey: "The request timed out."])
            client?.urlProtocol(self, didFailWithError: timeout)
        case "malformed":
            send(Data(TestFixtures.malformedJSON.utf8))
        default:
            send(Data(payload.utf8))
        }
    }

    override func stopLoading() {}

    private func send(_ data: Data) {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url,
                                             statusCode: 200,
                                             httpVersion: nil,
                                             headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}
#endif
