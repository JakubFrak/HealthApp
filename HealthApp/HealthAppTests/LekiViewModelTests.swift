//
//  LekiViewModelTests.swift
//  CardioGoTests
//
//  Created by Jakub Frąk on 16/01/2024.
//

import XCTest
@testable import CardioGo

final class LekiViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_convertSymptomRawValue() throws{
        let symptom = "Headache"
        let vm = LekiViewModel()
        let convertedValue = vm.convertSymptomRawValue(sym: symptom)
        XCTAssertNotNil(convertedValue)
        XCTAssertEqual(convertedValue, "Ból Głowy")
        XCTAssertEqual(vm.convertSymptomRawValue(sym: "Test"), "Test")
    }
    
    func test_isTakenText() throws {
        let vm = LekiViewModel()
        XCTAssertEqual(vm.isTakenText(taken: true), "✔️")
        XCTAssertEqual(vm.isTakenText(taken: false), "Zapisz przyjęcie")
    }
    
    func test_weekdayINT() throws {
        let vm = LekiViewModel()
        for i in 1...6{
            XCTAssertEqual(vm.weekdayINT(day: i), i+1)
        }
        XCTAssertEqual(vm.weekdayINT(day: 7), 1)
    }
    
    func test_weekDayName() throws {
        let weekDays = ["P", "W", "Ś", "C", "P", "S", "N"]
        let vm = LekiViewModel()
        for i in 1...7{
            XCTAssertEqual(vm.weekDayName(i: i), weekDays[i-1])
        }
    }
}
