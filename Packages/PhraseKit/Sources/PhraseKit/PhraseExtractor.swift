/// Turns the speech recognised inside an A-B loop into word-list lines.
///
/// The A-B range is what decides how long a line is — the user chose it — so
/// nothing here cuts by word count. The only trimming is at the edges: words
/// the range caught only partly, hesitation fillers, and a name used to
/// address someone. A range holding several sentences becomes several lines,
/// but only where the sentence boundary is unmistakable.
public struct PhraseExtractor: Sendable {
    /// A silence long enough to end a sentence when the recogniser gave no
    /// punctuation. Deliberately generous: a breath taken mid-sentence must
    /// never split one line into two.
    public var sentencePause: Double

    public init(sentencePause: Double = 1.0) {
        self.sentencePause = sentencePause
    }

    /// - Parameters:
    ///   - tokens: Recognised words in time order, possibly reaching past the range.
    ///   - range: The A-B loop, in seconds.
    ///   - languageCode: BCP-47 tag of the spoken language, e.g. "ja" or "en".
    public func phrases(
        from tokens: [TimedToken],
        in range: ClosedRange<Double>,
        languageCode: String
    ) -> [String] {
        let rules = LanguageRules(languageCode: languageCode)

        // A word counts when most of it was inside the loop: setting A or B a
        // beat early or late is normal and shouldn't leave half a word behind.
        var spoken: [TimedToken] = []
        for token in tokens where token.fractionInside(range) > 0.5 {
            guard rules.isFiller(token.text) else {
                spoken.append(token)
                continue
            }
            // Recognisers hang punctuation on the word before it, so a filler
            // can carry the full stop. Keep the stop, or two sentences merge.
            let ending = rules.sentenceEnding(of: token.text)
            if !ending.isEmpty, let last = spoken.last, !rules.endsSentence(last.text) {
                spoken[spoken.count - 1] = TimedToken(last.text + ending, last.start, last.end)
            }
        }

        let sentences = sentences(in: spoken, rules: rules)
            .map(rules.assemble)
            .map(rules.removingAddressedName)
            .filter(rules.hasContent)

        return rules.mergingShortFragments(sentences).map(rules.finished)
    }

    private func sentences(in tokens: [TimedToken], rules: LanguageRules) -> [[TimedToken]] {
        var sentences: [[TimedToken]] = []
        var current: [TimedToken] = []

        for (index, token) in tokens.enumerated() {
            current.append(token)
            let next = tokens.indices.contains(index + 1) ? tokens[index + 1] : nil

            let pauseFollows = next.map { $0.start - token.end >= sentencePause } ?? false
            // A full stop recognised as a token of its own belongs to the
            // sentence it closes, so hold the break until it has been added.
            let punctuationFollows = next.map { rules.isPunctuationOnly($0.text) } ?? false

            if (rules.endsSentence(token.text) || pauseFollows) && !punctuationFollows {
                sentences.append(current)
                current = []
            }
        }
        if !current.isEmpty { sentences.append(current) }
        return sentences
    }
}
