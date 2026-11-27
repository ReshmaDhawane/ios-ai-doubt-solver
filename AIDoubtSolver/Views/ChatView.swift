import SwiftData
import SwiftUI

/// Entry view: builds the view model once the SwiftData context is available.
struct ChatView: View {
    let service: AIService
    @Environment(\.modelContext) private var context
    @State private var viewModel: ChatViewModel?

    var body: some View {
        Group {
            if let viewModel {
                ChatContentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = ChatViewModel(service: service, store: SwiftDataChatStore(context: context))
            }
        }
    }
}

struct ChatContentView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var input = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SubjectPicker(selected: viewModel.subject) { viewModel.select($0) }

                if AIServiceFactory.isDemo {
                    Text("Demo mode: no API key configured.")
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(.yellow.opacity(0.25))
                }

                messageList
                inputBar
            }
            .navigationTitle("AI Doubt Solver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Clear", systemImage: "trash") { viewModel.clear() }
            }
            .alert(
                "Could not get an answer",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.messages.isEmpty && !viewModel.isThinking {
                        Text("Ask your first \(viewModel.subject.label) doubt")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 60)
                    }
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message) {
                            Task { await viewModel.retry(message) }
                        }
                        .id(message.id)
                    }
                    if viewModel.isThinking {
                        TypingIndicator()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("typing")
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation { proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom) }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Type your doubt...", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
            Button {
                let text = input
                input = ""
                Task { await viewModel.send(text) }
            } label: {
                Image(systemName: "paperplane.fill")
                    .padding(10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isThinking || input.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Send")
        }
        .padding(8)
        .background(.bar)
    }
}

#Preview {
    ChatView(service: MockAIService())
        .modelContainer(for: StoredMessage.self, inMemory: true)
}
