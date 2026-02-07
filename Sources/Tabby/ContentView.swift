import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tabManager: TabManager
    @State private var showingSettings = false
    @State private var searchText = ""
    
    var filteredTabs: [TabItem] {
        if searchText.isEmpty {
            return tabManager.tabs
        } else {
            return tabManager.tabs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.url.localizedCaseInsensitiveContains(searchText) ||
                ($0.note ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            if !showingSettings {
                MainView(showingSettings: $showingSettings, searchText: $searchText, tabs: filteredTabs)
                    .transition(.move(edge: .leading))
            } else {
                SettingsView(showingSettings: $showingSettings)
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(width: 400, height: 600)
        .onAppear {
            tabManager.refreshTabs()
        }
    }
}

struct MainView: View {
    @EnvironmentObject var tabManager: TabManager
    @Binding var showingSettings: Bool
    @Binding var searchText: String
    var tabs: [TabItem]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Glass Header
            VStack(spacing: 12) {
                HStack {
                    Label("Tabby", systemImage: "safari")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            tabManager.refreshTabs()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .padding(.trailing, 4)
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            showingSettings = true
                        }
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .padding(.trailing, 4)
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search tabs...", text: $searchText)
                        .textFieldStyle(.plain) 
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }
            .padding()
            .background(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Scrollable List
            ScrollView {
                VStack(spacing: 16) {
                    if tabs.isEmpty {
                        EmptyStateView(isSearching: !searchText.isEmpty)
                            .padding(.top, 40)
                    } else {
                        // Group tabs by tier
                        let grouped = Dictionary(grouping: tabs, by: { $0.tier })
                        
                        // Define Order
                        let order: [TabTier] = [.focus, .research, .chill, .other]
                        
                        ForEach(order, id: \.self) { tier in
                            if let tierTabs = grouped[tier], !tierTabs.isEmpty {
                                TierAccordionView(tier: tier, tabs: tierTabs)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .background(.ultraThinMaterial)
    }
}

struct SettingsView: View {
    @EnvironmentObject var tabManager: TabManager
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    withAnimation(.spring()) {
                        showingSettings = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(GlassButtonStyle())
                
                Spacer()
                
                Text("Settings")
                    .font(.headline)
                
                Spacer()
                
                // Invisible spacer for visual balance
                Color.clear.frame(width: 60, height: 1)
            }
            .padding()
            .background(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Browser Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Broswers to Scan")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        VStack(spacing: 1) {
                            if tabManager.availableBrowsers.isEmpty {
                                Text("No supported browsers found.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(tabManager.availableBrowsers) { browser in
                                    ToggleRow(
                                        title: browser.rawValue,
                                        icon: browserIcon(for: browser.rawValue),
                                        isOn: Binding(
                                            get: { tabManager.enabledBrowsers[browser] ?? true },
                                            set: { _ in tabManager.toggleBrowser(browser) }
                                        )
                                    )
                                }
                            }
                        }
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        VStack(spacing: 16) {
                            Image(systemName: "safari")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                                .padding(.top, 8)
                            
                            VStack(spacing: 4) {
                                Text("Tabby")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Version 1.0.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            VStack(spacing: 8) {
                                Text("Designed & Developed by")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Devansh Rai")
                                    .fontWeight(.medium)
                                
                                Link("Contact Developer", destination: URL(string: "mailto:idevanshrai@gmail.com")!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.bottom, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .background(.ultraThinMaterial)
    }
    
    func browserIcon(for browser: String) -> String {
        switch browser {
        case "Google Chrome": return "globe"
        case "Safari": return "safari"
        case "Arc": return "circle.grid.cross"
        case "Firefox": return "flame" // System image for Firefox-like icon
        default: return "network"
        }
    }
}

struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            Text(title)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }
}

struct EmptyStateView: View {
    var isSearching: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isSearching ? "magnifyingglass" : "moon.zzz.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(isSearching ? "No tabs found matching your search." : "No Tabs Found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !isSearching {
                Text("Open chrome, safari, or arc to see tabs here.")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}
struct TabRow: View {
    let tab: TabItem
    @EnvironmentObject var tabManager: TabManager
    @State private var isExpanded: Bool = false
    @State private var isReminderExpanded: Bool = false
    @State private var noteText: String = ""
    @FocusState private var isNoteFocused: Bool
    
    // Helper to get icon for browser
    var browserIcon: String {
        switch tab.browser {
        case "Google Chrome": return "globe"
        case "Safari": return "safari"
        case "Arc": return "circle.grid.cross"
        case "Firefox": return "flame"
        default: return "network"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Row Content
            HStack(spacing: 12) {
                // Browser Icon
                ZStack {
                    Circle()
                        .fill(.regularMaterial)
                        .frame(width: 32, height: 32)
                    Image(systemName: browserIcon)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(tab.url)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let note = tab.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.blue.opacity(0.8))
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 8) {
                    // Jump/Activate Button
                    Button(action: {
                        tabManager.activateTab(tab)
                    }) {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    if tab.reminderDate != nil {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                    if isExpanded {
                        noteText = tab.note ?? ""
                        isNoteFocused = true
                    } else {
                        isNoteFocused = false
                    }
                }
            }
            
            // Expanded Content (Note & Reminder)
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(.secondary.opacity(0.2))
                    
                    // Note Input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Context Note")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        TextField("Why is this tab open?", text: $noteText, onCommit: {
                            saveNote()
                        })
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        )
                        .focused($isNoteFocused)
                    }
                    
                    // Reminder Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Reminder")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    isReminderExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: tab.reminderDate != nil ? "bell.fill" : "bell")
                                    Text(tab.reminderDate != nil ? "Edit Reminder" : "Add Reminder")
                                }
                                .font(.caption)
                                .foregroundColor(tab.reminderDate != nil ? .orange : .blue)
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                )
                            }
                            .buttonStyle(.plain)
                            
                            if tab.reminderDate != nil {
                                Button(action: {
                                    withAnimation { tabManager.updateReminder(for: tab, date: nil) }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 4)
                            }
                        }

                        if isReminderExpanded || (tab.reminderDate != nil && isReminderExpanded) {
                            DatePicker("Select Date", selection: Binding(get: {
                                tab.reminderDate ?? Date()
                            }, set: { newDate in
                                withAnimation {
                                    tabManager.updateReminder(for: tab, date: newDate)
                                }
                            }), in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        } else if let date = tab.reminderDate {
                            Text("Reminder set for \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Save Button
                    HStack {
                        Spacer()
                        Button(action: {
                            saveNote()
                        }) {
                            Text("Save Changes")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                        }
                        .buttonStyle(GlassButtonStyle(color: .blue))
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
            }
        }
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func saveNote() {
        withAnimation {
            tabManager.updateNote(for: tab, note: noteText.isEmpty ? nil : noteText)
            isExpanded = false
        }
    }
}

struct GlassButtonStyle: ButtonStyle {
    var color: Color = .secondary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.3 : 0.1))
            )
            .foregroundColor(color)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TierAccordionView: View {
    let tier: TabTier
    let tabs: [TabItem]
    @State private var isExpanded: Bool = true
    
    var tierColor: Color {
        switch tier {
        case .focus: return .purple
        case .research: return .blue
        case .chill: return .orange
        case .other: return .secondary
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: tier.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(tierColor)
                        .frame(width: 24)
                    
                    Text(tier.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(tabs.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .buttonStyle(.plain)
            
            // Content
            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(tabs) { tab in
                        TabRow(tab: tab)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.regularMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tierColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: tierColor.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
