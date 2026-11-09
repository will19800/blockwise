import XCTest
@testable import Blockwise

final class BlockwiseTests: XCTestCase {
    func testLocalPackagesAreLinked() {
        XCTAssertEqual(BlockwiseMetadata.enginePackageName, "CRDTKit")
        XCTAssertEqual(BlockwiseMetadata.syncPackageName, "SyncKit")
        XCTAssertEqual(BlockwiseMetadata.snapshotFormatVersion, 1)
    }
}

