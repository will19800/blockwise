/// A deterministic Lamport clock owned by one replica.
public struct LamportClock: Sendable {
    public let replicaID: ReplicaID
    public private(set) var counter: UInt64

    public init(replicaID: ReplicaID, initialCounter: UInt64 = 0) {
        self.replicaID = replicaID
        self.counter = initialCounter
    }

    /// Advances the local clock and returns an ID for a new local operation.
    public mutating func issueID() -> OpID {
        precondition(counter < UInt64.max, "Lamport counter exhausted")
        counter += 1
        return OpID(lamport: counter, replica: replicaID)
    }

    /// Observes a remote operation without issuing a local event.
    public mutating func observe(_ remoteID: OpID) {
        counter = max(counter, remoteID.lamport)
    }
}

