import Foundation
import Observation

/// Persistence boundary so the view model is testable without SwiftData.
@MainActor
protocol ChatStore {
    func load(_ subject: Subject) -> [ChatMessage]
    func save(_ messages: [ChatMessage], for subject: Subject)
}

@MainActor
@Observable
final class ChatViewModel {
    private(set) var subject: Subject = .general
    private(set) var messages: [ChatMessage] = []
    private(set) var isThinking = false
    var errorMessage: String?

    private let service: AIService
    private let store: ChatStore

    init(service: AIService, store: ChatStore) {
        self.service = service
        self.store = store
        messages = store.load(subject)
    }

    func select(_ subject: Subject) {
        self.subject = subject
        messages = store.load(subject)
        errorMessage = nil
    }

    func send(_ raw: String) async {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        let question = ChatMessage(role: .user, text: text)
        messages.append(question)
        await ask(about: question.id)
    }

    func retry(_ message: ChatMessage) async {
        guard !isThinking, let i = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[i].status = .sent
        await ask(about: message.id)
    }

    func clear() {
        messages = []
        store.save([], for: subject)
    }

    private func ask(about questionID: UUID) async {
        isThinking = true
        errorMessage = nil
        defer {
            isThinking = false
            store.save(messages, for: subject)
        }
        do {
            let answer = try await service.ask(subject: subject, history: messages)
            messages.append(ChatMessage(role: .assistant, text: answer))
        } catch {
            if let i = messages.firstIndex(where: { $0.id == questionID }) {
                messages[i].status = .failed
            }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
        }
    }
}
