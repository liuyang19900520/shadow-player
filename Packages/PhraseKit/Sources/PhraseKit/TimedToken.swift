/// One recognised word, or punctuation mark, and when it was spoken.
public struct TimedToken: Equatable, Sendable {
    public let text: String
    /// Seconds from the start of the video.
    public let start: Double
    public let end: Double

    public init(_ text: String, _ start: Double, _ end: Double) {
        self.text = text
        self.start = start
        self.end = end
    }

    /// How much of the token falls inside `range`, from 0 to 1. A token with no
    /// length counts as wholly inside or outside, by where it sits.
    func fractionInside(_ range: ClosedRange<Double>) -> Double {
        let length = end - start
        guard length > 0 else { return range.contains(start) ? 1 : 0 }
        let overlap = min(end, range.upperBound) - max(start, range.lowerBound)
        return max(0, overlap) / length
    }
}
