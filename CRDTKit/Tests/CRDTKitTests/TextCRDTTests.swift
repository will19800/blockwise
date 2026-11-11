import Foundation
import XCTest
@testable import CRDTKit

final class TextCRDTTests: XCTestCase {
    func testInsertWaitsForOriginThenIntegratesImmediately() throws {
        let origin = insert(lamport: 1, scalar: 0x41)
        let child = insert(lamport: 2, origin: origin.id, scalar: 0x42)
        var text = TextCRDT()

        XCTAssertEqual(
            try text.apply(child),
            .buffered(missing: origin.id)
        )
        XCTAssertTrue(text.isPending(child.id))
        XCTAssertEqual(text.text, "")

        XCTAssertEqual(
            try text.apply(origin),
            .applied(operationIDs: [origin.id, child.id])
        )
        XCTAssertEqual(text.text, "AB")
        XCTAssertTrue(text.hasApplied(origin.id))
        XCTAssertTrue(text.hasApplied(child.id))
        XCTAssertTrue(text.pendingOperations.isEmpty)
    }

    func testDeleteWaitsForTargetAndLeavesATombstone() throws {
        let insertion = insert(lamport: 1, scalar: 0x41)
        let deletion = delete(lamport: 2, target: insertion.id)
        var text = TextCRDT()

        XCTAssertEqual(
            try text.apply(deletion),
            .buffered(missing: insertion.id)
        )
        XCTAssertEqual(
            try text.apply(insertion),
            .applied(operationIDs: [insertion.id, deletion.id])
        )

        XCTAssertEqual(text.text, "")
        XCTAssertEqual(text.rga.elements.count, 1)
        XCTAssertTrue(text.rga.elements[0].deleted)
    }

    func testDependencyChainDrainsRecursively() throws {
        let first = insert(lamport: 1, scalar: 0x41)
        let second = insert(lamport: 2, origin: first.id, scalar: 0x42)
        let third = insert(lamport: 3, origin: second.id, scalar: 0x43)
        var text = TextCRDT()

        XCTAssertEqual(try text.apply(third), .buffered(missing: second.id))
        XCTAssertEqual(try text.apply(second), .buffered(missing: first.id))
        XCTAssertEqual(
            try text.apply(first),
            .applied(operationIDs: [first.id, second.id, third.id])
        )

        XCTAssertEqual(text.text, "ABC")
        XCTAssertEqual(text.appliedOperationIDs, [first.id, second.id, third.id])
        XCTAssertTrue(text.pendingOperations.isEmpty)
    }

    func testDuplicateDeliveryIsIgnoredWhilePendingAndAfterApply() throws {
        let origin = insert(lamport: 1, scalar: 0x41)
        let child = insert(lamport: 2, origin: origin.id, scalar: 0x42)
        var text = TextCRDT()

        XCTAssertEqual(try text.apply(child), .buffered(missing: origin.id))
        XCTAssertEqual(try text.apply(child), .duplicate)
        XCTAssertEqual(text.pendingOperations, [child])

        try text.apply(origin)
        XCTAssertEqual(try text.apply(origin), .duplicate)
        XCTAssertEqual(try text.apply(child), .duplicate)
        XCTAssertEqual(text.text, "AB")
        XCTAssertEqual(text.appliedOperationIDs.count, 2)
    }

    func testDifferentDeliveryOrdersWithDuplicatesConverge() throws {
        let first = insert(lamport: 1, replica: 1, scalar: 0x41)
        let lowerChild = insert(lamport: 2, replica: 1, origin: first.id, scalar: 0x42)
        let higherChild = insert(lamport: 2, replica: 2, origin: first.id, scalar: 0x43)
        let deletion = delete(lamport: 3, replica: 1, target: lowerChild.id)
        let operations = [first, lowerChild, higherChild, deletion]
        var ordered = TextCRDT()
        var reordered = TextCRDT()

        for operation in operations {
            try ordered.apply(operation)
        }
        for operation in [deletion, higherChild, lowerChild, deletion, first, higherChild] {
            try reordered.apply(operation)
        }

        XCTAssertEqual(ordered, reordered)
        XCTAssertEqual(ordered.text, "AC")
        XCTAssertEqual(ordered.appliedOperationIDs.count, operations.count)
    }

    func testRejectedOperationLeavesStateUnchanged() throws {
        let valid = insert(lamport: 1, scalar: 0x41)
        let invalid = insert(lamport: 2, origin: valid.id, scalar: 0xD800)
        var text = TextCRDT()
        try text.apply(valid)
        let stateBeforeRejection = text

        XCTAssertThrowsError(try text.apply(invalid)) { error in
            XCTAssertEqual(error as? RGAError, .invalidUnicodeScalar(0xD800))
        }

        XCTAssertEqual(text, stateBeforeRejection)
        XCTAssertFalse(text.isPending(invalid.id))
        XCTAssertFalse(text.hasApplied(invalid.id))
    }

    func testCodableRoundTripPreservesAppliedAndPendingState() throws {
        let origin = insert(lamport: 1, scalar: 0x41)
        let child = insert(lamport: 2, origin: origin.id, scalar: 0x42)
        let independent = insert(lamport: 1, replica: 2, scalar: 0x43)
        var original = TextCRDT()
        try original.apply(child)
        try original.apply(independent)

        let data = try JSONEncoder().encode(original)
        var decoded = try JSONDecoder().decode(TextCRDT.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(
            try decoded.apply(origin),
            .applied(operationIDs: [origin.id, child.id])
        )
        XCTAssertEqual(decoded.text, "CAB")
    }

    private func insert(
        lamport: UInt64,
        replica: UInt64 = 1,
        origin: OpID? = nil,
        scalar: UInt32
    ) -> TextOperation {
        TextOperation(
            id: OpID(lamport: lamport, replica: ReplicaID(raw: replica)),
            body: .insert(origin: origin, scalar: scalar)
        )
    }

    private func delete(
        lamport: UInt64,
        replica: UInt64 = 1,
        target: OpID
    ) -> TextOperation {
        TextOperation(
            id: OpID(lamport: lamport, replica: ReplicaID(raw: replica)),
            body: .delete(target: target)
        )
    }
}

