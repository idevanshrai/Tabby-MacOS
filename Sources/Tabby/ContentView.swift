import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tabManager: TabManager
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Glass Header
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
                .padding(.trailing, 8)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding()
            .background(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Scrollable List
            ScrollView {
                LazyVStack(spacing: 12) {
                    if tabManager.tabs.isEmpty {
                        EmptyStateView()
                            .padding(.top, 40)
                    } else {
                        ForEach(tabManager.tabs) { tab in
                            TabRow(tab: tab)
                                .transition(.opacity.combined(with: .slide))
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .background(.ultraThinMaterial)
        .frame(width: 400, height: 600)
        .onAppear {
            tabManager.refreshTabs()
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "safari")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No active tabs found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Open Chrome, Safari, or Arc to see them here.")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
}

struct TabRow: View {
    let tab: TabItem
    @EnvironmentObject var tabManager: TabManager
    @State private var isExpanded: Bool = false
    @State private var noteText: String = ""
    @FocusState private var isNoteFocused: Bool
    
    // Helper to get icon for browser
    var browserIcon: String {
        switch tab.browser {
        case "Google Chrome": return "globe"
        case "Safari": return "safari"
        case "Arc": return "circle.grid.cross"
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
                }
                
                Spacer()
                
                // Indicators
                HStack(spacing: 8) {
                    if tab.reminderDate != nil {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    if tab.note != nil {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.blue)
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
                        
                        TextField("Why is this tab open? (e.g. 'Read for research')", text: $noteText, onCommit: {
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
                    
                    // Reminder
                    HStack {
                        DatePicker("Remind me:", selection: Binding(get: {
                            tab.reminderDate ?? Date()
                        }, set: { newDate in
                            withAnimation {
                                tabManager.updateReminder(for: tab, date: newDate)
                            }
                        }), in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .scaleEffect(0.9, anchor: .leading)
                        
                        Spacer()
                        
                        // Action Buttons
                        if tab.reminderDate != nil {
                            Button(action: {
                                withAnimation { tabManager.updateReminder(for: tab, date: nil) }
                            }) {
                                Image(systemName: "bell.slash.fill")
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .buttonStyle(GlassButtonStyle())
                        }
                        
                        Button(action: {
                            saveNote()
                        }) {
                            Text("Save")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
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
