import CRDTKit

public struct TextFuzzConfiguration: Equatable, Sendable {
    public var iterations: Int
    public var actionsPerIteration: Int
    public var replicaCount: Int
    public var seed: UInt64

    public init(
        iterations: Int = 1_000,
        actionsPerIteration: Int = 100,
        replicaCount: Int = 3,
        seed: UInt64 = 0xB10C_715E
    ) {
        self.iterations = iterations
        self.actionsPerIteration = actionsPerIteration
        self.replicaCount = replicaCount
        self.seed = seed
    }
}

public struct TextFuzzSummary: Equatable, Sendable {
    public let iterations: Int
    public let generatedOperations: Int
    public let deliveries: Int
    public let seed: UInt64

    public init(iterations: Int, generatedOperations: Int, deliveries: Int, seed: UInt64) {
        self.iterations = iterations
        self.generatedOperations = generatedOperations
        self.deliveries = deliveries
        self.seed = seed
    }
}

public enum TextFuzzError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidConfiguration(String)
    case convergenceFailure(iterationSeed: UInt64, reason: String, trace: [String])

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            "Invalid fuzz configuration: \(reason)"
        case let .convergenceFailure(iterationSeed, reason, trace):
            "Convergence failure for seed 0x\(String(iterationSeed, radix: 16)): \(reason)\n"
                + trace.joined(separator: "\n")
        }
    }
}

/// Generates concurrent edits, delays and reorders their delivery, and verifies that
/// every replica reaches exactly the same materialized and internal state.
public enum TextConvergenceFuzzer {
    private static let iterationStride: UInt64 = 0x9E37_79B9_7F4A_7C15
    private static let fuzzScalars = Array("abcdefghijklmnopqrstuvwxyz 🧩\n".unicodeScalars)

    public static func run(
        configuration: TextFuzzConfiguration = TextFuzzConfiguration()
    ) throws -> TextFuzzSummary {
        try validate(configuration)

        var operationCount = 0
        var deliveryCount = 0

        for iteration in 0 ..< configuration.iterations {
            let iterationSeed = configuration.seed &+
                (UInt64(iteration) &* iterationStride)
            let result = try runIteration(
                seed: iterationSeed,
                actionCount: configuration.actionsPerIteration,
                replicaCount: configuration.replicaCount
            )
            operationCount += result.operations
            deliveryCount += result.deliveries
        }

        return TextFuzzSummary(
            iterations: configuration.iterations,
            generatedOperations: operationCount,
            deliveries: deliveryCount,
            seed: configuration.seed
        )
    }

    private static func validate(_ configuration: TextFuzzConfiguration) throws {
        guard configuration.iterations > 0 else {
            throw TextFuzzError.invalidConfiguration("iterations must be positive")
        }
        guard configuration.actionsPerIteration > 0 else {
            throw TextFuzzError.invalidConfiguration("actions must be positive")
        }
        guard (2 ... 5).contains(configuration.replicaCount) else {
            throw TextFuzzError.invalidConfiguration("replicas must be between 2 and 5")
        }
    }

    private struct Replica {
        var clock: LamportClock
        var text = TextCRDT()
    }

    private struct IterationResult {
        let operations: Int
        let deliveries: Int
    }

    private struct QueuedDelivery {
        let recipient: Int
        let operation: TextOperation
    }

