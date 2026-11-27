# AI Doubt Solver - iOS (Swift, SwiftUI)

An AI tutor chat app where students pick a subject (Maths, Physics, Chemistry, Programming, General) and ask study doubts. Built with **iOS (Swift, SwiftUI)** as part of a cross-platform portfolio: the same product implemented in Flutter, React Native, native Android and native iOS.

## Features

- Chat with an AI tutor per subject; each subject keeps its own history
- Subject-specific system prompts (step-by-step maths, formulas for physics, code for programming)
- Works with any **OpenAI-compatible** Chat Completions API (OpenAI, Azure OpenAI, Groq, local LLM servers)
- **Offline demo mode**: with no API key the app uses a mock tutor, so it runs out of the box
- Chat history persisted locally and restored on app launch
- Failed questions are marked and can be retried without duplicating them
- Friendly error handling (network, invalid key, rate limit, server errors) with a 30 s timeout
- Only the last 12 messages are sent as context to control token cost
- Typing indicator, auto-scroll, long-press to copy, light/dark theme, accessibility labels
- Unit tests for the core chat logic

## Tech stack

- Swift 5.10, **SwiftUI**, iOS 17+
- Architecture: **MVVM** with the Observation framework (@Observable), protocol-oriented services
- Concurrency: **async/await**, @MainActor, Sendable types
- Persistence: **SwiftData**
- Networking: URLSession + Codable
- Project generation: XcodeGen (project.yml) - no merge conflicts in .xcodeproj
- Testing: XCTest

## Architecture

```
AIDoubtSolver/
  App/             AIDoubtSolverApp.swift (SwiftData container)
  Models/          Subject.swift, ChatMessage.swift (+ StoredMessage @Model)
  Services/        AIService.swift (protocol, OpenAI-compatible, mock, factory), SwiftDataChatStore.swift
  ViewModels/      ChatViewModel.swift (@Observable, @MainActor)
  Views/           ChatView.swift, Components.swift
AIDoubtSolverTests/ ChatViewModelTests.swift
Config/            Base.xcconfig, Secrets.example.xcconfig
```

UI -> state holder (ViewModel / Cubit / Redux slice) -> repository / service abstraction -> HTTP API + local storage. The AI provider is behind an interface, so it is swapped for a mock in tests and in demo mode.

## Getting started

```bash
brew install xcodegen
xcodegen generate
open AIDoubtSolver.xcodeproj
```

Optional, for real answers: copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` (git-ignored) and set `AI_API_KEY`. Without it the app runs in demo mode.

## Tests

```bash
xcodebuild test -scheme AIDoubtSolver -destination "platform=iOS Simulator,name=iPhone 15"
```

## Security note

API keys are never committed. They are read at build time from a git-ignored file / build flag. For production, route requests through your own backend so the key never ships inside the app.

## Author

**Reshma Dhawane** - Senior Mobile Developer (Flutter, React Native, Android, iOS)

## License

MIT
