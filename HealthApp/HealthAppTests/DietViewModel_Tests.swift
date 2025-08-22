//
//  DietViewModel_Tests.swift
//  CardioGoTests
//
//  Created by Jakub Frąk on 16/01/2024.
//

import XCTest
@testable import CardioGo

final class DietViewModel_Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_convertIntakeRawValue() throws {
        let vm = DietViewModel()
        XCTAssertEqual(vm.convertIntakeRawValue(intake: "Green_vegetables"), "Warzywa Zielone")
        XCTAssertEqual(vm.convertIntakeRawValue(intake: "Caffeine"), "Kofeina")
    }
    
    func test_unitForIntake() throws {
        let vm = DietViewModel()
        XCTAssertEqual(vm.unitForIntake(intake: "Green_vegetables"), "µg")
        XCTAssertEqual(vm.unitForIntake(intake: "Caffeine"), "mg")
    }
    
    func test_symbolForInake() throws {
        let vm = DietViewModel()
        XCTAssertEqual(vm.symbolForInake(intake: "Green_vegetables"), "🥬")
        XCTAssertEqual(vm.symbolForInake(intake: "Caffeine"), "☕️")
    }
}
