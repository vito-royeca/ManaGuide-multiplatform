//
//  ManaGuideUITests.swift
//  ManaGuideUITests
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import XCTest
import SimulatorStatusMagic

class ManaGuideUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        SDStatusBarManager.sharedInstance().enableOverrides()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testScreenshots() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.        
        app.tables.cells.buttons["See All"].tap()
        snapshot("01Sets")

        app.tabBars.buttons["Search"].tap()
        app.navigationBars["Search"].children(matching: .button).element.tap()
        snapshot("02Search")
        app.navigationBars["Search"].children(matching: .button).element.tap()

        app.tabBars.buttons["Account"].tap()
        app.navigationBars["Account"].buttons["Login"].tap()
        snapshot("03Account")
        app.navigationBars["Login"].buttons["Cancel"].tap()

        app.tabBars.buttons["More"].tap()
        snapshot("04More")
    }
    
}
