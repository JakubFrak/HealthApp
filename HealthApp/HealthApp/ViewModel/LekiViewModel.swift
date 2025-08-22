//
//  LekiViewModel.swift
//  HealthApp
//
//  Created by Jakub Frąk on 20/11/2023.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

struct MedTaken{
    var Med: Lek
    var isTaken: Bool
}

class LekiViewModel: ObservableObject{
    @Published var Lekk: Lek = Lek.empty
    @Published var Leki: [MedTaken] = Array()
    @Published var otherMeds: Array<Lek> = Array()
    @Published var medTakenCalendar: Array<MedTakenDate> = Array()
    
    @Published var Symptoms_today: Symptoms = Symptoms.empty
    @Published var symptomsPaginated: [Symptoms] = Array()
    private var symptomsLastDoc: QueryDocumentSnapshot?
    @Published var symptomsPaginatedOtherUser: [Symptoms] = Array()
    private var symptomsLastDocOtherUser: QueryDocumentSnapshot?
    
    @Published var MedsOtherUser: [MedTaken] = Array()
    @Published var otherMedsOtherUser: Array<Lek> = Array()
    @Published var medTakenCalendarOtherUser: Array<MedTakenDate> = Array()
    @Published var SymptomsTodayOtherUser: Symptoms = Symptoms.empty
    
    @Published var Name = ""
    @Published var isNameValid = false
    @Published var isNameEmpty = false
    @Published var canSaveMed = false
    private var cancellables: Set<AnyCancellable> = []
    
    @Published private var user: User?
    private var db = Firestore.firestore().collection("Users")
    
    init() {
        registerAuthStateHandler()
        
        $Name.map{name in
            return name.isEmpty
        }.assign(to: \.isNameEmpty, on: self).store(in: &cancellables)
        
        $Name.map{name in
            return name != "Warfin" && name != "Sintrom"
        }.assign(to: \.isNameValid, on: self).store(in: &cancellables)
        Publishers.CombineLatest($isNameEmpty, $isNameValid).map{ isNameEmpty, isNameValid in
            return !isNameEmpty && isNameValid
        }.assign(to: \.canSaveMed, on: self).store(in: &cancellables)
    }
    
