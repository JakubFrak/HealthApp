//
//  MedTakenDate.swift
//  HealthApp
//
//  Created by Jakub Frąk on 21/12/2023.
//

import Foundation

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct MedTakenDate: Codable{
    @DocumentID var id: String?
    var date: Date
    var isTaken: Bool
}

extension MedTakenDate{
    static var empty: MedTakenDate{
        MedTakenDate(date: Date(), isTaken: true)
    }
}
