import Foundation

/// A language the app can translate between. The raw value is the BCP-47 tag
/// Apple's Translation framework expects, so it doubles as the stored value.
enum TranslationLanguage: String, CaseIterable, Identifiable, Codable {
    case chinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"

    var id: String { rawValue }

    /// Shown in its own language, the way Apple lists languages.
    var label: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        }
    }
}

/// Keys for the translation preferences. The switch is one app-wide setting;
/// the language pair is stored per scope (see `TranslationScope`).
enum TranslationDefaults {
    static let enabledKey = "wordTranslationsEnabled"
    static let sourceKeyPrefix = "wordTranslationSource_"
    static let targetKeyPrefix = "wordTranslationTarget_"

    /// Stored value that stands for automatic detection.
    static let autoSource = ""
}

/// Which set of languages a word list uses. Stored per playlist, so a playlist
/// of English videos and one of Japanese videos each keep their own pair
/// instead of overwriting one shared setting.
struct TranslationScope: Equatable {
    /// Suffix that separates one playlist's languages from another's.
    let id: String
    /// Playlist name, shown in the settings sheet; nil for the shared default.
    let name: String?

    /// Used by videos that aren't in any playlist.
    static let shared = TranslationScope(id: "default", name: nil)

    static func playlist(_ playlist: Playlist) -> TranslationScope {
        TranslationScope(id: playlist.id.uuidString, name: playlist.name)
    }

    /// A video takes the languages of the first playlist it belongs to, so every
    /// video in an English playlist shares one setting while a Japanese playlist
    /// keeps its own. Videos in no playlist fall back to the shared default.
    static func forVideo(_ videoID: String) -> TranslationScope {
        let owner = PlaylistStore.loadAll().first { playlist in
            playlist.videos.contains { $0.id == videoID }
        }
        return owner.map(TranslationScope.playlist) ?? .shared
    }

    var sourceKey: String { TranslationDefaults.sourceKeyPrefix + id }
    var targetKey: String { TranslationDefaults.targetKeyPrefix + id }
}
