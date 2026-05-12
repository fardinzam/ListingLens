//
//  ListingLensUITests.swift
//  ListingLensUITests
//
//  Created by Fardin Zaman on 5/11/26.
//

import XCTest

final class ListingLensUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainDemoPathShowsHostGuestAndQualityReport() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.scrollViews["host-dashboard"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bright Mission Studio Near Transit"].exists)

        app.tabBars.buttons["Guest"].tap()
        XCTAssertTrue(app.scrollViews["guest-trust"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Reliability Indicators"].exists)

        app.buttons["view-full-quality-report"].tap()
        XCTAssertTrue(app.scrollViews["quality-report-detail"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Risk and Positive Signals"].exists)
    }

    @MainActor
    func testRecommendationCompletionUpdatesHostDashboard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.scrollViews["host-dashboard"].waitForExistence(timeout: 5))

        let completeButton = app.buttons["complete-recommendation-rec_checkin_photos_001"]
        XCTAssertTrue(completeButton.exists)
        completeButton.tap()

        XCTAssertFalse(completeButton.waitForExistence(timeout: 2))
    }
}
