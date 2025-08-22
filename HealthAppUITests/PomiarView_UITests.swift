//
//  PomiarView_UITests.swift
//  CardioGoUITests
//
//  Created by Jakub Frąk on 17/01/2024.
//

import XCTest
@testable import CardioGo

final class PomiarView_UITests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
    }

    override func tearDownWithError() throws {
        
    }

    func test_addINR() throws {
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.buttons["Dodaj pomiar INR"].tap()
        app.textFields["0.00"].tap()
        app/*@START_MENU_TOKEN@*/.keys["3"]/*[[".keyboards.keys[\"3\"]",".keys[\"3\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.buttons["Zapisz"].tap()
        XCTAssert(XCUIApplication().scrollViews.otherElements/*@START_MENU_TOKEN@*/.staticTexts["todaysMeasurement"]/*[[".staticTexts[\"Dzisiejszy pomiar wynosi: 3,00\"]",".staticTexts[\"todaysMeasurement\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.waitForExistence(timeout: 5))
        XCTAssertEqual(XCUIApplication().scrollViews.otherElements/*@START_MENU_TOKEN@*/.staticTexts["todaysMeasurement"]/*[[".staticTexts[\"Dzisiejszy pomiar wynosi: 3,00\"]",".staticTexts[\"todaysMeasurement\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.label, "Dzisiejszy pomiar wynosi: 3.00")
    }
}
