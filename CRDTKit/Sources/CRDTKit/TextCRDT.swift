/// Delivery-order-independent state for one RGA text sequence.
///
/// Operations can arrive more than once or before their dependencies. Applied operation
/// IDs provide idempotence, while missing origins and delete targets are retained in a
/// dependency-keyed buffer and retried as soon as an insertion creates that element.
public struct TextCRDT: Codable, Equatable, Sendable {
    public private(set) var rga: RGA

    private var appliedIDs: Set<OpID>
    private var pendingByDependency: [OpID: [TextOperation]]
    private var pendingIDs: Set<OpID>

    public init() {
        rga = RGA()
        appliedIDs = []
        pendingByDependency = [:]
        pendingIDs = []
    }

    public var text: String {
        rga.text
    }

    public var appliedOperationIDs: [OpID] {
        appliedIDs.sorted()
    }

    public var pendingOperations: [TextOperation] {
        pendingByDependency.values
            .flatMap { $0 }
            .sorted { $0.id < $1.id }
    }

    public func hasApplied(_ operationID: OpID) -> Bool {
        appliedIDs.contains(operationID)
    }

    public func isPending(_ operationID: OpID) -> Bool {
        pendingIDs.contains(operationID)
    }

    /// Delivers an operation transactionally.
    ///
    /// A rejected operation leaves the receiver unchanged, including operations that
    /// would otherwise have been released from the pending buffer.
    @discardableResult
    public mutating func apply(_ operation: TextOperation) throws -> TextApplyOutcome {
        var candidate = self
        let outcome = try candidate.applyInPlace(operation)
        self = candidate
        return outcome
    }

    private mutating func applyInPlace(
        _ operation: TextOperation
    ) throws -> TextApplyOutcome {
        guard !appliedIDs.contains(operation.id), !pendingIDs.contains(operation.id) else {
            return .duplicate
        }

        do {
            try integrate(operation)
        } catch let error as RGAError {
            guard let dependency = missingDependency(from: error) else {
                throw error
            }

            buffer(operation, missing: dependency)
            return .buffered(missing: dependency)
        }

        appliedIDs.insert(operation.id)
        var integratedIDs = [operation.id]
        var createdElementIDs = operation.createdElementID.map { [$0] } ?? []
        var nextDependencyIndex = 0

        while nextDependencyIndex < createdElementIDs.count {
            let dependency = createdElementIDs[nextDependencyIndex]
            nextDependencyIndex += 1

            guard var waiting = pendingByDependency.removeValue(forKey: dependency) else {
                continue
            }
            waiting.sort { $0.id < $1.id }

            for pendingOperation in waiting {
                pendingIDs.remove(pendingOperation.id)

                if appliedIDs.contains(pendingOperation.id) {
                    continue
                }

                do {
                    try integrate(pendingOperation)
                } catch let error as RGAError {
                    guard let nextDependency = missingDependency(from: error) else {
                        throw error
                    }

                    buffer(pendingOperation, missing: nextDependency)
                    continue
                }

                appliedIDs.insert(pendingOperation.id)
                integratedIDs.append(pendingOperation.id)
                if let createdElementID = pendingOperation.createdElementID {
                    createdElementIDs.append(createdElementID)
                }
            }
        }

        return .applied(operationIDs: integratedIDs)
    }

    private mutating func integrate(_ operation: TextOperation) throws {
        switch operation.body {
        case let .insert(origin, scalar):
            try rga.insert(id: operation.id, origin: origin, scalar: scalar)
        case let .delete(target):
            try rga.delete(target: target)
        }
    }

    private mutating func buffer(_ operation: TextOperation, missing dependency: OpID) {
        pendingByDependency[dependency, default: []].append(operation)
        pendingIDs.insert(operation.id)
    }

    private func missingDependency(from error: RGAError) -> OpID? {
        switch error {
        case let .missingOrigin(origin):
            origin
        case let .missingTarget(target):
            target
        case .conflictingElementID, .invalidUnicodeScalar, .nonCausalOrigin:
            nil
        }
    }
}