    var conformMedNamePrompt: String{
        isNameValid ? "" : "Nazwa nie może być taka sama jak jeden z głównych leków"
    }
    var conformMedNameEmptyPrompt: String{
        isNameEmpty ? "Nazwa nie może być pusta" : ""
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                if user?.uid != nil {
                    self.db = Firestore.firestore().collection("Users")
                    self.pobierzLeki()
                    self.getOtherMeds()
                    self.getSymptoms()
                }
            }
        }
    }
    
    func pobierzLeki(){
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("Medications").whereFilter(Filter.orFilter([Filter.whereField("name", isEqualTo: "Warfin"), Filter.whereField("name", isEqualTo: "Sintrom")])).getDocuments()
                if !querySnapshot.isEmpty {
                    await MainActor.run{
                        self.Leki.removeAll()
                    }
                    for doc in querySnapshot.documents{
                        let p = try doc.data(as: Lek.self)
                        let querySnapshot = try await db.document(self.user!.uid).collection("Medications").document(doc.documentID).collection("MedicineTaken").order(by: "date", descending: true).limit(to: 1).getDocuments()
                        let docRef = querySnapshot.documents.first!
                        let ts = docRef.get("date") as! Timestamp
                        let date = ts.dateValue()
                        let isTaken = docRef.get("isTaken") as? Bool ?? false
                        if(Calendar.current.isDateInToday(date)){
                            await MainActor.run{
                                self.Leki.append(MedTaken(Med: p, isTaken: isTaken))
                            }
                        }else{
                            await MainActor.run{
                                self.Leki.append(MedTaken(Med: p, isTaken: false))
                            }
                        }
                        
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func getOtherMeds(){
        if(self.user?.uid != nil){
            Task{
                do{
                    let querySnapshot = try await db.document(self.user!.uid).collection("Medications").whereField("name", notIn: ["Warfin", "Sintrom"]).getDocuments()
                    if !querySnapshot.isEmpty{
                        await MainActor.run{
                            self.otherMeds.removeAll()
                        }
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Lek.self)
                            await MainActor.run{
                                self.otherMeds.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func zapiszLek(){
        do{
            if let l = Leki.first(where: {$0.Med.name == Lekk.name}) {
                let lek = l.Med
                try db.document(self.user!.uid).collection("Medications").document(lek.id!).setData(from: Lekk)
            }else{
                let documentReference = try db.document(self.user!.uid).collection("Medications").addDocument(from: Lekk)
                Lekk.id = documentReference.documentID
                if(Lekk.name == "Warfin" || Lekk.name == "Sintrom"){
                    db.document(self.user!.uid).collection("Medications").document(documentReference.documentID).collection("MedicineTaken").addDocument(data: ["date" : Date(), "isTaken" : false])
                }
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func addMainMed(med: String){
        if(!self.Leki.contains(where: {$0.Med.name == med})){
            var Med = Lek(name: med, form: .tabletka, plans: [week_plan(dose: 0.25, time: "17:30", days_of_week: [1,2,3,4,5,6,7])], unit: .mg)
            do{
                let documentReference = try db.document(self.user!.uid).collection("Medications").addDocument(from: Med)
                Med.id = documentReference.documentID
                db.document(self.user!.uid).collection("Medications").document(documentReference.documentID).collection("MedicineTaken").addDocument(data: ["date" : Date(), "isTaken" : false])
            }catch {
                print(error.localizedDescription)
            }
            let MedID = Med
            Task{
                await MainActor.run{
                    self.Leki.append(MedTaken(Med: MedID, isTaken: false))
                }
            }
        }
    }
    
    func saveOtherMed(){
        do{
            if let l = otherMeds.first(where: {$0.name == Lekk.name}) {
                let lek = l
                try db.document(self.user!.uid).collection("Medications").document(lek.id!).setData(from: Lekk)
            }else{
                let documentReference = try db.document(self.user!.uid).collection("Medications").addDocument(from: Lekk)
                Lekk.id = documentReference.documentID
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteOtherMed(med: Lek){
        self.otherMeds.removeAll(where: {$0.name == med.name})
        Task{
            if let id = med.id{
                do{
                    try await db.document(self.user!.uid).collection("Medications").document(id).delete()
                }catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func toggleTakingMedicine(Med: Lek){
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("Medications").document(Med.id!).collection("MedicineTaken").order(by: "date", descending: true).limit(to: 1).getDocuments()
                if !querySnapshot.isEmpty {
                    let docRef = querySnapshot.documents.first!
                    let ts = docRef.get("date") as! Timestamp
                    let date = ts.dateValue()
                    let isTaken = docRef.get("isTaken") as! Bool
                    if(Calendar.current.isDateInToday(date)){
                        if(isTaken){
                            try await db.document(self.user!.uid).collection("Medications").document(Med.id!).collection("MedicineTaken").document(docRef.documentID).setData(["date": Date(), "isTaken" : false])
                        }else{
                            try await db.document(self.user!.uid).collection("Medications").document(Med.id!).collection("MedicineTaken").document(docRef.documentID).setData(["date": Date(), "isTaken" : true])
                        }
                    }
                    else{
                        try await db.document(self.user!.uid).collection("Medications").document(Med.id!).collection("MedicineTaken").addDocument(data: ["date" : Date(), "isTaken" : true])
                    }
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func getDatesMedTaken(Med: Lek){
        Task{
            if(medTakenCalendar.isEmpty){
                do{
                    let querySnapshot = try await db.document(self.user!.uid).collection("Medications").document(Med.id!).collection("MedicineTaken").whereField("date", isGreaterThan: getLastMonth()).order(by: "date", descending: true).getDocuments()
                    if !querySnapshot.isEmpty{
                        await MainActor.run{
                            self.medTakenCalendar.removeAll()
                        }
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: MedTakenDate.self)
                            await MainActor.run{
                                self.medTakenCalendar.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }else{
                print("calendar values already loaded")
            }
        }
    }
    
    func getSymptoms(){
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("Symptoms").order(by: "day", descending: true).limit(to: 1).getDocuments()
                if !querySnapshot.isEmpty{
                    if let sym = try querySnapshot.documents.first?.data(as: Symptoms.self){
                        if(Calendar.current.isDateInToday(sym.day)){
                            await MainActor.run{
                                self.Symptoms_today = sym
                            }
                        }else{
                            await MainActor.run{
                                self.symptomsPaginated.append(sym)
                            }
                        }
                        self.symptomsLastDoc = querySnapshot.documents.last!
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func saveSymptoms(){
        do{
            if (Calendar.current.isDateInToday(Symptoms_today.day) && Symptoms_today.id != nil) {
                try db.document(self.user!.uid).collection("Symptoms").document(Symptoms_today.id!).setData(from: Symptoms_today)
            }else{
                let documentReference = try db.document(self.user!.uid).collection("Symptoms").addDocument(from: Symptoms_today)
                Symptoms_today.id = documentReference.documentID
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteSymptom(Sym: String){
        if Symptoms_today.symptom_arr.contains(where: {$0 == Sym}){
            if(Symptoms_today.symptom_arr.count > 1){
                Symptoms_today.symptom_arr.removeAll(where: {$0 == Sym})
                do{
                    try db.document(self.user!.uid).collection("Symptoms").document(Symptoms_today.id!).setData(from: Symptoms_today)
                }
                catch{
                    print(error.localizedDescription)
                }
            }else{
                deleteSymptoms(id: Symptoms_today.id!)
                Symptoms_today = Symptoms.empty
            }
        }
    }
    
    func deleteSymptoms(id: String){
        Task{
            do{
                try await db.document(self.user!.uid).collection("Symptoms").document(id).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func getMoreSymptoms(){
        if(self.symptomsLastDoc != nil){
            Task{
                do{
                    let querySnapshot = try await db.document(self.user!.uid).collection("Symptoms").order(by: "day", descending: true).start(afterDocument: self.symptomsLastDoc!).limit(to: 5).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let sym = try doc.data(as: Symptoms.self)
                            await MainActor.run{
                                self.symptomsPaginated.append(sym)
                            }
                            self.symptomsLastDoc = querySnapshot.documents.last!
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func getMoreSymptomsOtherUser(userId: String){
        if(self.symptomsLastDocOtherUser != nil){
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("Symptoms").order(by: "day", descending: true).start(afterDocument: self.symptomsLastDocOtherUser!).limit(to: 5).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let sym = try doc.data(as: Symptoms.self)
                            await MainActor.run{
                                self.symptomsPaginatedOtherUser.append(sym)
                            }
                            self.symptomsLastDocOtherUser = querySnapshot.documents.last!
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func changeMedArray(MT: MedTaken){
        var newArr = Leki
        newArr.removeAll(where: {$0.Med.name == MT.Med.name})
        newArr.append(MT)
        Leki = newArr
        if(MT.isTaken){
            self.medTakenCalendar.removeAll(where: {Calendar.current.isDate($0.date, inSameDayAs: Date())})
            self.medTakenCalendar.append( MedTakenDate(date: Date(), isTaken: true) )
        }else{
            self.medTakenCalendar.removeAll(where: {Calendar.current.isDate($0.date, inSameDayAs: Date())})
            self.medTakenCalendar.append( MedTakenDate(date: Date(), isTaken: false) )
        }
    }
    
    func getBeginningOfMonth() -> Date{
        var cal = Calendar.current
        cal.timeZone = .gmt
        
        return cal.date(from: cal.dateComponents([.year, .month], from: cal.startOfDay(for: Date())))!
    }

    func getEndOfMonth() -> Date{
        var comps = DateComponents()
        comps.month = 1
        comps.day = -1
        return Calendar.current.date(byAdding: comps, to: getBeginningOfMonth())!
    }

    func getLastMonth() -> Date{
        return Calendar.current.date(byAdding: .month, value: -1, to: getBeginningOfMonth())!
    }
    
    func getMedsOtherUser(userId: String){
        if(self.MedsOtherUser.isEmpty){
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("Medications").whereFilter(Filter.orFilter([Filter.whereField("nazwa", isEqualTo: "Warfin"), Filter.whereField("nazwa", isEqualTo: "Sintrom")])).getDocuments()
                    if !querySnapshot.isEmpty {
                        await MainActor.run{
                            self.MedsOtherUser.removeAll()
                        }
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Lek.self)
                            let querySnapshot = try await db.document(userId).collection("Medications").document(doc.documentID).collection("MedicineTaken").order(by: "date", descending: true).limit(to: 1).getDocuments()
                            let docRef = querySnapshot.documents.first!
                            let ts = docRef.get("date") as! Timestamp
                            let date = ts.dateValue()
                            let isTaken = docRef.get("isTaken") as? Bool ?? false
                            if(Calendar.current.isDateInToday(date)){
                                await MainActor.run{
                                    self.MedsOtherUser.append(MedTaken(Med: p, isTaken: isTaken))
                                }
                            }else{
                                await MainActor.run{
                                    self.MedsOtherUser.append(MedTaken(Med: p, isTaken: false))
                                }
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    func getOtherMedsOtherUser(userId: String){
        if(self.otherMedsOtherUser.isEmpty){
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("Medications").whereField("nazwa", notIn: ["Warfin", "Sintrom"]).getDocuments()
                    if !querySnapshot.isEmpty{
                        await MainActor.run{
                            self.otherMedsOtherUser.removeAll()
                        }
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Lek.self)
                            await MainActor.run{
                                self.otherMedsOtherUser.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
    func getDatesMedTakenOtherUser(Med: Lek, userId: String){
        Task{
            if(medTakenCalendarOtherUser.isEmpty){
                do{
                    let querySnapshot = try await db.document(userId).collection("Medications").document(Med.id!).collection("MedicineTaken").whereField("date", isGreaterThan: getLastMonth()).order(by: "date", descending: true).getDocuments()
                    if !querySnapshot.isEmpty{
                        await MainActor.run{
                            self.medTakenCalendarOtherUser.removeAll()
                        }
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: MedTakenDate.self)
                            await MainActor.run{
                                self.medTakenCalendarOtherUser.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }else{
                print("calendar values already loaded")
            }
        }
    }
    func getSymptomsOtherUser(userId: String){
        Task{
            do{
                let querySnapshot = try await db.document(userId).collection("Symptoms").order(by: "day", descending: true).limit(to: 1).getDocuments()
                if !querySnapshot.isEmpty{
                    if let sym = try querySnapshot.documents.first?.data(as: Symptoms.self){
                        if(Calendar.current.isDateInToday(sym.day)){
                            await MainActor.run{
                                self.SymptomsTodayOtherUser = sym
                            }
                        }else{
                            await MainActor.run{
                                self.symptomsPaginatedOtherUser.append(sym)
                            }
                        }
                        self.symptomsLastDocOtherUser = querySnapshot.documents.last!
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func convertSymptomRawValue(sym: String) -> String{
        switch sym{
        case "Headache":
            return "Ból Głowy"
        case "Bleeding":
            return "Krwawienie z nieznanej przyczyny"
        case "Bruises":
            return "Siniaki z nieznanej przyczyny"
        case "Chest_Pain":
            return "Ból w klatce piersiowej"
        case "Leg_Swelling":
            return "Opuchlizna nóg"
        case "Palpitations":
            return "Kołatanie serca"
        case "Dizzyness":
            return "Zawroty głowy"
        case "Hot_Flush":
            return "Uderzenia gorąca"
        case "Coughing":
            return "Kaszel"
        default:
            return sym
        }
    }
    
    func formatDate(dt: Date) -> String{
        let components = Calendar.current.dateComponents([.day, .month, .year], from: dt)
        var day = "01"
        if(components.day ?? 1 < 10){
            day = "0\(components.day ?? 1)"
        }else{
            day = "\(components.day!)"
        }
        var month = "01"
        if(components.month ?? 1 < 10){
            month = "0\(components.month ?? 1)"
        }else{
            month = "\(components.month!)"
        }
        return "\(day).\(month).\(components.year ?? 2000)"
    }
    
    func isTakenText(taken: Bool) -> String{
        if taken{
            return "✔️"
        }
        return "Zapisz przyjęcie"
    }
    
    func weekDayName(i: Int) -> String{
        switch i{
        case 1:
            return "P"
        case 2:
            return "W"
        case 3:
            return "Ś"
        case 4:
            return "C"
        case 5:
            return "P"
        case 6:
            return "S"
        case 7:
            return "N"
        default:
            return "?"
        }
    }
    
    func weekdayINT(day: Int) -> Int{
        if(day>6){return 1}
        else {return day+1}
    }
}

//func formatDate(dt: Date) -> String{
//    let components = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: dt)
//    return "\(components.day ?? 01):\(components.month ?? 01):\(components.year ?? 2000)"
//}

func unformatDate(Stime: String) -> Date{
    let dateFromatter = DateFormatter()
    dateFromatter.dateFormat = "dd:MM:yyyy"
    let t = dateFromatter.date(from: Stime)

    var components = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: Date())
    let calendar = Calendar.current
    components.day = calendar.component(.day, from: t ?? Date())
    components.month = calendar.component(.month, from: t ?? Date())
    components.year = calendar.component(.year, from: t ?? Date())

    return Calendar(identifier: .gregorian).date(from: components) ?? Date()
}


