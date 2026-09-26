import Foundation
import Photos

/// Display names for videos.
///
/// Titles are keyed by asset identifier rather than stored on `PickedVideo`,
/// because the same video exists as a separate copy in Recent and in every
/// playlist holding it — renaming one copy would leave the others stale.
@MainActor
final class VideoTitleStore: ObservableObject {
    static let shared = VideoTitleStore()

    /// Names the user typed. Persisted.
    @Published private(set) var custom: [String: String] = [:]

    /// Original filenames from the photo library, without the extension. Cached
    /// in memory only: a filename never changes, so there is nothing worth
    /// persisting, and re-reading it on launch is cheap.
    @Published private(set) var filenames: [String: String] = [:]

    private let key = "videoTitles"

    private init() {
        custom = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    /// The name to show, or nil when neither a typed title nor a usable
    /// filename is known — callers then let the duration lead instead, rather
    /// than filling the list with "Untitled".
    func displayName(for videoID: String) -> String? {
        if let typed = custom[videoID], !typed.isEmpty { return typed }
        return filenames[videoID]
    }

    /// Passing an empty title clears it, so the name falls back to the filename.
    func setTitle(_ title: String?, for videoID: String) {
        let trimmed = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            custom.removeValue(forKey: videoID)
        } else {
            custom[videoID] = trimmed
        }
        UserDefaults.standard.set(custom, forKey: key)
    }

    /// Reads the original filename once and caches it. Off the main actor: the
    /// library lookup is disk work and must not run while a row is rendering.
    func loadFilename(for videoID: String) async {
        guard filenames[videoID] == nil else { return }

        let stem = await Task.detached(priority: .utility) { () -> String? in
            guard
                let asset = PHAsset.fetchAssets(withLocalIdentifiers: [videoID], options: nil).firstObject,
                let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename
            else { return nil }
            let stem = (filename as NSString).deletingPathExtension
            return stem.isEmpty ? nil : stem
        }.value

        if let stem { filenames[videoID] = stem }
    }
}
