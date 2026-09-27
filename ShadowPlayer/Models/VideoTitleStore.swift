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

    /// Names the user typed.
    @Published private(set) var custom: [String: String] = [:]

    /// Original filenames from the photo library, without the extension.
    /// Persisted rather than just cached: once a video is deleted from the
    /// library the filename can no longer be read, and its word list would be
    /// left showing a bare identifier.
    @Published private(set) var filenames: [String: String] = [:]

    /// Videos whose asset is no longer in the photo library. Their notes are
    /// still worth showing; the video just cannot be played any more.
    @Published private(set) var missing: Set<String> = []

    private let customKey = "videoTitles"
    private let filenameKey = "videoFilenames"

    private init() {
        custom = UserDefaults.standard.dictionary(forKey: customKey) as? [String: String] ?? [:]
        filenames = UserDefaults.standard.dictionary(forKey: filenameKey) as? [String: String] ?? [:]
    }

    /// The name to show, or nil when neither a typed title nor a known filename
    /// exists — callers then let the duration lead instead, rather than filling
    /// the list with "Untitled".
    func displayName(for videoID: String) -> String? {
        if let typed = custom[videoID], !typed.isEmpty { return typed }
        return filenames[videoID]
    }

    func isMissing(_ videoID: String) -> Bool { missing.contains(videoID) }

    /// Passing an empty title clears it, so the name falls back to the filename.
    func setTitle(_ title: String?, for videoID: String) {
        let trimmed = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            custom.removeValue(forKey: videoID)
        } else {
            custom[videoID] = trimmed
        }
        UserDefaults.standard.set(custom, forKey: customKey)
    }

    /// Looks the video up in the photo library: records its filename the first
    /// time, and notes when the asset has gone. Runs off the main actor — the
    /// lookup is disk work and must not happen while a row is rendering.
    func refresh(_ videoID: String) async {
        let found = await Task.detached(priority: .utility) { () -> (exists: Bool, stem: String?) in
            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [videoID], options: nil).firstObject
            else { return (false, nil) }
            let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename
            let stem = (filename as NSString?)?.deletingPathExtension
            return (true, (stem?.isEmpty == false) ? stem : nil)
        }.value

        if found.exists {
            missing.remove(videoID)
        } else {
            missing.insert(videoID)
        }

        if let stem = found.stem, filenames[videoID] != stem {
            filenames[videoID] = stem
            UserDefaults.standard.set(filenames, forKey: filenameKey)
        }
    }
}
