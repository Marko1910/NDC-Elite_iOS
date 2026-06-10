import SwiftUI

@main
struct NDC_EliteApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
                .task {
                    await session.start()
                }
        }
    }
}
