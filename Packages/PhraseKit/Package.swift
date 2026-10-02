// swift-tools-version: 5.9
import PackageDescription

// The rules that turn a looped stretch of recognised speech into word-list
// lines. Kept apart from the app so they can be tested with `swift test` on a
// Mac, where the speech recogniser itself is not available.
let package = Package(
    name: "PhraseKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "PhraseKit", targets: ["PhraseKit"]),
    ],
    targets: [
        .target(name: "PhraseKit"),
        .testTarget(name: "PhraseKitTests", dependencies: ["PhraseKit"]),
    ]
)
