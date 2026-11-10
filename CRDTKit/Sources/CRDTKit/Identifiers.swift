/// A stable identifier for one CRDT replica.
///
/// Replica IDs are minted outside CRDTKit and injected so the engine remains
/// deterministic.
public struct ReplicaID: Hashable, Codable, Sendable, Comparable {
    public let raw: UInt64

    public init(raw: UInt64) {
        self.raw = raw
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.raw < rhs.raw
    }
}

/// A globally unique, totally ordered operation identifier.
public struct OpID: Hashable, Codable, Sendable, Comparable {
    public let lamport: UInt64
    public let replica: ReplicaID

    public init(lamport: UInt64, replica: ReplicaID) {
        self.lamport = lamport
        self.replica = replica
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.lamport != rhs.lamport {
            return lhs.lamport < rhs.lamport
        }

        return lhs.replica < rhs.replica
    }
}

