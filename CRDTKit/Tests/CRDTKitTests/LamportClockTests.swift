import XCTest
@testable import CRDTKit

final class LamportClockTests: XCTestCase {
    func testLocalIDsIncreaseMonotonically() {
        let replica = ReplicaID(raw: 9)
        var clock = LamportClock(replicaID: replica)

        XCTAssertEqual(clock.issueID(), OpID(lamport: 1, replica: replica))
        XCTAssertEqual(clock.issueID(), OpID(lamport: 2, replica: replica))
        XCTAssertEqual(clock.counter, 2)
    }

    func testRemoteObservationAdvancesNextLocalID() {
        let localReplica = ReplicaID(raw: 1)
        var clock = LamportClock(replicaID: localReplica, initialCounter: 3)

        clock.observe(OpID(lamport: 11, replica: ReplicaID(raw: 2)))

        XCTAssertEqual(clock.counter, 11)
        XCTAssertEqual(clock.issueID(), OpID(lamport: 12, replica: localReplica))
    }

    func testOlderRemoteObservationDoesNotMoveClockBackward() {
        var clock = LamportClock(replicaID: ReplicaID(raw: 1), initialCounter: 8)

        clock.observe(OpID(lamport: 3, replica: ReplicaID(raw: 2)))

        XCTAssertEqual(clock.counter, 8)
    }
}