    private static func runIteration(
        seed: UInt64,
        actionCount: Int,
        replicaCount: Int
    ) throws -> IterationResult {
        var generator = SplitMix64(seed: seed)
        var replicas = (0 ..< replicaCount).map { index in
            Replica(clock: LamportClock(replicaID: ReplicaID(raw: UInt64(index + 1))))
        }
        var operations: [TextOperation] = []
        var queued: [QueuedDelivery] = []
        var trace: [String] = ["seed=0x\(String(seed, radix: 16))"]
        var deliveries = 0

        for action in 0 ..< actionCount {
            if !queued.isEmpty, generator.chance(percent: 28) {
                let deliveryIndex = generator.nextInt(upperBound: queued.count)
                let delivery = queued.remove(at: deliveryIndex)
                try apply(
                    delivery.operation,
                    to: delivery.recipient,
                    replicas: &replicas,
                    seed: seed,
                    trace: trace
                )
                deliveries += 1
                trace.append(
                    "\(action): deliver \(describe(delivery.operation)) -> r\(delivery.recipient + 1)"
                )
                continue
            }

            let author = generator.nextInt(upperBound: replicaCount)
            let visible = replicas[author].text.rga.visibleElementIDs
            let shouldDelete = !visible.isEmpty && generator.chance(percent: 34)
            let operation: TextOperation

            if shouldDelete {
                let target = visible[generator.nextInt(upperBound: visible.count)]
                operation = TextOperation(
                    id: replicas[author].clock.issueID(),
                    body: .delete(target: target)
                )
            } else {
                let origin: OpID?
                if visible.isEmpty || generator.chance(percent: 16) {
                    origin = nil
                } else {
                    origin = visible[generator.nextInt(upperBound: visible.count)]
                }
                let scalar = fuzzScalars[generator.nextInt(upperBound: fuzzScalars.count)].value
                operation = TextOperation(
                    id: replicas[author].clock.issueID(),
                    body: .insert(origin: origin, scalar: scalar)
                )
            }

            try apply(operation, to: author, replicas: &replicas, seed: seed, trace: trace)
            operations.append(operation)
            trace.append("\(action): r\(author + 1) creates \(describe(operation))")

            for recipient in 0 ..< replicaCount where recipient != author {
                queued.append(QueuedDelivery(recipient: recipient, operation: operation))
                if generator.chance(percent: 25) {
                    queued.append(QueuedDelivery(recipient: recipient, operation: operation))
                }
            }
        }

        // Replay the complete immutable history in a different order at every replica.
        // This also covers operations whose simulated network deliveries remain queued.
        for recipient in 0 ..< replicaCount {
            var replay = operations
            generator.shuffle(&replay)
            for operation in replay {
                try apply(operation, to: recipient, replicas: &replicas, seed: seed, trace: trace)
                deliveries += 1
                if generator.chance(percent: 20) {
                    try apply(operation, to: recipient, replicas: &replicas, seed: seed, trace: trace)
                    deliveries += 1
                }
            }
        }

        try verify(replicas: replicas, operations: operations, seed: seed, trace: trace)
        return IterationResult(operations: operations.count, deliveries: deliveries)
    }

    private static func apply(
        _ operation: TextOperation,
        to recipient: Int,
        replicas: inout [Replica],
        seed: UInt64,
        trace: [String]
    ) throws {
        replicas[recipient].clock.observe(operation.id)
        do {
            try replicas[recipient].text.apply(operation)
        } catch {
            throw TextFuzzError.convergenceFailure(
                iterationSeed: seed,
                reason: "r\(recipient + 1) rejected \(describe(operation)): \(error)",
                trace: trace
            )
        }
    }

    private static func verify(
        replicas: [Replica],
        operations: [TextOperation],
        seed: UInt64,
        trace: [String]
    ) throws {
        guard let expected = replicas.first?.text else {
            return
        }
        let operationIDs = Set(operations.map(\.id))
        let insertedIDs = Set(operations.compactMap { operation -> OpID? in
            if case .insert = operation.body {
                return operation.id
            }
            return nil
        })

        for (index, replica) in replicas.enumerated() {
            guard replica.text.pendingOperations.isEmpty else {
                throw failure(
                    seed: seed,
                    reason: "r\(index + 1) retained \(replica.text.pendingOperations.count) operations",
                    trace: trace
                )
            }
            guard Set(replica.text.appliedOperationIDs) == operationIDs else {
                throw failure(
                    seed: seed,
                    reason: "r\(index + 1) did not apply the complete history",
                    trace: trace
                )
            }
            guard replica.text == expected else {
                throw failure(
                    seed: seed,
                    reason: "r\(index + 1) diverged: \(replica.text.text.debugDescription) != \(expected.text.debugDescription)",
                    trace: trace
                )
            }

            let materializedIDs = replica.text.rga.elements.map(\.id)
            guard materializedIDs.count == insertedIDs.count,
                  Set(materializedIDs) == insertedIDs
            else {
                throw failure(
                    seed: seed,
                    reason: "r\(index + 1) lost or duplicated inserted elements",
                    trace: trace
                )
            }
        }
    }

    private static func failure(seed: UInt64, reason: String, trace: [String]) -> TextFuzzError {
        .convergenceFailure(iterationSeed: seed, reason: reason, trace: trace)
    }

    private static func describe(_ operation: TextOperation) -> String {
        let identifier = describe(operation.id)
        switch operation.body {
        case let .insert(origin, scalar):
            let anchor = origin.map(describe) ?? "root"
            let value = Unicode.Scalar(scalar).map(String.init) ?? "U+\(String(scalar, radix: 16))"
            return "insert[\(identifier), after=\(anchor), value=\(value.debugDescription)]"
        case let .delete(target):
            return "delete[\(identifier), target=\(describe(target))]"
        }
    }

    private static func describe(_ identifier: OpID) -> String {
        "\(identifier.lamport)@\(identifier.replica.raw)"
    }
}
