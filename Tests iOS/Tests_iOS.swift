//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Vito Royeca on 4/21/22.
//

import XCTest

class Tests_iOS: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testScreenshots() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        let tabBar = XCUIApplication().tabBars["Tab Bar"]

        tabBar.buttons["News"].tap()
        sleep(4)
        snapshot("01News")

        tabBar.buttons["Sets"].tap()
        sleep(4)
        snapshot("02Sets")

        let tablesQuery = app.tables

        tablesQuery.cells.element(boundBy: 0).tap()
        sleep(4)
        snapshot("03Set")

        let collectionsQuery = app.collectionViews

        collectionsQuery.cells.element(boundBy: 1).tap()
        collectionsQuery.cells.element(boundBy: 1).swipeUp()
        sleep(4)
        snapshot("04Card")
    }
}
