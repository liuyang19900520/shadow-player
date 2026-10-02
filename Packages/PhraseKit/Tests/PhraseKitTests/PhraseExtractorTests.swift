import XCTest
@testable import PhraseKit

/// Tokens laid end to end, each `step` seconds long, starting at `start`.
private func spoken(_ words: [String], from start: Double = 0, step: Double = 0.3) -> [TimedToken] {
    words.enumerated().map { i, word in
        TimedToken(word, start + Double(i) * step, start + Double(i + 1) * step)
    }
}

/// Two runs of tokens separated by a silence of `gap` seconds.
private func spoken(_ first: [String], pause gap: Double, _ second: [String]) -> [TimedToken] {
    let head = spoken(first)
    return head + spoken(second, from: (head.last?.end ?? 0) + gap)
}

private func extract(
    _ tokens: [TimedToken],
    _ language: String,
    in range: ClosedRange<Double>? = nil
) -> [String] {
    let whole = (tokens.first?.start ?? 0)...(tokens.last?.end ?? 0)
    return PhraseExtractor().phrases(from: tokens, in: range ?? whole, languageCode: language)
}

// MARK: - The A-B range decides the length

final class EdgeTrimmingTests: XCTestCase {
    private let tokens = [
        TimedToken("walk", 0.0, 0.4),
        TimedToken("to", 0.4, 0.6),
        TimedToken("the", 0.6, 0.8),
        TimedToken("station", 0.8, 1.4),
    ]

    func testDropsAWordMostlyBeforeA() {
        // Only a quarter of "walk" is inside: A was set a beat late.
        XCTAssertEqual(extract(tokens, "en", in: 0.3...1.4), ["To the station"])
    }

    func testKeepsAWordMostlyInside() {
        XCTAssertEqual(extract(tokens, "en", in: 0.1...1.4), ["Walk to the station"])
    }

    func testDropsAWordMostlyAfterB() {
        // B landed at the very start of "station".
        XCTAssertEqual(extract(tokens, "en", in: 0.0...1.0), ["Walk to the"])
    }

    func testKeepsPunctuationThatHasNoLength() {
        // Recognisers often stamp punctuation with a zero-length time.
        let tokens = [
            TimedToken("行き", 0.0, 0.3),
            TimedToken("ます", 0.3, 0.6),
            TimedToken("。", 0.6, 0.6),
            TimedToken("次", 1.6, 2.0),
        ]
        XCTAssertEqual(extract(tokens, "ja", in: 0.0...0.8), ["行きます。"])
    }

    func testNothingInsideGivesNothing() {
        XCTAssertEqual(extract(tokens, "en", in: 2.0...3.0), [])
    }

    func testNoTokensGivesNothing() {
        XCTAssertEqual(extract([], "ja", in: 0...1), [])
    }
}

// MARK: - Never cut by length; split only on a clear sentence boundary

final class SentenceSplittingTests: XCTestCase {
    func testSplitsOnSentencePunctuation() {
        let tokens = spoken(["おはよう", "ござい", "ます", "。", "今日", "は", "いい", "天気", "です", "ね", "。"])
        XCTAssertEqual(extract(tokens, "ja"), ["おはようございます。", "今日はいい天気ですね。"])
    }

    func testAShortPauseDoesNotSplit() {
        // A breath mid-sentence must not cut the line in two.
        let tokens = spoken(["駅", "まで"], pause: 0.4, ["一緒に", "行き", "ませんか"])
        XCTAssertEqual(extract(tokens, "ja"), ["駅まで一緒に行きませんか"])
    }

    func testALongPauseSplitsWhenThereIsNoPunctuation() {
        let tokens = spoken(["good", "morning"], pause: 1.2, ["how", "are", "you"])
        XCTAssertEqual(extract(tokens, "en"), ["Good morning", "How are you"])
    }

    func testALongSentenceStaysWhole() {
        let words = "I was wondering if you would like to walk to the station with me after the meeting today"
            .split(separator: " ").map(String.init)
        XCTAssertEqual(extract(spoken(words), "en"), [words.joined(separator: " ").capitalizedFirst])
    }

    func testAShortFragmentJoinsTheNextSentenceInJapanese() {
        let tokens = spoken(["はい", "。", "わかり", "まし", "た", "。"])
        XCTAssertEqual(extract(tokens, "ja"), ["はい、わかりました。"])
    }

    func testAShortFragmentJoinsThePreviousSentenceInEnglish() {
        let tokens = spoken(["I", "understand.", "Yes."])
        XCTAssertEqual(extract(tokens, "en"), ["I understand, yes."])
    }

