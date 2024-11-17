//

import Foundation

struct RowsGarden: Codable {
    struct Entry: Codable, Identifiable {
        let clue: String
        let answer: String
        var id: String { "\(clue) \(answer)" }
    }
    let title: String?
    let author: String?
    let created: String?
    let url: String?
    let copyright: String?
    let notes: String?
    let rows: [[Entry]]
    let light: [Entry]
    let medium: [Entry]
    let dark: [Entry]
}
