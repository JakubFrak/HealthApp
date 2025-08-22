//
//  LekiView_UITests.swift
//  CardioGoUITests
//
//  Created by Jakub Frąk on 17/01/2024.
//

import XCTest
@testable import CardioGo

final class LekiView_UITests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        
    }

    func test_checkTakingMedicine() throws {
        let app = XCUIApplication()
        app.tabBars["Pasek kart"].buttons["Zdrowie"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery/*@START_MENU_TOKEN@*/.buttons["checkTakingMed"]/*[[".buttons[\"Zapisz przyjęcie\"]",".buttons[\"checkTakingMed\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCTAssert(elementsQuery/*@START_MENU_TOKEN@*/.buttons["checkTakingMed"]/*[[".buttons[\"Zapisz przyjęcie\"]",".buttons[\"checkTakingMed\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.waitForExistence(timeout: 3))
        XCTAssertEqual(elementsQuery/*@START_MENU_TOKEN@*/.buttons["checkTakingMed"]/*[[".buttons[\"Zapisz przyjęcie\"]",".buttons[\"checkTakingMed\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.label, "✔️")
    }
}
