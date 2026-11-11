/// A small deterministic generator suitable for reproducible randomized tests.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    public mutating func nextInt(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        return Int(next() % UInt64(upperBound))
    }

    public mutating func chance(percent: Int) -> Bool {
        precondition((0 ... 100).contains(percent))
        return nextInt(upperBound: 100) < percent
    }

    public mutating func shuffle<Element>(_ values: inout [Element]) {
        guard values.count > 1 else {
            return
        }

        for index in stride(from: values.count - 1, through: 1, by: -1) {
            values.swapAt(index, nextInt(upperBound: index + 1))
        }
    }
}
