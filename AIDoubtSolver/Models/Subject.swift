import Foundation

enum Subject: String, CaseIterable, Identifiable, Codable, Sendable {
    case maths, physics, chemistry, programming, general

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    private var styleHint: String {
        switch self {
        case .maths: "Explain step by step with worked examples."
        case .physics: "Use formulas, units and real-life intuition."
        case .chemistry: "Mention reactions and balanced equations where relevant."
        case .programming: "Give short, runnable code snippets."
        case .general: "Answer clearly and concisely."
        }
    }

    var systemPrompt: String {
        "You are a friendly \(label) tutor for students. \(styleHint) "
            + "If the question is ambiguous, ask one clarifying question. Keep answers under 250 words."
    }
}
