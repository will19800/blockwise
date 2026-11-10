import Foundation
import XCTest
@testable import CRDTKit

final class IdentifiersTests: XCTestCase {
    func testOperationIDsOrderByLamportThenReplica() {
        let firstReplica = ReplicaID(raw: 1)
        let secondReplica = ReplicaID(raw: 2)

        let IDs = [
            OpID(lamport: 2, replica: firstReplica),
            OpID(lamport: 1, replica: secondReplica),
            OpID(lamport: 1, replica: firstReplica),
        ]

        XCTAssertEqual(
            IDs.sorted(),
            [
                OpID(lamport: 1, replica: firstReplica),
                OpID(lamport: 1, replica: secondReplica),
                OpID(lamport: 2, replica: firstReplica),
            ]
        )
    }

    func testOperationIDCodableRoundTrip() throws {
        let original = OpID(lamport: 42, replica: ReplicaID(raw: 7))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OpID.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}

