import Foundation

enum TabTier: String, CaseIterable, Codable {
    case focus = "Focus"
    case research = "Research"
    case chill = "Chill"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .research: return "book.closed.fill"
        case .chill: return "cup.and.saucer.fill"
        case .other: return "globe"
        }
    }
}

extension TabItem {
    static func classify(url: String, title: String) -> TabTier {
        let lowerURL = url.lowercased()
        let lowerTitle = title.lowercased()
        
        // Focus
        if lowerURL.contains("github.com") || 
           lowerURL.contains("docs.") || 
           lowerURL.contains("localhost") ||
           lowerURL.contains("jira") ||
           lowerURL.contains("linear.app") ||
           lowerURL.contains("notion.so") ||
           lowerURL.contains("figma.com") {
            return .focus
        }
        
        // Research
        if lowerURL.contains("stackoverflow.com") || 
           lowerURL.contains("medium.com") || 
           lowerURL.contains("wikipedia.org") ||
           lowerURL.contains("news.ycombinator.com") ||
           lowerURL.contains("dev.to") {
            return .research
        }
        
        // Chill
        if lowerURL.contains("youtube.com") || 
           lowerURL.contains("netflix.com") || 
           lowerURL.contains("reddit.com") || 
           lowerURL.contains("twitter.com") ||
           lowerURL.contains("x.com") ||
           lowerURL.contains("instagram.com") ||
           lowerURL.contains("discord.com") {
            return .chill
        }
        
        return .other
    }
}
struct TabItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let browser: String
    var note: String?
    var reminderDate: Date?
    var tier: TabTier = .other
}
