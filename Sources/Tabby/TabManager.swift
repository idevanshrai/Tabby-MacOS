import SwiftUI

struct TabMetadata: Codable {
    var note: String?
    var reminderDate: Date?
}

import UserNotifications
import EventKit

@MainActor
class TabManager: ObservableObject {
    @Published var tabs: [TabItem] = []
    @Published var enabledBrowsers: [BrowserType: Bool] = [:]
    @Published var availableBrowsers: [BrowserType] = []
    
    private var persistence: [String: TabMetadata] = [:]
    private var timer: Timer?
    
    init() {
        // Detect installed browsers
        availableBrowsers = BrowserType.allCases.filter { $0.isInstalled }
        
        // Initialize default enabled settings
        for browser in availableBrowsers {
            enabledBrowsers[browser] = UserDefaults.standard.object(forKey: "Enabled_\(browser.rawValue)") as? Bool ?? true
        }
        
        loadPersistence()
        requestNotificationPermission()
        startAutoRefresh()
    }
    
    func startAutoRefresh() {
        // Auto-refresh every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.refreshTabs()
        }
    }
    
    func toggleBrowser(_ browser: BrowserType) {
        let newState = !(enabledBrowsers[browser] ?? true)
        enabledBrowsers[browser] = newState
        UserDefaults.standard.set(newState, forKey: "Enabled_\(browser.rawValue)")
        refreshTabs()
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
        var newTabs: [TabItem] = []
        
        // Fetch current tabs from browsers
        var fetchedTabs: [BrowserTab] = []
        for browser in availableBrowsers {
            if let enabled = enabledBrowsers[browser], !enabled { continue }
            fetchedTabs.append(contentsOf: BrowserService.shared.fetchTabs(from: browser))
        }
        
        // Merge with existing tabs to preserve IDs (Stable Identity)
        // We use a pool of existing tabs to try and match by URL
        var existingTabsPool = self.tabs
        
        for fetchedTab in fetchedTabs {
            let metadata = persistence[fetchedTab.url]
            
            // Try to find an existing tab with the same URL to reuse its UUID
            var matchedID = UUID()
            if let index = existingTabsPool.firstIndex(where: { $0.url == fetchedTab.url }) {
                matchedID = existingTabsPool[index].id
                existingTabsPool.remove(at: index) // Remove so we don't reuse it for another duplicate URL
            }
            
            let tabItem = TabItem(
                id: matchedID,
                title: fetchedTab.title,
                url: fetchedTab.url,
                browser: fetchedTab.browser,
                note: metadata?.note,
                reminderDate: metadata?.reminderDate
            )
            newTabs.append(tabItem)
        }
        
        self.tabs = newTabs
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
    
    func activateTab(_ tab: TabItem) {
        BrowserService.shared.activateTab(url: tab.url, browser: tab.browser)
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
        
        // Sync with Calendar (EventKit)
        syncToCalendar(for: tab, date: date)
    }
    
    private let eventStore = EKEventStore()
    
    private func syncToCalendar(for tab: TabItem, date: Date) {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            guard granted, error == nil else {
                print("Calendar access denied or error: \(String(describing: error))")
                return
            }
            
            // Check if we already created an event for this tab (naive check by title/url in recent events or similar)
            // For simplicity in this v1, we just create a new event.
            // In production, we'd store the 'eventIdentifier' in TabMetadata to update/delete it.
            
            let event = EKEvent(eventStore: self!.eventStore)
            event.title = "Tabby: \(tab.title)"
            event.notes = "\(tab.note ?? "")\n\nURL: \(tab.url)"
            event.startDate = date
            event.endDate = date.addingTimeInterval(3600) // 1 hour duration
            event.calendar = self!.eventStore.defaultCalendarForNewEvents
            event.url = URL(string: tab.url)
            
            // Add alarm
            let alarm = EKAlarm(absoluteDate: date)
            event.addAlarm(alarm)
            
            do {
                try self!.eventStore.save(event, span: .thisEvent)
                print("Saved event to calendar: \(event.title ?? "")")
            } catch {
                print("Failed to save event: \(error)")
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
