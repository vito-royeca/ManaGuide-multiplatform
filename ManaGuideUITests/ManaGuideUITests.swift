//
//  ManaGuideUITests.swift
//  ManaGuideUITests
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import XCTest

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
        
        let tabBarsQuery = app.tabBars

        sleep(10)
        snapshot("01Features")

        app.tables/*@START_MENU_TOKEN@*/.cells.buttons["See All >"]/*[[".cells.buttons[\"See All >\"]",".buttons[\"See All >\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.tap()
        sleep(2)
        snapshot("02Sets")

        tabBarsQuery.buttons["More"].tap()
        snapshot("05More")
        
        tabBarsQuery.buttons["Search"].tap()
        let keywordSearchField = app.searchFields["Keyword"]
        keywordSearchField.tap()
        keywordSearchField.typeText("Lotus")
        sleep(10)
        snapshot("03Search")
        app.tables.cells.containing(.staticText, identifier:"").staticTexts["Artifact"].tap()
        sleep(20)
        snapshot("04Card")
    }
    
}
