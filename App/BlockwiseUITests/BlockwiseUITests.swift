import XCTest

final class BlockwiseUITests: XCTestCase {
    @MainActor
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["blockwise.title"].waitForExistence(timeout: 2)
        )
    }
}

