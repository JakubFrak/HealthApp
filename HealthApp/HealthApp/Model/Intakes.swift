//
//  Intake.swift
//  HealthApp
//
//  Created by Jakub Frąk on 09/12/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Intake: Codable{
    var name: String
    var amount: Int
}

struct Intakes: Codable{
    @DocumentID var id: String?
    var day: Date
    var intake_arr: [Intake]
}

extension Intakes{
    static var empty: Intakes{
        Intakes(day: Date(), intake_arr: [])
    }
}
