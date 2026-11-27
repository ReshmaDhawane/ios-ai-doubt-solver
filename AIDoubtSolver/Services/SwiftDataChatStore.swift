import Foundation
import SwiftData

@MainActor
struct SwiftDataChatStore: ChatStore {
    let context: ModelContext

    func load(_ subject: Subject) -> [ChatMessage] {
        let raw = subject.rawValue
        let descriptor = FetchDescriptor<StoredMessage>(
            predicate: #Predicate { $0.subject == raw },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return ((try? context.fetch(descriptor)) ?? []).map(\.asMessage)
    }

    func save(_ messages: [ChatMessage], for subject: Subject) {
        let raw = subject.rawValue
        try? context.delete(model: StoredMessage.self, where: #Predicate { $0.subject == raw })
        messages.forEach { context.insert(StoredMessage($0, subject: subject)) }
        try? context.save()
    }
}
