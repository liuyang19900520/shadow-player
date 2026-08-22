import Foundation

/// One row in a video's word list: a single free-form note.
struct WordEntry: Identifiable, Hashable, Codable {
    var id = UUID()
    var text = ""
}
