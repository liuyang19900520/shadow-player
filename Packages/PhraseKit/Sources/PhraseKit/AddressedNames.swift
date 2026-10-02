import Foundation
import NaturalLanguage

/// Removes a name used to address someone — "田中さん、" or "Hey Tom," — from
/// the start or end of a line, since it is not something to study.
///
/// A name that is part of the sentence stays: "田中さんは来ますか" and
/// "Tom is waiting" are about Tanaka and Tom, and cutting the name would
/// break them. Names in the middle of a line are never touched.
enum AddressedNames {
    // MARK: - Japanese

    /// The system has no Japanese name recogniser, so a name is found by the
    /// honorific after it — and only when a comma sets it apart from the rest
    /// of the line. Without the comma, "田中さんおはよう" can't be told from
    /// "おじさん来たよ", and guessing wrongly saves a mangled sentence; a name
    /// left in is easy to delete by hand.
    private static let honorifics = [
        "さん", "くん", "君", "ちゃん", "様", "さま", "先生", "せんせい", "氏", "殿",
    ]

    /// Titles used on their own to address someone.
    private static let standaloneTitles: Set<String> = ["先生", "せんせい"]

    /// Set phrases and ordinary words that happen to end in an honorific.
    private static let notNames = [
        "お疲れさま", "おつかれさま", "お疲れ様", "ごちそうさま", "ご馳走さま", "ご馳走様",
        "ご苦労さま", "ご苦労様", "おかげさま", "お陰様", "お世話さま", "お待ちどおさま",
        "お互いさま", "たくさん", "皆さん", "みなさん", "皆様", "みなさま",
    ]

    /// A stretch holding one of these is a phrase doing a job in the sentence
    /// ("今日は田中さん"), not someone being addressed.
    private static let bindingWords: Set<String> = [
        "は", "が", "を", "に", "の", "と", "も", "で", "へ", "から", "まで", "より", "や", "って",
        "だ", "です", "でした", "だった", "じゃ", "では", "か", "ね", "よ",
    ]

    /// A name with its honorific is at most this many words: 田中|太郎|さん.
    private static let longestAddressInWords = 3

    private static let separators: Set<Character> = ["、", ",", "，"]
    private static let closingPunctuation: Set<Character> = ["。", "．", ".", "！", "!", "？", "?", "…"]

    static func strippingJapanese(_ sentence: String) -> String {
        let (body, closing) = splittingClosingPunctuation(sentence)

        // The whole line is someone's name: nothing to study.
        if isJapaneseAddress(body) { return "" }

        var text = body
        // "田中さん、おはようございます"
        if let comma = text.firstIndex(where: separators.contains),
           isJapaneseAddress(String(text[..<comma])) {
            text = String(text[text.index(after: comma)...])
        }
        // "ありがとう、山田先生"
        if let comma = text.lastIndex(where: separators.contains),
           isJapaneseAddress(String(text[text.index(after: comma)...])) {
            text = String(text[..<comma])
        }
        return text + closing
    }

    private static func isJapaneseAddress(_ candidate: String) -> Bool {
        let text = candidate.trimmingCharacters(in: .whitespaces)
        // A name never spans a comma: "ありがとう、山田先生" is a line, not a name.
        guard !text.isEmpty, !text.contains(where: separators.contains),
              !notNames.contains(where: text.hasSuffix) else { return false }
        if standaloneTitles.contains(text) { return true }
        guard honorifics.contains(where: { text.hasSuffix($0) && text.count > $0.count }) else { return false }

        let words = japaneseWords(in: text).map { String(text[$0]) }
        return words.count <= longestAddressInWords && !words.contains(where: bindingWords.contains)
    }

    private static func splittingClosingPunctuation(_ text: String) -> (body: String, closing: String) {
        let closing = String(text.reversed().prefix { closingPunctuation.contains($0) }.reversed())
        return (String(text.dropLast(closing.count)), closing)
    }

    private static func japaneseWords(in text: String) -> [Range<String.Index>] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.setLanguage(.japanese)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex)
    }

    // MARK: - English

    /// Words that open an address. "Oh" and "OK" are left out: they start
    /// ordinary sentences ("Oh, English is hard").
    private static let greetings: Set<String> = ["hey", "hi", "hello", "yo", "dear"]

    static func strippingEnglish(_ sentence: String) -> String {
        trailingEnglishRemoved(leadingEnglishRemoved(sentence))
    }

    private static func leadingEnglishRemoved(_ text: String) -> String {
        let words = englishWords(in: text)
        let names = personalNames(in: text)
        guard let first = words.first else { return text }

        func name(startingAt word: Range<String.Index>) -> Range<String.Index>? {
            names.first { $0.lowerBound == word.lowerBound }
        }
        func wordAfter(_ span: Range<String.Index>) -> Range<String.Index>? {
            words.first { $0.lowerBound >= span.upperBound }
        }

        // "Hey Tom good morning": the greeting marks what follows as an
        // address, comma or not. The tagger can't be relied on here — it
        // misses "Tom" without a comma and reads "Hi Sarah" as one name — so a
        // capitalised word after the greeting is taken as the name.
        if greetings.contains(text[first].lowercased()), words.count > 1,
           isCapitalisedName(text[words[1]]) {
            let covering = names.first { $0.contains(words[1].lowerBound) }
            let spokenEnd = max(words[1].upperBound, covering?.upperBound ?? words[1].upperBound)
            return String(text[(wordAfter(words[1].lowerBound..<spokenEnd)?.lowerBound ?? text.endIndex)...])
        }

        // "Tom, could you…" is an address; "Tom is waiting" is not.
        if let spoken = name(startingAt: first) {
            let rest = wordAfter(spoken)?.lowerBound ?? text.endIndex
            if text[spoken.upperBound..<rest].contains(where: separators.contains) {
                return String(text[rest...])
            }
        }
        return text
    }

    private static func trailingEnglishRemoved(_ text: String) -> String {
        let words = englishWords(in: text)
        guard let last = words.last,
              let spoken = personalNames(in: text).last(where: { $0.upperBound == last.upperBound }),
              let previous = words.last(where: { $0.upperBound <= spoken.lowerBound })
        else { return text }

        // Only "…, Sarah." — without the comma the name may be the object.
        guard text[previous.upperBound..<spoken.lowerBound].contains(where: separators.contains) else {
            return text
        }
        return String(text[..<previous.upperBound]) + text[spoken.upperBound...]
    }

    /// Recognisers capitalise proper nouns, so after a greeting a capital
    /// letter means a name — except "I", as in "Hi, I'm Tom".
    private static func isCapitalisedName(_ word: Substring) -> Bool {
        guard let first = word.first, first.isUppercase else { return false }
        return word != "I" && !word.hasPrefix("I'")
    }

    /// Whether the line opens with a name, which keeps its capital when a
    /// short fragment is joined in front of it.
    static func startsWithEnglishName(_ text: String) -> Bool {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        tagger.setLanguage(.english, range: text.startIndex..<text.endIndex)
        guard let first = englishWords(in: text).first else { return false }
        let (tag, _) = tagger.tag(at: first.lowerBound, unit: .word, scheme: .nameType)
        return [.personalName, .placeName, .organizationName].contains(tag)
    }

    private static func englishWords(in text: String) -> [Range<String.Index>] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.setLanguage(.english)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex)
    }

    private static func personalNames(in text: String) -> [Range<String.Index>] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        tagger.setLanguage(.english, range: text.startIndex..<text.endIndex)
        var names: [Range<String.Index>] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation, .joinNames]
        ) { tag, range in
            if tag == .personalName { names.append(range) }
            return true
        }
        return names
    }
}
