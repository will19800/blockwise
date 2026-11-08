import XCTest
@testable import CRDTKit

final class CRDTKitTests: XCTestCase {
    func testPackageMetadataIsStable() {
        XCTAssertEqual(CRDTKitMetadata.packageName, "CRDTKit")
        XCTAssertEqual(CRDTKitMetadata.snapshotFormatVersion, 1)
    }
}

