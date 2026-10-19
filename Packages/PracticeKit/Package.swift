// swift-tools-version: 5.9
import PackageDescription

// The rules behind the daily close-reading check-in: which looped stretches
// count, which day they belong to, and how a day is marked. Kept apart from the
// app so they can be tested with `swift test` on a Mac.
let package = Package(
    name: "PracticeKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "PracticeKit", targets: ["PracticeKit"]),
    ],
    targets: [
        .target(name: "PracticeKit"),
        .testTarget(name: "PracticeKitTests", dependencies: ["PracticeKit"]),
    ]
)
