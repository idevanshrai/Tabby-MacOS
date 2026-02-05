import SwiftUI

@main
struct TabbyApp: App {
    @StateObject private var tabManager = TabManager()
    
    var body: some Scene {
        MenuBarExtra("Tabby", systemImage: "safari") {
            ContentView()
                .environmentObject(tabManager)
        }
        .menuBarExtraStyle(.window) // Allows a popover window
    }
}
