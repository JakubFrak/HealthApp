//
//  Lek.swift
//  HealthApp
//
//  Created by Jakub Frąk on 21/11/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum postac: String, Codable, CaseIterable, Identifiable{
    case tabletka, plyn, inne
    var id: Self {self}
}
enum unit: String, Codable, CaseIterable, Identifiable{
    case mg, ml
    var id: Self {self}
}

struct week_plan: Codable, Hashable{
    var dose: Double
    var time: String
    var days_of_week: [Int]
    var datetime: Date = Date()
    
    enum CodingKeys: String, CodingKey{
        case dose
        case time
        case days_of_week
    }
}

struct Lek: Codable, Identifiable, Hashable{
    @DocumentID var id: String?
    var name: String
    var form: postac
    var plans: [week_plan]
    var unit: unit
}

extension Lek{
    static var empty: Lek{
        Lek(name: "", form: postac.tabletka, plans: [], unit: .mg)
    }
}

