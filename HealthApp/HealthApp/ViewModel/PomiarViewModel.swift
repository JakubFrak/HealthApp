//
//  PomiarViewModel.swift
//  HealthApp
//
//  Created by Jakub Frąk on 24/10/2023.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class PomiarViewModel: ObservableObject {
    @Published var INRText: String = ""
    @Published var d_pressure: String = ""
    @Published var pulse: String = ""
    @Published var s_pressure: String = ""
    
    @Published var isINRValid = false
    @Published var isPulseValid = false
    @Published var isDPressureValid = false
    @Published var isSPressureValid = false
    @Published var canSubmitBP = false
    private var cancellables: Set<AnyCancellable> = []
    
    let doublePredicate = NSPredicate(format: "SELF MATCHES %@", "^[0-9]+\\.[0-9]{1,2}$|^[0-9]{1,3}$")
    
    @Published var pomiarINR = INR.empty
    @Published var pomiaryINR: Array<INR> = Array()
    @Published var INRPaginated: Array<INR> = Array()
    private var INRLastDoc: QueryDocumentSnapshot?
    
    @Published var MeasurementINRmonth: Array<INR> = Array()
    @Published var MeasurementINRmonth3: Array<INR> = Array()
    
    //@Published var MeasurementINRyear: Array<INR> = Array()
    
    @Published var MeasurementBPweek: Array<Tetno> = Array()
    @Published var MeasurementBPmonth: Array<Tetno> = Array()
    @Published var MeasurementBPmonthAvg: Array<Tetno> = Array()
    
//    @Published var MeasurementBPmonth6: Array<Tetno> = Array()
//    @Published var MeasurementBPyear: Array<Tetno> = Array()
    
    @Published var pomiarTetno = Tetno.empty
    @Published var pomiaryTetno: Array<Tetno> = Array()
    @Published var BPPaginated: Array<Tetno> = Array()
    private var BPLastDoc: QueryDocumentSnapshot?
    
    private var bpMeasTest = Tetno.empty
    
    @Published private var user: User?
    private var db = Firestore.firestore().collection("Users")
    
    @Published var INRMeasurementsOtherUser: Array<INR> = Array()
    @Published var MeasurementINRmonthOtherUser: Array<INR> = Array()
    @Published var MeasurementINRmonth3OtherUser: Array<INR> = Array()
    @Published var MeasurementINRmonth6OtherUser: Array<INR> = Array()
    @Published var BPMeasurementsOtherUser: Array<Tetno> = Array()
    @Published var MeasurementBPweekOtherUser: Array<Tetno> = Array()
    @Published var MeasurementBPmonthOtherUser: Array<Tetno> = Array()
    @Published var MeasurementBPmonthAvgOtherUser: Array<Tetno> = Array()
    @Published var MeasurementBPmonth3OtherUser: Array<Tetno> = Array()
    @Published var MeasurementBPmonth3AvgOtherUser: Array<Tetno> = Array()
    
    @Published var INRMeasurementsToDisplay: Array<INR> = Array()
    
    init() {
        registerAuthStateHandler()
        
        $INRText.map{inr in
            return self.doublePredicate.evaluate(with: inr)
        }.assign(to: \.isINRValid, on: self).store(in: &cancellables)
        $pulse.map{p in
            return self.doublePredicate.evaluate(with: p)
        }.assign(to: \.isPulseValid, on: self).store(in: &cancellables)
        $d_pressure.map{dp in
            return self.doublePredicate.evaluate(with: dp)
        }.assign(to: \.isDPressureValid, on: self).store(in: &cancellables)
        $s_pressure.map{sp in
            return self.doublePredicate.evaluate(with: sp)
        }.assign(to: \.isSPressureValid, on: self).store(in: &cancellables)
        Publishers.CombineLatest3($isPulseValid, $isDPressureValid, $isSPressureValid).map{ isPulseValid, isDPressureValid, isSPressureValid in
            return (isPulseValid && isDPressureValid && isSPressureValid)
        }.assign(to: \.canSubmitBP, on: self).store(in: &cancellables)
      }
    
    var conformPulsePrompt: String{
        isPulseValid ? "" : "Pomiar powinien być zapisany w postaci 0.00"
    }
    var conformINRPrompt: String{
        isINRValid ? "" : "Pomiar powinien być zapisany w postaci 0.00"
    }
    var conformDPPrompt: String{
        isDPressureValid ? "" : "Pomiar powinien być zapisany w postaci 0.00"
    }
    var conformSPPrompt: String{
        isSPressureValid ? "" : "Pomiar powinien być zapisany w postaci 0.00"
    }
    var conformBPPrompt: String{
        canSubmitBP ? "" : "Jedna z wartości jest niepoprawnie zapisana"
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                if user != nil{
                    self.db = Firestore.firestore().collection("Users")
                    self.pobierzPomiarINR()
                    self.pobierzPomiaryINR()
                    self.pobierzPomiarTetno()
                    self.pobierzPomiaryTetno()
                }
            }
        }
    }
    
