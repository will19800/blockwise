/// An immutable operation against a single RGA text sequence.
public struct TextOperation: Codable, Equatable, Sendable {
    public let id: OpID
    public let body: Body

    public init(id: OpID, body: Body) {
        self.id = id
        self.body = body
    }

    public enum Body: Codable, Equatable, Sendable {
        case insert(origin: OpID?, scalar: UInt32)
        case delete(target: OpID)
    }

    var createdElementID: OpID? {
        switch body {
        case .insert:
            id
        case .delete:
            nil
        }
    }
}

/// The immediate result of delivering an operation to `TextCRDT`.
public enum TextApplyOutcome: Equatable, Sendable {
    /// The operation and any newly unblocked operations were integrated.
    case applied(operationIDs: [OpID])

    /// The operation is retained until the named element arrives.
    case buffered(missing: OpID)

    /// An applied or already-buffered operation with this ID was delivered again.
    case duplicate
}

