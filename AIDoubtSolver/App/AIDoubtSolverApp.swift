import SwiftData
import SwiftUI

@main
struct AIDoubtSolverApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView(service: AIServiceFactory.make())
        }
        .modelContainer(for: StoredMessage.self)
    }
}
