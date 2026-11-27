import SwiftUI

struct SubjectPicker: View {
    let selected: Subject
    let onSelect: (Subject) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Subject.allCases) { subject in
                    Button(subject.label) { onSelect(subject) }
                        .buttonStyle(.bordered)
                        .tint(subject == selected ? .indigo : .secondary)
                        .accessibilityAddTraits(subject == selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let onRetry: () -> Void

    private var failed: Bool { message.status == .failed }

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                Text(message.text)
                    .textSelection(.enabled)
                    .foregroundStyle(message.isUser && !failed ? .white : .primary)
                if failed {
                    Button("Retry", systemImage: "arrow.clockwise", action: onRetry)
                        .font(.footnote.bold())
                        .tint(.red)
                }
            }
            .padding(12)
            .background(
                failed ? Color.red.opacity(0.15) : message.isUser ? Color.indigo : Color(.secondarySystemBackground),
                in: .rect(cornerRadius: 16)
            )
            .contextMenu {
                Button("Copy", systemImage: "doc.on.doc") { UIPasteboard.general.string = message.text }
            }
            if !message.isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 12)
    }
}

struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .opacity(phase == Double(i) ? 1 : 0.3)
            }
        }
        .foregroundStyle(.indigo)
        .padding(16)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation { phase = (phase + 1).truncatingRemainder(dividingBy: 3) }
            }
        }
        .accessibilityLabel("Tutor is typing")
    }
}
