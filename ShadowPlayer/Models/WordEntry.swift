import Foundation

/// One row in a video's word list: the word or phrase the user noted, plus an
/// optional meaning filled in by on-device translation or typed by hand.
struct WordEntry: Identifiable, Hashable, Codable {
    var id = UUID()
    var text = ""
    /// Optional so lists saved before meanings existed still decode cleanly.
    var translation: String?
    /// The word the meaning was written for. Once the word is edited away
    /// from it, the meaning is out of date and is translated again. Nil in
    /// lists saved before this existed, until the word is next edited — so an
    /// update never re-translates a whole list on its own.
    var meaningSource: String?

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasMeaning: Bool {
        !(translation ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The word has changed since its meaning was written.
    private var meaningIsStale: Bool {
        guard hasMeaning, let meaningSource else { return false }
        return meaningSource != trimmedText
    }

    /// A row worth translating: it has a word, and either no meaning yet or
    /// one written for what the word used to be.
    var needsTranslation: Bool {
        !trimmedText.isEmpty && (!hasMeaning || meaningIsStale)
    }

    /// Change the word. The meaning stays visible until a new one arrives,
    /// but it is now out of date.
    mutating func setText(_ newText: String) {
        // Rows saved before `meaningSource` existed learn it on first edit.
        if hasMeaning, meaningSource == nil {
            meaningSource = trimmedText
        }
        text = newText
    }

    /// The user typed the meaning: it belongs to the word as it stands now,
    /// so translation leaves it alone until the word itself changes.
    mutating func setMeaning(_ meaning: String) {
        translation = meaning.isEmpty ? nil : meaning
        meaningSource = translation == nil ? nil : trimmedText
    }

    /// A translation of `source` came back. Dropped if the word has been
    /// edited since — a translation of the new word is on its way — or if
    /// the row no longer wants one, such as a meaning typed in the meantime.
    @discardableResult
    mutating func applyTranslation(_ meaning: String, of source: String) -> Bool {
        guard !meaning.isEmpty, source == trimmedText, needsTranslation else { return false }
        translation = meaning
        meaningSource = source
        return true
    }
}
