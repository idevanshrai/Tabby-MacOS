import Foundation

struct TabItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let browser: String
    var note: String?
    var reminderDate: Date?
}
