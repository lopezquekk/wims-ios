//
//  WimsUITests.swift
//  WimsUITests
//
//  Created by Camilo Lopez on 12/29/25.
//

import Testing
import XCTest

@Suite("UI Tests")
struct WimsUITests {
    @Test("Example UI test")
    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use #expect and related functions to verify your tests produce the correct results.
    }

    @Test("Launch performance")
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
