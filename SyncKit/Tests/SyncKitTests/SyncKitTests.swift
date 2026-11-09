import XCTest
@testable import SyncKit

final class SyncKitTests: XCTestCase {
    func testPackageConsumesCRDTKitMetadata() {
        XCTAssertEqual(SyncKitMetadata.packageName, "SyncKit")
        XCTAssertEqual(SyncKitMetadata.supportedSnapshotFormatVersion, 1)
    }
}

