//
//  DietViewModel.swift
//  CardioGo
//
//  Created by Jakub Frąk on 29/12/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class DietViewModel: ObservableObject{
    @Published var intakesToday: Intakes = Intakes.empty
    private var intakesLastDoc: QueryDocumentSnapshot?
    
    @Published var intakesTodayOtherUser: Intakes = Intakes.empty
    private var intakesLastDocOtherUser: QueryDocumentSnapshot?
    
    @Published var intakesPaginated: [Intakes] = Array()
    @Published var intakesPaginatedOtherUser: [Intakes] = Array()
    
    @Published private var user: User?
    private var db = Firestore.firestore().collection("Users")
    
    init() {
        registerAuthStateHandler()
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                if user?.uid != nil {
                    self.db = Firestore.firestore().collection("Users")
                    self.getIntakes()
                }
            }
        }
    }
    
    func getIntakes(){
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("Intakes").order(by: "day", descending: true).limit(to: 1).getDocuments()
                if !querySnapshot.isEmpty{
                    if let intake = try querySnapshot.documents.first?.data(as: Intakes.self){
                        if(Calendar.current.isDateInToday(intake.day)){
                            await MainActor.run{
                                self.intakesToday = intake
                            }
                        }else{
                            await MainActor.run{
                                self.intakesPaginated.append(intake)
                            }
                        }
                        self.intakesLastDoc = querySnapshot.documents.last!
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    func saveIntakes(){
        do{
            if (Calendar.current.isDateInToday(intakesToday.day) && intakesToday.id != nil) {
                try db.document(self.user!.uid).collection("Intakes").document(intakesToday.id!).setData(from: intakesToday)
//                self.intakesPaginated.removeAll(where: {$0.id == intakesToday.id})
            }else{
                let documentReference = try db.document(self.user!.uid).collection("Intakes").addDocument(from: intakesToday)
                intakesToday.id = documentReference.documentID
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteIntake(intake: String){
        if intakesToday.intake_arr.contains(where: {$0.name == intake}){
            if(intakesToday.intake_arr.count > 1){
                intakesToday.intake_arr.removeAll(where: {$0.name == intake})
                do{
                    try db.document(self.user!.uid).collection("Intakes").document(intakesToday.id!).setData(from: intakesToday)
                }
                catch{
                    print(error.localizedDescription)
                }
            }else{
                deleteIntakes(id: intakesToday.id!)
                intakesToday = Intakes.empty
            }
        }
    }
    
    func getMoreIntakes(){
        if(self.intakesLastDoc != nil){
            Task{
                do{
                    let querySnapshot = try await db.document(self.user!.uid).collection("Intakes").order(by: "day", descending: true).start(afterDocument: self.intakesLastDoc!).limit(to: 5).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let i = try doc.data(as: Intakes.self)
                            await MainActor.run{
                                self.intakesPaginated.append(i)
                            }
                            self.intakesLastDoc = querySnapshot.documents.last!
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func deleteIntakes(id: String){
        Task{
            do{
                try await db.document(self.user!.uid).collection("Intakes").document(id).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func getIntakesOtherUser(userId: String){
        Task{
            do{
                let querySnapshot = try await db.document(userId).collection("Intakes").order(by: "day", descending: true).limit(to: 1).getDocuments()
                if !querySnapshot.isEmpty{
                    if let intake = try querySnapshot.documents.first?.data(as: Intakes.self){
                        if(Calendar.current.isDateInToday(intake.day)){
                            await MainActor.run{
                                self.intakesTodayOtherUser = intake
                            }
                        }else{
                            await MainActor.run{
                                self.intakesPaginatedOtherUser.append(intake)
                            }
                        }
                        self.intakesLastDocOtherUser = querySnapshot.documents.last!
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func getMoreIntakesOtherUser(userId: String){
        if(self.intakesLastDocOtherUser != nil){
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("Intakes").order(by: "day", descending: true).start(afterDocument: self.intakesLastDocOtherUser!).limit(to: 5).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let i = try doc.data(as: Intakes.self)
                            await MainActor.run{
                                self.intakesPaginatedOtherUser.append(i)
                            }
                            self.intakesLastDocOtherUser = querySnapshot.documents.last!
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func convertIntakeRawValue(intake: String) -> String{
        switch intake{
        case "Green_vegetables":
            return "Warzywa Zielone"
        case "Caffeine":
            return "Kofeina"
        case "Nicotine":
            return "Nikotyna"
        case "Alcohol":
            return "Alkohol"
        case "Other":
            return "Inne"
        default:
            return intake
        }
    }
    func unitForIntake(intake: String) -> String{
        switch intake{
        case "Green_vegetables":
            return "µg"
        case "Caffeine", "Nicotine", "Alcohol":
            return "mg"
        default:
            return ""
        }
    }
    func symbolForInake(intake: String) -> String{
        switch intake{
        case "Green_vegetables": return "🥬"
        case "Caffeine": return "☕️"
        case "Nicotine": return "🚬"
        case "Alcohol": return "🍺"
        default: return ""
            
        }
    }
}
