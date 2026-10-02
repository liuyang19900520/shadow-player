import Foundation

/// The language-specific parts of phrase extraction: which words are
/// hesitation, how text is spaced, and how lines are tidied up. Languages
/// without rules of their own are only trimmed and split.
struct LanguageRules {
    private enum Language {
        case japanese, english, other
    }

    private let language: Language
    /// Japanese and Chinese are written without spaces between words.
    private let writesWithoutSpaces: Bool

    init(languageCode: String) {
        let base = languageCode.split(separator: "-").first.map { $0.lowercased() } ?? ""
        switch base {
        case "ja": language = .japanese
        case "en": language = .english
        default: language = .other
        }
        writesWithoutSpaces = base == "ja" || base == "zh"
    }

    // MARK: - Tokens

    /// "あの" and "その" are left out on purpose: they are also "that",
    /// as in その本. Only their drawn-out hesitation forms are fillers.
    private static let japaneseFillers: Set<String> = [
        "えー", "えーと", "えーっと", "ええと", "ええっと", "えっと", "えと",
        "あー", "あのー", "あのう", "そのー", "まあ", "まぁ", "うーん", "んー",
    ]

    private static let englishFillers: Set<String> = [
        "um", "umm", "uh", "uhh", "er", "erm", "hmm", "hm", "mm",
    ]

    private static let sentenceEnders: Set<Character> = ["。", "．", ".", "！", "!", "？", "?", "…"]

    /// "Mr." ends a word, not a sentence.
    private static let abbreviations: Set<String> = ["mr", "mrs", "ms", "dr", "st", "prof", "jr", "sr"]

    func isFiller(_ text: String) -> Bool {
        let word = Self.bare(text).lowercased()
        switch language {
        case .japanese: return Self.japaneseFillers.contains(word)
        case .english: return Self.englishFillers.contains(word)
        case .other: return false
        }
    }

    func endsSentence(_ text: String) -> Bool {
        guard let last = text.trimmingCharacters(in: .whitespacesAndNewlines).last,
              Self.sentenceEnders.contains(last) else { return false }
        return !Self.abbreviations.contains(Self.bare(text).lowercased())
    }

    /// The full stop, question mark or similar a token ends with, if any.
    func sentenceEnding(of text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.reversed().prefix { Self.sentenceEnders.contains($0) }.reversed())
    }

    func isPunctuationOnly(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.unicodeScalars.allSatisfy(CharacterSet.punctuationCharacters.contains)
    }

    /// Join tokens into text. Recognisers disagree on whether a token carries
    /// its trailing space, so spacing is rebuilt rather than trusted.
    func assemble(_ tokens: [TimedToken]) -> String {
        var text = ""
        for token in tokens {
            let word = token.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !word.isEmpty else { continue }
            if needsSpace(between: text, and: word) { text += " " }
            text += word
        }
        return text
    }

    private func needsSpace(between text: String, and word: String) -> Bool {
        guard let before = text.last, let after = word.first else { return false }
        if isPunctuationOnly(word) { return false }
        if writesWithoutSpaces {
            // Only a Latin word inside Japanese text keeps its space.
            return before.isASCIIAlphanumeric && after.isASCIIAlphanumeric
        }
        return true
    }

    // MARK: - Lines

    func removingAddressedName(from sentence: String) -> String {
        switch language {
        case .japanese: return AddressedNames.strippingJapanese(sentence)
        case .english: return AddressedNames.strippingEnglish(sentence)
        case .other: return sentence
        }
    }

    func hasContent(_ sentence: String) -> Bool {
        sentence.contains { $0.isLetter || $0.isNumber }
    }

    /// A line too short to stand on its own — "はい", "Yes" — joins its
    /// neighbour instead of becoming an entry of its own. A single short line
    /// is kept: the user looped exactly that.
    func mergingShortFragments(_ sentences: [String]) -> [String] {
        var lines = sentences
        while lines.count > 1, let index = lines.firstIndex(where: isShort) {
            // A leading fragment runs into what follows; any other joins what
            // came before it.
            let pair = index == 0 ? 0...1 : (index - 1)...index
            lines.replaceSubrange(pair, with: [joining(lines[pair.lowerBound], lines[pair.upperBound])])
        }
        return lines
    }

    private func isShort(_ sentence: String) -> Bool {
        let content = Self.bare(sentence)
        if writesWithoutSpaces { return content.count < 3 }
        return content.split(whereSeparator: \.isWhitespace).count < 2
    }

    private func joining(_ first: String, _ second: String) -> String {
        let head = String(first.reversed().drop { Self.sentenceEnders.contains($0) }.reversed())
        if writesWithoutSpaces { return head + "、" + second }
        let keepsCapital = language == .english && AddressedNames.startsWithEnglishName(second)
        return head + ", " + (keepsCapital ? second : Self.lowercasingFirstWord(second))
    }

    /// Final tidying once names and fillers are gone.
    func finished(_ sentence: String) -> String {
        var text = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        // Separators stranded by a removed name or filler.
        while let first = text.first, "、,，".contains(first) {
            text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        while let last = text.last, "、,，".contains(last) {
            text = String(text.dropLast()).trimmingCharacters(in: .whitespaces)
        }
        text = text.replacingOccurrences(of: "、。", with: "。")
            .replacingOccurrences(of: ",.", with: ".")
        if !writesWithoutSpaces, let first = text.first, first.isLowercase {
            text = first.uppercased() + text.dropFirst()
        }
        return text
    }

    // MARK: - Helpers

    /// Text with the punctuation and spaces around it removed.
    private static func bare(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
    }

    /// "Yes" after a comma reads "yes"; "I" stays capital.
    private static func lowercasingFirstWord(_ text: String) -> String {
        let firstWord = text.prefix { !$0.isWhitespace }
        if firstWord == "I" || firstWord.hasPrefix("I'") { return text }
        guard let first = text.first else { return text }
        return first.lowercased() + text.dropFirst()
    }
}

private extension Character {
    var isASCIIAlphanumeric: Bool { isASCII && (isLetter || isNumber) }
}
