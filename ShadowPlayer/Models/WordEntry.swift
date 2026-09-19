import Foundation

/// One row in a video's word list: the word or phrase the user noted, plus an
/// optional Chinese meaning filled in by on-device translation.
struct WordEntry: Identifiable, Hashable, Codable {
    var id = UUID()
    var text = ""
    /// Optional so lists saved before meanings existed still decode cleanly.
    var translation: String?

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A row worth translating: it has a word but no meaning yet. Rows the user
    /// already wrote a meaning for are never re-translated.
    var needsTranslation: Bool {
        !trimmedText.isEmpty
            && (translation ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
