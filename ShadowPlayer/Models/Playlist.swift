import Foundation

/// A named, ordered collection of videos.
struct Playlist: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var videos: [PickedVideo] = []
}
