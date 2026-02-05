import SwiftUI

struct TabMetadata: Codable {
    var note: String?
    var reminderDate: Date?
}

import UserNotifications

@MainActor
class TabManager: ObservableObject {
    @Published var tabs: [TabItem] = []
    private var persistence: [String: TabMetadata] = [:]
    
    init() {
        loadPersistence()
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("⚠️ Bundle Identifier is nil. Notifications are disabled in 'swift run' mode. Run via Xcode or as a .app to enable.")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func refreshTabs() {
        var allTabs: [TabItem] = []
        
        for browser in BrowserType.allCases {
            let browserTabs = BrowserService.shared.fetchTabs(from: browser)
            let tabItems = browserTabs.map { tab in
                let metadata = persistence[tab.url]
                return TabItem(
                    id: UUID(),
                    title: tab.title,
                    url: tab.url,
                    browser: tab.browser,
                    note: metadata?.note,
                    reminderDate: metadata?.reminderDate
                )
            }
            allTabs.append(contentsOf: tabItems)
        }
        
        self.tabs = allTabs
    }
    
    func updateNote(for tab: TabItem, note: String?) {
        var metadata = persistence[tab.url] ?? TabMetadata()
        metadata.note = note
        persistence[tab.url] = metadata
        savePersistence()
        
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index].note = note
        }
    }
    
    func updateReminder(for tab: TabItem, date: Date?) {
        var metadata = persistence[tab.url] ?? TabMetadata()
        metadata.reminderDate = date
        persistence[tab.url] = metadata
        savePersistence()
        
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index].reminderDate = date
        }
        
        scheduleNotification(for: tab, date: date)
    }
    
    private func scheduleNotification(for tab: TabItem, date: Date?) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        
        let center = UNUserNotificationCenter.current()
        // Remove existing notification for this URL
        center.removePendingNotificationRequests(withIdentifiers: [tab.url])
        guard let date = date, date > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Tab Reminder: \(tab.title)"
        content.body = tab.note ?? "Time to check this tab!"
        content.sound = .default
        content.userInfo = ["url": tab.url]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: tab.url, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func loadPersistence() {
        if let data = UserDefaults.standard.data(forKey: "TabMetadata"),
           let decoded = try? JSONDecoder().decode([String: TabMetadata].self, from: data) {
            self.persistence = decoded
        }
    }
    
    private func savePersistence() {
        if let encoded = try? JSONEncoder().encode(persistence) {
            UserDefaults.standard.set(encoded, forKey: "TabMetadata")
        }
    }
}
