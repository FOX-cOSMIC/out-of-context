import Foundation

/// Talks to our Node server (server.js). The server holds the Claude API key and
/// does the local voice (Whisper + macOS voices), so the app never sees a key.
struct APIClient {
    /// Simulator: http://localhost:3000. Real phone: http://<this Mac's IP>:3000 (set in Settings).
    static var baseURL: URL {
        let saved = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        return URL(string: saved.isEmpty ? "http://localhost:3000" : saved) ?? URL(string: "http://localhost:3000")!
    }

    struct ServerError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    struct HistoryItem: Encodable {
        let role: String
        let text: String
        let image: String?
    }

    struct ChatRequest: Encodable {
        let history: [HistoryItem]
        let plan: Plan
        let taken: [String: Bool]
        let today: String
        let skills: [String]
    }

    func chat(_ request: ChatRequest) async throws -> ChatReply {
        var urlRequest = URLRequest(url: Self.baseURL.appending(path: "api/chat"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 120
        return try JSONDecoder().decode(ChatReply.self, from: try await send(urlRequest))
    }

    func transcribe(audioFile: URL) async throws -> String {
        var urlRequest = URLRequest(url: Self.baseURL.appending(path: "api/transcribe"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("audio/mp4", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try Data(contentsOf: audioFile)
        urlRequest.timeoutInterval = 60
        struct Result: Decodable { let text: String }
        return try JSONDecoder().decode(Result.self, from: try await send(urlRequest)).text
    }

    func speak(_ text: String) async throws -> Data {
        var urlRequest = URLRequest(url: Self.baseURL.appending(path: "api/speak"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(["text": text])
        urlRequest.timeoutInterval = 30
        return try await send(urlRequest)
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ServerError(message: "I can't reach the helper right now. Is the computer on and the server running?")
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        struct ErrorBody: Decodable { let error: String }
        if let body = try? JSONDecoder().decode(ErrorBody.self, from: data) {
            throw ServerError(message: body.error)
        }
        guard (200..<300).contains(status) else {
            throw ServerError(message: "That did not work just now. Please try again.")
        }
        return data
    }
}
