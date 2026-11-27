import Foundation
import SwiftData

enum Role: String, Codable, Sendable { case user, assistant }
enum MessageStatus: String, Codable, Sendable { case sent, failed }

/// Value type used by the view model and services.
struct ChatMessage: Identifiable, Equatable, Sendable {
    let id: UUID
    let role: Role
    let text: String
    let createdAt: Date
    var status: MessageStatus

    init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = .now, status: MessageStatus = .sent) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.status = status
    }

    var isUser: Bool { role == .user }
}

/// SwiftData persistence model (one row per message).
@Model
final class StoredMessage {
    @Attribute(.unique) var id: UUID
    var subject: String
    var role: String
    var text: String
    var createdAt: Date
    var status: String

    init(_ m: ChatMessage, subject: Subject) {
        id = m.id
        self.subject = subject.rawValue
        role = m.role.rawValue
        text = m.text
        createdAt = m.createdAt
        status = m.status.rawValue
    }

    var asMessage: ChatMessage {
        ChatMessage(
            id: id,
            role: Role(rawValue: role) ?? .user,
            text: text,
            createdAt: createdAt,
            status: MessageStatus(rawValue: status) ?? .sent
        )
    }
}
