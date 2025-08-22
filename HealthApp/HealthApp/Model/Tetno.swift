//
//  Tetno.swift
//  HealthApp
//
//  Created by Jakub Frąk on 14/11/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Tetno: Codable, Identifiable{
    @DocumentID var id: String?
    var diastolic_pressure: Double
    var pulse: Double
    var systolic_pressure: Double
    var time: Date
}

extension Tetno {
    static var empty: Tetno{
        Tetno(diastolic_pressure: 0, pulse: 0, systolic_pressure: 0, time: Date())
    }
}
