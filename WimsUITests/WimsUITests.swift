//
//  WimsUITests.swift
//  WimsUITests
//
//  Created by Camilo Lopez on 12/29/25.
//

// swiftlint:disable swift_testing_test swift_testing_suite swift_testing_expect
import XCTest

final class WimsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Teardown code
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
// swiftlint:enable swift_testing_test swift_testing_suite swift_testing_expect