    func testJoiningKeepsTheCapitalOfAName() {
        let tokens = spoken(["Yes.", "Tokyo", "is", "big."])
        XCTAssertEqual(extract(tokens, "en"), ["Yes, Tokyo is big."])
    }

    func testAShortLineOnItsOwnIsKept() {
        // The user looped just this — it is what they want.
        XCTAssertEqual(extract(spoken(["はい"]), "ja"), ["はい"])
    }
}

// MARK: - Fillers

final class FillerTests: XCTestCase {
    func testDropsJapaneseFillers() {
        let tokens = spoken(["えーと", "今日", "は", "駅", "まで", "あのー", "行き", "ます"])
        XCTAssertEqual(extract(tokens, "ja"), ["今日は駅まで行きます"])
    }

    func testDropsAFillerThatCarriesPunctuation() {
        let tokens = spoken(["えーと、", "今日", "は", "晴れ", "です"])
        XCTAssertEqual(extract(tokens, "ja"), ["今日は晴れです"])
    }

    func testKeepsSonoWhenItPointsAtSomething() {
        // その as "that" is a real word, not hesitation.
        let tokens = spoken(["その", "本", "を", "ください"])
        XCTAssertEqual(extract(tokens, "ja"), ["その本をください"])
    }

    func testDropsEnglishFillers() {
        let tokens = spoken(["Um,", "I", "think", "uh", "so"])
        XCTAssertEqual(extract(tokens, "en"), ["I think so"])
    }

    func testAFillerCarryingAFullStopKeepsTheSentenceBreak() {
        // Recognisers attach punctuation to the word before it.
        let tokens = spoken(["I", "see", "um.", "Let's", "go", "now."])
        XCTAssertEqual(extract(tokens, "en"), ["I see.", "Let's go now."])
    }

    func testOnlyFillersGiveNothing() {
        XCTAssertEqual(extract(spoken(["えーと", "あのー"]), "ja"), [])
    }
}

// MARK: - Names used to address someone

final class JapaneseNameTests: XCTestCase {
    func testDropsALeadingName() {
        let tokens = spoken(["田中", "さん", "、", "おはよう", "ござい", "ます", "。"])
        XCTAssertEqual(extract(tokens, "ja"), ["おはようございます。"])
    }

    func testKeepsALeadingNameWithoutPunctuation() {
        // Without a comma there's no telling "田中さんおはよう" from
        // "おじさん来たよ", so the name stays: a leftover name is easy to
        // delete, a mangled sentence is not.
        let tokens = spoken(["田中", "さん", "おはよう", "ござい", "ます"])
        XCTAssertEqual(extract(tokens, "ja"), ["田中さんおはようございます"])
    }

    func testDropsALeadingNameTheRecogniserKeptAsOneToken() {
        let tokens = spoken(["田中さん、", "おはよう", "ござい", "ます"])
        XCTAssertEqual(extract(tokens, "ja"), ["おはようございます"])
    }

    func testDropsATrailingName() {
        let tokens = spoken(["ありがとう", "、", "山田", "先生", "。"])
        XCTAssertEqual(extract(tokens, "ja"), ["ありがとう。"])
    }

    func testKeepsANameThatIsTheSubject() {
        // Followed by a particle, the name is part of the sentence.
        let tokens = spoken(["田中", "さん", "は", "来", "ます", "か"])
        XCTAssertEqual(extract(tokens, "ja"), ["田中さんは来ますか"])
    }

    func testKeepsATrailingNameThatCompletesTheSentence() {
        let tokens = spoken(["あれ", "が", "田中", "さん"])
        XCTAssertEqual(extract(tokens, "ja"), ["あれが田中さん"])
    }

    func testKeepsANameInTheMiddle() {
        let tokens = spoken(["今日", "は", "田中", "さん", "と", "行き", "ます"])
        XCTAssertEqual(extract(tokens, "ja"), ["今日は田中さんと行きます"])
    }

    func testANameAloneGivesNothing() {
        XCTAssertEqual(extract(spoken(["田中", "さん", "！"]), "ja"), [])
    }

    // Found in review: the tokenizer splits words like し|ます and お|母|さん,
    // and taking the fragment before an honorific as a name mangled these.

    func testDropsATrailingTitleWithoutEatingTheVerb() {
        let tokens = spoken(["よろしく", "お願い", "し", "ます", "、", "先生", "。"])
        XCTAssertEqual(extract(tokens, "ja"), ["よろしくお願いします。"])
    }

    func testDropsATrailingFamilyTitleWhole() {
        let tokens = spoken(["それ", "は", "たいへん", "です", "ね", "、", "お", "母", "さん", "。"])
        XCTAssertEqual(extract(tokens, "ja"), ["それはたいへんですね。"])
    }

