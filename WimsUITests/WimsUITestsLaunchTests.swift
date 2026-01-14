//
//  WimsUITestsLaunchTests.swift
//  WimsUITests
//
//  Created by Camilo Lopez on 12/29/25.
//

import Testing
import XCTest

@Suite("Launch Tests")
struct WimsUITestsLaunchTests {
    static var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @Test("App launch")
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