//    func testOtherUser(){
//        //F4QNgv6lTVQtNVcAo1eQU24GlwY2
//        Task{
//            do{
//                let querySnapshot = try await Firestore.firestore().collection("Users").document("F4QNgv6lTVQtNVcAo1eQU24GlwY2").collection("BloodPressureMeasurements").order(by: "time", descending: true).limit(to: 1).getDocuments()
//                if !querySnapshot.isEmpty {
//                    if let pomiar = try querySnapshot.documents.first?.data(as: Tetno.self) {
//                        await MainActor.run {
//                            print("Assigning value: \(pomiar.pulse), \(pomiar.diastolic_pressure), \(pomiar.systolic_pressure) to Test.")
//                            self.bpMeasTest = pomiar
//                        }
//                    }
//                }
//            }
//            catch{
//                print(error.localizedDescription)
//            }
//        }
//    }
    
    func pobierzPomiarINR(){
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("INRMeasurements").order(by: "date", descending: true).limit(to: 1).getDocuments()
                if !querySnapshot.isEmpty {
                    if let pomiar = try querySnapshot.documents.first?.data(as: INR.self) {
                        await MainActor.run {
                            //print("Assigning value: \(pomiar.value)")
                            self.pomiarINR = pomiar
                        }
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func pobierzPomiaryINR(){
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("INRMeasurements").order(by: "date", descending: true).limit(to: 5).getDocuments()
                if !querySnapshot.isEmpty {
                    await MainActor.run{
                        self.pomiaryINR.removeAll()
                        self.INRMeasurementsToDisplay.removeAll()
                    }
                    for doc in querySnapshot.documents{
                        let p = try doc.data(as: INR.self)
                        await MainActor.run{
                            self.pomiaryINR.append(p)
                            self.INRPaginated.append(p)
                            self.INRMeasurementsToDisplay.append(p)
                        }
                    }
                    self.INRLastDoc = querySnapshot.documents.last!
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func getMoreINR(){
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("INRMeasurements").order(by: "date", descending: true).start(afterDocument: self.INRLastDoc!).limit(to: 10).getDocuments()
                if !querySnapshot.isEmpty {
                    for doc in querySnapshot.documents{
                        let p = try doc.data(as: INR.self)
                        await MainActor.run{
                            self.INRPaginated.append(p)
                        }
                        self.INRLastDoc = querySnapshot.documents.last!
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func deleteINR(id: String){
        Task{
            do{
                try await db.document(self.user!.uid).collection("INRMeasurements").document(id).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func updateINR(){
        do{
            if let documentId = pomiarINR.id {
                try db.document(self.user!.uid).collection("INRMeasurements").document(documentId).setData(from: pomiarINR)
            }
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func zapiszPomiarINR(){
        let calendar = Calendar.current
        do{
            if(calendar.isDateInToday(pomiarINR.date)){//jesli data jest dzisiaj to edytuj dzisiejszy pomiar
                if let documentId = pomiarINR.id {
                    try db.document(self.user!.uid).collection("INRMeasurements").document(documentId).setData(from: pomiarINR)
                }else{
                    let documentReference = try db.document(self.user!.uid).collection("INRMeasurements").addDocument(from: pomiarINR)
                    print(pomiarINR)
                    pomiarINR.id = documentReference.documentID
                }
            }else{//jezeli nie to dodaj nowy
                var pomiar2 = INR.empty
                pomiar2.value = pomiarINR.value
                let documentReference = try db.document(self.user!.uid).collection("INRMeasurements").addDocument(from: pomiar2)
                pomiar2.id = documentReference.documentID
                pomiarINR = pomiar2
                print(pomiarINR)
            }
            
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func getMeasurementINRmonth(){
        if(self.MeasurementINRmonth.isEmpty){
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            Task{
                do{
                    let querySnapshot = try await db.document(self.user!.uid).collection("INRMeasurements").whereField("date", isGreaterThan: monthAgo).order(by: "date", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: INR.self)
                            await MainActor.run{
                                self.MeasurementINRmonth.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }else{
            print("Measurements from month ago already loaded.")
        }
    }
    func getMeasurementINRmonth3(){
        if(self.MeasurementINRmonth3.isEmpty){
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            let monthsAgo3 = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
            Task{
                for m in self.MeasurementINRmonth{
                    await MainActor.run{
                        self.MeasurementINRmonth3.append(m)
                    }
                }
                do{
                    let querySnapshot = try await db.document(self.user!.uid).collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgo3).whereField("date", isLessThan: monthAgo).order(by: "date", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: INR.self)
                            await MainActor.run{
                                self.MeasurementINRmonth3.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
                
            }
        }else{
            print("Measurements from 3 months ago already loaded.")
        }
    }
    func getMeasurementINRmonth6OtherUser(userId: String){
        if(self.MeasurementINRmonth6OtherUser.isEmpty){
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            let monthsAgo6 = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
            Task{
                for m in self.MeasurementINRmonthOtherUser{
                    await MainActor.run{
                        self.MeasurementINRmonth6OtherUser.append(m)
                    }
                }
                do{
                    let querySnapshot = try await db.document(userId).collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgo6).whereField("date", isLessThan: monthAgo).order(by: "date", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let m = try doc.data(as: INR.self)
                            await MainActor.run{
                                self.MeasurementINRmonth6OtherUser.append(m)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }else{
            print("Measurements from 6 months ago already loaded.")
        }
    }
    
//    func getMeasurementINRyear(){
//        if(self.MeasurementINRyear.isEmpty){
//            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
//            let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
//            Task{
//                for m in self.MeasurementINRmonth{
//                    await MainActor.run{
//                        self.MeasurementINRyear.append(m)
//                    }
//                }
//                do{
//                    let querySnapshot = try await db.document(self.user!.uid).collection("INRMeasurements").whereField("date", isGreaterThan: yearAgo).whereField("date", isLessThan: monthAgo).order(by: "date", descending: true).getDocuments()
//                    if !querySnapshot.isEmpty {
//                        for doc in querySnapshot.documents{
//                            let p = try doc.data(as: INR.self)
//                            await MainActor.run{
//                                self.MeasurementINRyear.append(p)
//                            }
//                        }
//                    }
//                }
//                catch{
//                    print(error.localizedDescription)
//                }
//            }
//        }else{
//            print("Measurements from year ago already loaded.")
//        }
//    }
    
//    func saveTestValuesBP(){
//        Task{
//            for i in 1...17{
//                let seconds = 2.0
//                do{
//                    try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
//                    let Measurement = Tetno(diastolic_pressure: Double(Int.random(in: 70..<100)), pulse: Double(Int.random(in: 50..<110)), systolic_pressure: Double(Int.random(in: 110..<150)), time: Calendar.current.date(byAdding: .day, value: -i, to: Date())!)
//                    print(Measurement)
//                    let documentReference = try db.document(self.user!.uid).collection("BloodPressureMeasurements").addDocument(from: Measurement)
//                }
//                catch {
//                    print(error.localizedDescription)
//                }
//            }
//        }
//    }
    func getMeasurementBPweek(){
        if(self.MeasurementBPweek.isEmpty){
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            Task{
                do{
                    let querySnapshot = try await db.document(self.user!.uid).collection("BloodPressureMeasurements").whereField("time", isGreaterThan: weekAgo).order(by: "time", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Tetno.self)
                            await MainActor.run{
                                self.MeasurementBPweek.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }else{
            print("Measurements from week ago already loaded.")
        }
    }
    func getMeasurementBPmonth(){
        if(self.MeasurementBPmonth.isEmpty){
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            Task{
                do{
                    let querySnapshot = try await db.document(self.user!.uid).collection("BloodPressureMeasurements").whereField("time", isGreaterThan: monthAgo).order(by: "time", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Tetno.self)
                            await MainActor.run{
                                self.MeasurementBPmonth.append(p)
                            }
                        }
                    }
                    if(!self.MeasurementBPmonth.isEmpty){
                        var sumPulse = 0.0
                        var sumDP = 0.0
                        var sumSP = 0.0
                        var j = 0
                        let latestDay = self.MeasurementBPmonth.first!.time
                        for i in 0...28{
                            let measurements = self.MeasurementBPmonth.filter{Calendar.current.isDate($0.time, inSameDayAs: Calendar.current.date(byAdding: .day, value: -i, to: latestDay)!)}
                            for m in measurements{
                                //print("sumPulse = \(sumPulse)+\(m.pulse)")
                                sumPulse += m.pulse
                                sumDP += m.diastolic_pressure
                                sumSP += m.systolic_pressure
                                j+=1
                            }
                            if(i%4 == 0){
                                //print("Puls = \(sumPulse)/\(j) = \(sumPulse/Double(j))")
                                let DPavg = sumDP/Double(j)
                                let PulseAvg = sumPulse/Double(j)
                                let SPavg = sumSP/Double(j)
                                if(sumDP != 0){
                                    await MainActor.run{
                                        self.MeasurementBPmonthAvg.append(Tetno(diastolic_pressure: DPavg, pulse: PulseAvg, systolic_pressure: SPavg, time: Calendar.current.date(byAdding: .day, value: -i, to: latestDay)!))
                                    }
                                }
                                sumPulse = 0
                                sumDP = 0
                                sumSP = 0
                                j = 0
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
                
            }
            
        }else{
            print("Measurements from month ago already loaded.")
        }
    }
    func getMeasurementBPmonth3(userId: String){
        if(self.MeasurementBPmonth3OtherUser.isEmpty){
            let month3Ago = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("BloodPressureMeasurements").whereField("time", isGreaterThan: month3Ago).order(by: "time", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Tetno.self)
                            await MainActor.run{
                                self.MeasurementBPmonth3OtherUser.append(p)
                            }
                        }
                    }
                    if(!self.MeasurementBPmonth3OtherUser.isEmpty){
                        var sumPulse = 0.0
                        var sumDP = 0.0
                        var sumSP = 0.0
                        var j = 0
                        let latestDay = self.MeasurementBPmonth3OtherUser.first!.time
                        for i in 0...84{
                            let measurements = self.MeasurementBPmonth3OtherUser.filter{Calendar.current.isDate($0.time, inSameDayAs: Calendar.current.date(byAdding: .day, value: -i, to: latestDay)!)}
                            for m in measurements{
                                //print("sumPulse = \(sumPulse)+\(m.pulse)")
                                sumPulse += m.pulse
                                sumDP += m.diastolic_pressure
                                sumSP += m.systolic_pressure
                                j+=1
                            }
                            if(i%12 == 0){
                                //print("Puls = \(sumPulse)/\(j) = \(sumPulse/Double(j))")
                                let DPavg = sumDP/Double(j)
                                let PulseAvg = sumPulse/Double(j)
                                let SPavg = sumSP/Double(j)
                                if(sumDP != 0){
                                    await MainActor.run{
                                        self.MeasurementBPmonth3AvgOtherUser.append(Tetno(diastolic_pressure: DPavg, pulse: PulseAvg, systolic_pressure: SPavg, time: Calendar.current.date(byAdding: .day, value: -i, to: latestDay)!))
                                    }
                                }
                                sumPulse = 0
                                sumDP = 0
                                sumSP = 0
                                j = 0
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
                
            }
            
        }else{
            print("Measurements from 3 months ago already loaded.")
        }
    }
    
//    func getMeasurementBPyear(){
//        if(self.MeasurementINRyear.isEmpty){
//            Task{
//                do{
//                    for i in 2...12{
//                        let monthsAgoLL = Calendar.current.date(byAdding: .month, value: -i, to: Date())!
//                        let monthsAgoUL = Calendar.current.date(byAdding: .month, value: -i+1, to: Date())!
//                        print("upper limit = \(monthsAgoUL), lower limit: \(monthsAgoLL)")
//                        let countQuerySnapshot01 = try await db.collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgoLL).whereField("date", isLessThan: monthsAgoUL).whereField("value", isLessThan: 1).order(by: "date", descending: true).count.getAggregation(source: .server)
//                        let countQuerySnapshot12 = try await db.collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgoLL).whereField("date", isLessThan: monthsAgoUL).whereField("value", isGreaterThan: 1).whereField("value", isLessThan: 2).order(by: "date", descending: true).count.getAggregation(source: .server)
//                        let countQuerySnapshot225 = try await db.collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgoLL).whereField("date", isLessThan: monthsAgoUL).whereField("value", isGreaterThan: 2).whereField("value", isLessThan: 2.5).order(by: "date", descending: true).count.getAggregation(source: .server)
//                        let countQuerySnapshot253 = try await db.collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgoLL).whereField("date", isLessThan: monthsAgoUL).whereField("value", isGreaterThan: 2.5).whereField("value", isLessThan: 3).order(by: "date", descending: true).count.getAggregation(source: .server)
//                        let countQuerySnapshot34 = try await db.collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgoLL).whereField("date", isLessThan: monthsAgoUL).whereField("value", isGreaterThan: 3).whereField("value", isLessThan: 4).order(by: "date", descending: true).count.getAggregation(source: .server)
//                        let countQuerySnapshot4 = try await db.collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgoLL).whereField("date", isLessThan: monthsAgoUL).whereField("value", isGreaterThan: 4).order(by: "date", descending: true).count.getAggregation(source: .server)
//                    }
//                }catch{
//                    print(error.localizedDescription)
//                }
//            }
//
//        }else{
//            print("Measurements from month ago already loaded.")
//        }
//    }
    
    func pobierzPomiarTetno(){

        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("BloodPressureMeasurements").order(by: "time", descending: true).limit(to: 1).getDocuments()
                if !querySnapshot.isEmpty {
                    if let pomiar = try querySnapshot.documents.first?.data(as: Tetno.self) {
                        await MainActor.run {
                            //print("Assigning value: \(pomiar.pulse), \(pomiar.diastolic_pressure), \(pomiar.systolic_pressure).")
                            self.pomiarTetno = pomiar
                        }
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func pobierzPomiaryTetno(){
        
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("BloodPressureMeasurements").order(by: "time", descending: true).limit(to: 5).getDocuments()
                if !querySnapshot.isEmpty {
                    await MainActor.run{
                        self.pomiaryTetno.removeAll()
                    }
                    for doc in querySnapshot.documents{
                        let p = try doc.data(as: Tetno.self)
                        await MainActor.run{
                            self.pomiaryTetno.append(p)
                            self.BPPaginated.append(p)
                        }
                    }
                    self.BPLastDoc = querySnapshot.documents.last!
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func getMoreBP(){
        Task{
            do{
                let querySnapshot = try await db.document(self.user!.uid).collection("BloodPressureMeasurements").order(by: "time", descending: true).start(afterDocument: self.BPLastDoc!).limit(to: 10).getDocuments()
                if !querySnapshot.isEmpty {
                    for doc in querySnapshot.documents{
                        let p = try doc.data(as: Tetno.self)
                        await MainActor.run{
                            self.BPPaginated.append(p)
                        }
                        self.BPLastDoc = querySnapshot.documents.last!
                    }
                }
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func deleteBP(id: String){
        Task{
            do{
                try await db.document(self.user!.uid).collection("BloodPressureMeasurements").document(id).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func updateBP(){
        do{
            if let documentId = pomiarTetno.id {
                try db.document(self.user!.uid).collection("BloodPressureMeasurements").document(documentId).setData(from: pomiarTetno)
            }
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func zapiszPomiarTetno(){
        do{
            if(pomiarTetno.time.timeIntervalSinceNow > -3600){//jesli pomiar był dodany mniej niż godzine temu to edytuj pomiar
                if let documentId = pomiarTetno.id {
                    try db.document(self.user!.uid).collection("BloodPressureMeasurements").document(documentId).setData(from: pomiarTetno)
                }else{
                    let documentReference = try db.document(self.user!.uid).collection("BloodPressureMeasurements").addDocument(from: pomiarTetno)
                    print(pomiarTetno)
                    pomiarTetno.id = documentReference.documentID
                }
            }else{//jezeli nie to dodaj nowy
                var pomiar2 = Tetno.empty
                pomiar2.pulse = pomiarTetno.pulse
                pomiar2.systolic_pressure = pomiarTetno.systolic_pressure
                pomiar2.diastolic_pressure = pomiarTetno.diastolic_pressure
                let documentReference = try db.document(self.user!.uid).collection("BloodPressureMeasurements").addDocument(from: pomiar2)
                pomiar2.id = documentReference.documentID
                pomiarTetno = pomiar2
                print(pomiarTetno)
            }
            
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func getINRMeasurementsOtherUser(userId: String){
        if(self.INRMeasurementsOtherUser.isEmpty){
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("INRMeasurements").order(by: "date", descending: true).limit(to: 5).getDocuments()
                    if !querySnapshot.isEmpty {
                        await MainActor.run{
                            self.INRMeasurementsOtherUser.removeAll()
                        }
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: INR.self)
                            await MainActor.run{
                                self.INRMeasurementsOtherUser.append(p)
                                //self.INRPaginated.append(p)
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
    func getMeasurementINRmonthOtherUser(userId: String){
        if(self.MeasurementINRmonthOtherUser.isEmpty){
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("INRMeasurements").whereField("date", isGreaterThan: monthAgo).order(by: "date", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: INR.self)
                            await MainActor.run{
                                self.MeasurementINRmonthOtherUser.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }else{
            print("Measurements from month ago already loaded.")
        }
    }
    func getMeasurementINRmonth3OtherUser(userId: String){
        if(self.MeasurementINRmonth3OtherUser.isEmpty){
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            let monthsAgo3 = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
            Task{
                for m in self.MeasurementINRmonthOtherUser{
                    await MainActor.run{
                        self.MeasurementINRmonth3OtherUser.append(m)
                    }
                }
                do{
                    let querySnapshot = try await db.document(userId).collection("INRMeasurements").whereField("date", isGreaterThan: monthsAgo3).whereField("date", isLessThan: monthAgo).order(by: "date", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: INR.self)
                            await MainActor.run{
                                self.MeasurementINRmonth3.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
                
            }
        }else{
            print("Measurements from 3 months ago already loaded.")
        }
    }
    func getMeasurementBPOtherUser(userId: String){
        if(self.BPMeasurementsOtherUser.isEmpty){
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("BloodPressureMeasurements").order(by: "time", descending: true).limit(to: 5).getDocuments()
                    if !querySnapshot.isEmpty {
                        await MainActor.run{
                            self.BPMeasurementsOtherUser.removeAll()
                        }
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Tetno.self)
                            await MainActor.run{
                                self.BPMeasurementsOtherUser.append(p)
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
    func getMeasurementBPweekOtherUser(userId: String){
        if(self.MeasurementBPweekOtherUser.isEmpty){
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("BloodPressureMeasurements").whereField("time", isGreaterThan: weekAgo).order(by: "time", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Tetno.self)
                            await MainActor.run{
                                self.MeasurementBPweekOtherUser.append(p)
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
            }
        }else{
            print("Measurements from week ago for other user already loaded.")
        }
    }
    func getMeasurementBPmonthOtherUser(userId: String){
        if(self.MeasurementBPmonthOtherUser.isEmpty){
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            Task{
                do{
                    let querySnapshot = try await db.document(userId).collection("BloodPressureMeasurements").whereField("time", isGreaterThan: monthAgo).order(by: "time", descending: true).getDocuments()
                    if !querySnapshot.isEmpty {
                        for doc in querySnapshot.documents{
                            let p = try doc.data(as: Tetno.self)
                            await MainActor.run{
                                self.MeasurementBPmonthOtherUser.append(p)
                            }
                        }
                    }
                    if(!self.MeasurementBPmonthOtherUser.isEmpty){
                        var sumPulse = 0.0
                        var sumDP = 0.0
                        var sumSP = 0.0
                        var j = 0
                        let latestDay = self.MeasurementBPmonthOtherUser.first!.time
                        for i in 0...28{
                            let measurements = self.MeasurementBPmonthOtherUser.filter{Calendar.current.isDate($0.time, inSameDayAs: Calendar.current.date(byAdding: .day, value: -i, to: latestDay)!)}
                            for m in measurements{
                                //print("sumPulse = \(sumPulse)+\(m.pulse)")
                                sumPulse += m.pulse
                                sumDP += m.diastolic_pressure
                                sumSP += m.systolic_pressure
                                j+=1
                            }
                            if(i%4 == 0){
                                //print("Puls = \(sumPulse)/\(j) = \(sumPulse/Double(j))")
                                let DPavg = sumDP/Double(j)
                                let PulseAvg = sumPulse/Double(j)
                                let SPavg = sumSP/Double(j)
                                await MainActor.run{
                                    self.MeasurementBPmonthAvgOtherUser.append(Tetno(diastolic_pressure: DPavg, pulse: PulseAvg, systolic_pressure: SPavg, time: Calendar.current.date(byAdding: .day, value: -i, to: latestDay)!))
                                }
                                sumPulse = 0
                                sumDP = 0
                                sumSP = 0
                                j = 0
                            }
                        }
                    }
                }
                catch{
                    print(error.localizedDescription)
                }
                
            }
            
        }else{
            print("Measurements from month ago for other user already loaded.")
        }
    }
    
    func convertBloodMeasurements(BPData: [Tetno]) -> [(name: String, data: [chartData])]{
        var pulsData: [chartData] = []
        var d_pData: [chartData] = []
        var s_dData: [chartData] = []
        for pomiar in BPData {
            pulsData.append(chartData(time: pomiar.time, value: pomiar.pulse))
            d_pData.append(chartData(time: pomiar.time, value: pomiar.diastolic_pressure))
            s_dData.append(chartData(time: pomiar.time, value: pomiar.systolic_pressure))
        }
        let final = [
            (name: "Puls", data: pulsData),
            (name: "Ciśnienie rozkurczowe", data: d_pData),
            (name: "Ciśnienie skurczowe", data: s_dData)
        ]
        return final
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
}
