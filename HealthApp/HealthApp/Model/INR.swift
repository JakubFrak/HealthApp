//
//  INR.swift
//  HealthApp
//
//  Created by Jakub Frąk on 24/10/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct INR: Codable, Identifiable{
    @DocumentID var id: String?
    var value: Double
    var date: Date
}

extension INR {
    static var empty: INR{
        INR(value: 0.0, date: Date())
    }
}
