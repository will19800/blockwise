import XCTest
@testable import CRDTKit

final class RGATests: XCTestCase {
    func testInsertsUnicodeScalarsAfterTheirOrigins() throws {
        let letter = OpID(lamport: 1, replica: ReplicaID(raw: 1))
        let emoji = OpID(lamport: 2, replica: ReplicaID(raw: 1))
        var text = RGA()

        try text.insert(id: letter, origin: nil, scalar: 0x41)
        try text.insert(id: emoji, origin: letter, scalar: 0x1F642)

        XCTAssertEqual(text.text, "A🙂")
        XCTAssertEqual(text.visibleScalars, [0x41, 0x1F642])
    }

    func testConcurrentRootInsertsConvergeRegardlessOfDeliveryOrder() throws {
        let lowerID = OpID(lamport: 1, replica: ReplicaID(raw: 1))
        let higherID = OpID(lamport: 1, replica: ReplicaID(raw: 2))
        var first = RGA()
        var second = RGA()

        try first.insert(id: lowerID, origin: nil, scalar: 0x41)
        try first.insert(id: higherID, origin: nil, scalar: 0x42)

        try second.insert(id: higherID, origin: nil, scalar: 0x42)
        try second.insert(id: lowerID, origin: nil, scalar: 0x41)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.text, "BA")
        XCTAssertEqual(first.visibleElementIDs, [higherID, lowerID])
    }

    func testConcurrentChildrenConvergeBesideExistingDescendants() throws {
        let origin = OpID(lamport: 1, replica: ReplicaID(raw: 1))
        let lowerChild = OpID(lamport: 2, replica: ReplicaID(raw: 1))
        let higherChild = OpID(lamport: 2, replica: ReplicaID(raw: 2))
        var first = RGA()
        var second = RGA()

        try first.insert(id: origin, origin: nil, scalar: 0x41)
        try first.insert(id: lowerChild, origin: origin, scalar: 0x42)
        try first.insert(id: higherChild, origin: origin, scalar: 0x43)

        try second.insert(id: origin, origin: nil, scalar: 0x41)
        try second.insert(id: higherChild, origin: origin, scalar: 0x43)
        try second.insert(id: lowerChild, origin: origin, scalar: 0x42)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.text, "ACB")
    }

    func testInsertionAndDeletionAreIdempotent() throws {
        let ID = OpID(lamport: 1, replica: ReplicaID(raw: 1))
        var text = RGA()

        XCTAssertTrue(try text.insert(id: ID, origin: nil, scalar: 0x41))
        XCTAssertFalse(try text.insert(id: ID, origin: nil, scalar: 0x41))
        XCTAssertTrue(try text.delete(target: ID))
        XCTAssertFalse(try text.delete(target: ID))

        XCTAssertEqual(text.text, "")
        XCTAssertEqual(text.elements.count, 1)
        XCTAssertTrue(text.elements[0].deleted)
    }

    func testRejectsAConflictingElementID() throws {
        let ID = OpID(lamport: 1, replica: ReplicaID(raw: 1))
        var text = RGA()
        try text.insert(id: ID, origin: nil, scalar: 0x41)

        XCTAssertThrowsError(try text.insert(id: ID, origin: nil, scalar: 0x42)) { error in
            XCTAssertEqual(error as? RGAError, .conflictingElementID(ID))
        }
    }

    func testReportsMissingAndNonCausalDependencies() {
        let missingOrigin = OpID(lamport: 4, replica: ReplicaID(raw: 1))
        let child = OpID(lamport: 5, replica: ReplicaID(raw: 1))
        var text = RGA()

        XCTAssertThrowsError(
            try text.insert(id: child, origin: missingOrigin, scalar: 0x41)
        ) { error in
            XCTAssertEqual(error as? RGAError, .missingOrigin(missingOrigin))
        }

        XCTAssertThrowsError(
            try text.insert(id: missingOrigin, origin: child, scalar: 0x41)
        ) { error in
            XCTAssertEqual(
                error as? RGAError,
                .nonCausalOrigin(origin: child, child: missingOrigin)
            )
        }

        XCTAssertThrowsError(try text.delete(target: missingOrigin)) { error in
            XCTAssertEqual(error as? RGAError, .missingTarget(missingOrigin))
        }
    }

    func testRejectsInvalidUnicodeScalar() {
        let ID = OpID(lamport: 1, replica: ReplicaID(raw: 1))
        var text = RGA()

        XCTAssertThrowsError(try text.insert(id: ID, origin: nil, scalar: 0xD800)) { error in
            XCTAssertEqual(error as? RGAError, .invalidUnicodeScalar(0xD800))
        }
    }
}