    func testKeepsSetPhrasesEndingInSama() {
        XCTAssertEqual(extract(spoken(["今日", "も", "お疲れ", "さま", "。"]), "ja"), ["今日もお疲れさま。"])
        XCTAssertEqual(extract(spoken(["ありがとう", "、", "ごちそう", "さま", "。"]), "ja"), ["ありがとう、ごちそうさま。"])
        XCTAssertEqual(extract(spoken(["ご苦労", "さま", "。"]), "ja"), ["ご苦労さま。"])
    }

    func testKeepsWordsThatMerelyEndInSan() {
        XCTAssertEqual(extract(spoken(["たくさん", "ある", "ね", "。"]), "ja"), ["たくさんあるね。"])
        XCTAssertEqual(extract(spoken(["もう", "たくさん", "。"]), "ja"), ["もうたくさん。"])
        XCTAssertEqual(extract(spoken(["おじさん", "来", "た", "よ", "。"]), "ja"), ["おじさん来たよ。"])
    }

    func testKeepsAddressingEveryone() {
        // 皆さん is not a name.
        XCTAssertEqual(extract(spoken(["皆", "さん", "、", "こんにち", "は", "。"]), "ja"), ["皆さん、こんにちは。"])
    }
}

final class EnglishNameTests: XCTestCase {
    func testDropsAGreetingAndName() {
        let tokens = spoken(["Hey", "Tom,", "good", "morning."])
        XCTAssertEqual(extract(tokens, "en"), ["Good morning."])
    }

    func testDropsAGreetingAndNameWithoutPunctuation() {
        let tokens = spoken(["Hey", "Tom", "good", "morning"])
        XCTAssertEqual(extract(tokens, "en"), ["Good morning"])
    }

    func testDropsAGreetingTheTaggerJoinedIntoTheName() {
        // The tagger reads "Hi Sarah" as one name.
        let tokens = spoken(["Hi", "Sarah", "how", "are", "you"])
        XCTAssertEqual(extract(tokens, "en"), ["How are you"])
    }

    func testKeepsAGreetingFollowedByI() {
        let tokens = spoken(["Hi", "I'm", "Tom"])
        XCTAssertEqual(extract(tokens, "en"), ["Hi I'm Tom"])
    }

    func testDropsANameFollowedByAComma() {
        let tokens = spoken(["Tom,", "could", "you", "help", "me?"])
        XCTAssertEqual(extract(tokens, "en"), ["Could you help me?"])
    }

    func testDropsATrailingName() {
        let tokens = spoken(["Thank", "you,", "Sarah."])
        XCTAssertEqual(extract(tokens, "en"), ["Thank you."])
    }

    func testKeepsANameThatIsTheSubject() {
        let tokens = spoken(["Tom", "is", "waiting", "outside"])
        XCTAssertEqual(extract(tokens, "en"), ["Tom is waiting outside"])
    }

    func testKeepsANameInTheMiddle() {
        let tokens = spoken(["I", "met", "Sarah", "yesterday"])
        XCTAssertEqual(extract(tokens, "en"), ["I met Sarah yesterday"])
    }

    func testATitleAbbreviationDoesNotEndTheSentence() {
        let tokens = spoken(["Mr.", "Smith", "is", "here", "today."])
        XCTAssertEqual(extract(tokens, "en"), ["Mr. Smith is here today."])
    }

    func testAnInterjectionIsNotAGreeting() {
        // "Oh" and "OK" start ordinary sentences; what follows isn't a name.
        let tokens = spoken(["Oh", "English", "is", "hard"])
        XCTAssertEqual(extract(tokens, "en"), ["Oh English is hard"])
    }
}

// MARK: - Putting the text back together

final class TextAssemblyTests: XCTestCase {
    func testJapaneseHasNoSpaces() {
        let tokens = spoken(["今日 ", "は ", "晴れ ", "です"])
        XCTAssertEqual(extract(tokens, "ja"), ["今日は晴れです"])
    }

    func testEnglishTokensWithTrailingSpacesAreNotDoubled() {
        let tokens = spoken(["Hey ", "there ", "friend"])
        XCTAssertEqual(extract(tokens, "en"), ["Hey there friend"])
    }

    func testPunctuationTokensAttachToTheWordBefore() {
        let tokens = spoken(["Good", "morning", "."])
        XCTAssertEqual(extract(tokens, "en"), ["Good morning."])
    }

    func testOtherLanguagesOnlyGetTrimmedAndSplit() {
        // No filler or name rules for French: "Marie" stays.
        let tokens = spoken(["Bonjour", "Marie"])
        XCTAssertEqual(extract(tokens, "fr"), ["Bonjour Marie"])
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
