import Foundation

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
}
