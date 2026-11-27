import Foundation

enum AIServiceError: LocalizedError, Equatable {
    case network, invalidKey, rateLimited, server(Int), badResponse

    var errorDescription: String? {
        switch self {
        case .network: "Network error. Check your connection."
        case .invalidKey: "Invalid API key."
        case .rateLimited: "Rate limited. Please try again shortly."
        case .server(let code): "Server error (\(code))."
        case .badResponse: "Unexpected response from server."
        }
    }
}

protocol AIService: Sendable {
    func ask(subject: Subject, history: [ChatMessage]) async throws -> String
}

/// Works with any OpenAI-compatible Chat Completions endpoint.
struct OpenAICompatibleService: AIService {
    let apiKey: String
    let model: String
    var baseURL = URL(string: "https://api.openai.com/v1")!
    var session: URLSession = .shared

    private struct Message: Codable { let role: String; let content: String }
    private struct Request: Encodable { let model: String; let temperature: Double; let messages: [Message] }
    private struct Response: Decodable {
        struct Choice: Decodable { let message: Message }
        let choices: [Choice]
    }

    func ask(subject: Subject, history: [ChatMessage]) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages = [Message(role: "system", content: subject.systemPrompt)]
            + history.suffix(12).map { Message(role: $0.isUser ? "user" : "assistant", content: $0.text) }
        request.httpBody = try JSONEncoder().encode(Request(model: model, temperature: 0.3, messages: messages))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIServiceError.network
        }

        guard let http = response as? HTTPURLResponse else { throw AIServiceError.badResponse }
        switch http.statusCode {
        case 200..<300: break
        case 401: throw AIServiceError.invalidKey
        case 429: throw AIServiceError.rateLimited
        default: throw AIServiceError.server(http.statusCode)
        }

        guard let content = try? JSONDecoder().decode(Response.self, from: data).choices.first?.message.content
        else { throw AIServiceError.badResponse }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Offline tutor used when no API key is configured.
struct MockAIService: AIService {
    func ask(subject: Subject, history: [ChatMessage]) async throws -> String {
        try await Task.sleep(for: .milliseconds(700))
        let question = history.last(where: \.isUser)?.text ?? ""
        return """
        (\(subject.label) demo tutor) Great question: "\(question)".

        1. Identify what is given and what is asked.
        2. Recall the core concept or formula.
        3. Apply it step by step and check units.

        Add AI_API_KEY in Config/Secrets.xcconfig for real answers.
        """
    }
}

enum AIServiceFactory {
    static func make(bundle: Bundle = .main) -> AIService {
        let key = (bundle.object(forInfoDictionaryKey: "AI_API_KEY") as? String) ?? ""
        let model = (bundle.object(forInfoDictionaryKey: "AI_MODEL") as? String).flatMap { $0.isEmpty ? nil : $0 }
        guard !key.isEmpty else { return MockAIService() }
        return OpenAICompatibleService(apiKey: key, model: model ?? "gpt-4o-mini")
    }

    static var isDemo: Bool {
        ((Bundle.main.object(forInfoDictionaryKey: "AI_API_KEY") as? String) ?? "").isEmpty
    }
}
