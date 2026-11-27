import XCTest
@testable import AIDoubtSolver

private struct StubService: AIService {
    var result: Result<String, AIServiceError>
    func ask(subject: Subject, history: [ChatMessage]) async throws -> String { try result.get() }
}

@MainActor
private final class InMemoryStore: ChatStore {
    var data: [Subject: [ChatMessage]] = [:]
    func load(_ subject: Subject) -> [ChatMessage] { data[subject] ?? [] }
    func save(_ messages: [ChatMessage], for subject: Subject) { data[subject] = messages }
}

@MainActor
final class ChatViewModelTests: XCTestCase {

    func testSendAppendsQuestionAndAnswerAndPersists() async {
        let store = InMemoryStore()
        let vm = ChatViewModel(service: StubService(result: .success("4")), store: store)

        await vm.send("  2 + 2?  ")

        XCTAssertEqual(vm.messages.map(\.text), ["2 + 2?", "4"])
        XCTAssertFalse(vm.isThinking)
        XCTAssertEqual(store.data[.general]?.count, 2)
    }

    func testFailureMarksQuestionFailedAndShowsError() async {
        let vm = ChatViewModel(service: StubService(result: .failure(.network)), store: InMemoryStore())

        await vm.send("What is inertia?")

        XCTAssertEqual(vm.messages.single?.status, .failed)
        XCTAssertEqual(vm.errorMessage, AIServiceError.network.errorDescription)
    }

    func testBlankInputIsIgnored() async {
        let vm = ChatViewModel(service: StubService(result: .success("x")), store: InMemoryStore())
        await vm.send("   ")
        XCTAssertTrue(vm.messages.isEmpty)
    }

    func testSubjectsKeepSeparateHistories() async {
        let store = InMemoryStore()
        let vm = ChatViewModel(service: StubService(result: .success("ok")), store: store)
        vm.select(.physics)
        await vm.send("Newton's 2nd law?")
        vm.select(.maths)
        XCTAssertTrue(vm.messages.isEmpty)
        vm.select(.physics)
        XCTAssertEqual(vm.messages.count, 2)
    }
}

private extension Array {
    var single: Element? { count == 1 ? first : nil }
}
