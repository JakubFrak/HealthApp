//
//  PomiarView_Tests.swift
//  CardioGoTests
//
//  Created by Jakub Frąk on 16/01/2024.
//

import XCTest
@testable import CardioGo

final class PomiarViewModel_Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ConvertBloodPressure() throws {
        let data = [Tetno(diastolic_pressure: 100, pulse: 80, systolic_pressure: 90, time: Date())]
        
        let vm = PomiarViewModel()
        
        let convertedData = vm.convertBloodMeasurements(BPData: data)
        
        XCTAssertNotNil(convertedData.first)
        XCTAssertEqual(convertedData.first!.name, "Puls")
        XCTAssertEqual(convertedData.last!.name, "Ciśnienie skurczowe")
        XCTAssertEqual(convertedData.first!.data.first!.value, 80)
        XCTAssertEqual(convertedData.last!.data.first!.value, 90)
    }
    
    func test_formatDate() throws {
        let date = Date(timeIntervalSince1970: 0)
        let vm = PomiarViewModel()
        let convertedDate = vm.formatDate(dt: date)
        
        XCTAssertNotNil(convertedDate)
        XCTAssertEqual(convertedDate, "01.01.1970")
    }
    
    func test_emptyINRMeasurement() throws {
        let vm = PomiarViewModel()
        XCTAssertNotNil(vm.pomiarINR)
        XCTAssertEqual(vm.pomiarINR.value, 0)
    }
    
    func test_emptyBPMeasurement() throws {
        let vm = PomiarViewModel()
        XCTAssertNotNil(vm.pomiarTetno)
        XCTAssertEqual(vm.pomiarTetno.pulse, 0)
        XCTAssertEqual(vm.pomiarTetno.diastolic_pressure, 0)
        XCTAssertEqual(vm.pomiarTetno.systolic_pressure, 0)
    }
}
