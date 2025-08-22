//
//  Symptom.swift
//  HealthApp
//
//  Created by Jakub Frąk on 05/12/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Symptoms: Codable{
    @DocumentID var id: String?
    var day: Date
    var symptom_arr: [String]
}

extension Symptoms{
    static var empty: Symptoms{
        Symptoms(day: Date(), symptom_arr: [])
    }
}
