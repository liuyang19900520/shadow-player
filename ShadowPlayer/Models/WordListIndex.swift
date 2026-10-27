import Foundation
import PracticeKit

/// Finds every saved word list by scanning the stored keys.
///
/// There is deliberately no separate index to maintain: one would drift out of
/// sync with the lists themselves, and it would not know about lists saved
/// before it existed. Scanning also surfaces notes whose video has since been
/// deleted or swiped out of Recent — data that was previously impossible to
/// reach again, because a list could only be found through a row still holding
/// its identifier.
enum WordListIndex {
    private static let prefix = "words_"

    /// Video identifiers that have at least one word written down, with how
    /// many. Reading each list once here avoids hitting storage per render.
    static func listsWithWords() -> [(videoID: String, count: Int)] {
        UserDefaults.standard.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
            .map { (videoID: $0, count: wordCount(for: $0)) }
            .filter { $0.count > 0 }
    }

    static func wordCount(for videoID: String) -> Int {
        WordListStore.load(videoID: videoID).filter { !$0.trimmedText.isEmpty }.count
    }

    /// Words added on `day`, by the language of the playlist their video is in.
    /// Words saved before rows had a date, and blank rows, count toward no day.
    static func wordsAdded(on day: DayKey) -> (total: Int, byLanguage: [PracticeLanguage: Int]) {
        var total = 0
        var byLanguage: [PracticeLanguage: Int] = [:]
        for (videoID, _) in listsWithWords() {
            let count = WordListStore.load(videoID: videoID).filter { entry in
                guard let createdAt = entry.createdAt, !entry.trimmedText.isEmpty else { return false }
                return DayKey(createdAt) == day
            }.count
            guard count > 0 else { continue }
            total += count
            // Only videos actually in a playlist get a tracked language; the
            // shared default can't be mistaken for one.
            if TranslationScope.isInPlaylist(videoID),
               let language = PracticeLanguage(TranslationScope.forVideo(videoID).audioLanguage) {
                byLanguage[language, default: 0] += count
            }
        }
        return (total, byLanguage)
    }
}
