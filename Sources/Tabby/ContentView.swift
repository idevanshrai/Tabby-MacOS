import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tabManager: TabManager
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Header
            HStack {
                Text("Tabby")
                    .font(.headline)
                Spacer()
                Button(action: {
                    tabManager.refreshTabs()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // List
            List {
                ForEach(tabManager.tabs) { tab in
                    TabRow(tab: tab)
                }
            }
            .listStyle(.plain)
        }
        .frame(width: 350, height: 500)
        .onAppear {
            tabManager.refreshTabs()
        }
    }
}

struct TabRow: View {
    let tab: TabItem
    @EnvironmentObject var tabManager: TabManager
    @State private var isExpanded: Bool = false
    @State private var noteText: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(tab.title)
                        .font(.body)
                        .lineLimit(1)
                    Text(tab.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if tab.note != nil {
                    Image(systemName: "note.text")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
                if isExpanded {
                    noteText = tab.note ?? ""
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading) {
                    TextField("Why did you open this?", text: $noteText, onCommit: {
                        tabManager.updateNote(for: tab, note: noteText)
                    })
                    .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        DatePicker("Remind me:", selection: Binding(get: {
                            tab.reminderDate ?? Date()
                        }, set: { newDate in
                            tabManager.updateReminder(for: tab, date: newDate)
                        }), in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .scaleEffect(0.8)
                        
                        if tab.reminderDate != nil {
                            Button(action: {
                                tabManager.updateReminder(for: tab, date: nil)
                            }) {
                                Image(systemName: "bell.slash")
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                        } else {
                            Image(systemName: "bell")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Save") {
                            tabManager.updateNote(for: tab, note: noteText)
                            isExpanded = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        if tab.note != nil {
                            Button("Clear") {
                                tabManager.updateNote(for: tab, note: nil)
                                noteText = ""
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.top, 4)
            } else if let note = tab.note {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
