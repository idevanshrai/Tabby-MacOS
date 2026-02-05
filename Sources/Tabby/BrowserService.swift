import Foundation
import AppKit

enum BrowserType: String, CaseIterable, Identifiable {
    case chrome = "Google Chrome"
    case safari = "Safari"
    case arc = "Arc"
    
    var id: String { rawValue }
    
    var bundleIdentifier: String? {
        switch self {
        case .chrome: return "com.google.Chrome"
        case .safari: return "com.apple.Safari"
        case .arc: return "company.thebrowser.Browser"
        }
    }
}

struct BrowserTab: Sendable {
    let title: String
    let url: String
    let browser: String
}

@MainActor
class BrowserService {
    
    static let shared = BrowserService()
    
    func fetchTabs(from browser: BrowserType) -> [BrowserTab] {
        // Check if browser is running
        guard isBrowserRunning(browser) else {
            return []
        }
        
        var scriptSource = ""
        
        switch browser {
        case .chrome:
            scriptSource = """
            tell application "Google Chrome"
                set tabList to {}
                repeat with w in windows
                    repeat with t in tabs of w
                        set end of tabList to {title of t, URL of t}
                    end repeat
                end repeat
                return tabList
            end tell
            """
        case .safari:
            scriptSource = """
            tell application "Safari"
                set tabList to {}
                repeat with w in windows
                    repeat with t in tabs of w
                        set end of tabList to {name of t, URL of t}
                    end repeat
                end repeat
                return tabList
            end tell
            """
        case .arc:
             scriptSource = """
            tell application "Arc"
                set tabList to {}
                repeat with w in windows
                    repeat with t in tabs of w
                        set end of tabList to {title of t, URL of t}
                    end repeat
                end repeat
                return tabList
            end tell
            """
        }
        
        return execute(script: scriptSource, browserName: browser.rawValue)
    }
    
    private func isBrowserRunning(_ browser: BrowserType) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { app in
            if let id = browser.bundleIdentifier {
                return app.bundleIdentifier == id
            }
            return app.localizedName == browser.rawValue
        }
    }

    
    private func execute(script: String, browserName: String) -> [BrowserTab] {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            
            if let error = error {
                print("AppleScript Error: \(error)")
                return []
            }
            
            // Parse the output (List of Lists)
            // Output format: {{title1, url1}, {title2, url2}, ...}
            var tabs: [BrowserTab] = []
            
            let descriptor = output
            let numberOfItems = descriptor.numberOfItems
            
            for i in 1...numberOfItems {
                if let item = descriptor.atIndex(i) {
                    // Each item should be a list {title, url}
                    if item.numberOfItems >= 2,
                       let titleDesc = item.atIndex(1),
                       let urlDesc = item.atIndex(2) {
                        
                        let title = titleDesc.stringValue ?? "No Title"
                        let url = urlDesc.stringValue ?? ""
                        
                        if !url.isEmpty {
                            tabs.append(BrowserTab(title: title, url: url, browser: browserName))
                        }
                    }
                }
            }
            return tabs
        }
        return []
    }
}
