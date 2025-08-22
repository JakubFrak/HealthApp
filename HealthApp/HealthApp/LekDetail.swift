//
//  LekDetail.swift
//  HealthApp
//
//  Created by Jakub Frąk on 23/11/2023.
//

import SwiftUI
import UserNotifications

struct LekDetail: View {
    @StateObject var viewmodel = LekiViewModel()
    @EnvironmentObject var AuthViewModel: AuthenticationViewModel
    var lek: Lek
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.dismiss) var dismiss
    @State var postac_wartosc: postac
    @State var plans: [week_plan]
    @State var Unit: unit

    @State var unitToggle = false
    
    @State var notifiEnabled: Bool
    
    @State var notificationsPermissionsDisabled = false
    
    init(lek: Lek) {
        self.lek = lek
        _postac_wartosc = State(initialValue: lek.form)
        _plans = State(initialValue: fillDateTime())
        _Unit = State(initialValue: lek.unit)
        @AppStorage("NotificationsEnabled") var ne: Bool?
        _notifiEnabled = State(initialValue: ne ?? false)
        
        func fillDateTime() -> [week_plan]{
            var final: [week_plan] = Array()
            for plan in lek.plans{
                final.append(week_plan(dose: plan.dose, time: plan.time, days_of_week: plan.days_of_week, datetime: unformatDate(Stime: plan.time)))
            }
            return final
        }
        
        func unformatDate(Stime: String) -> Date{
            let dateFromatter = DateFormatter()
            dateFromatter.dateFormat = "HH:mm"
            let t = dateFromatter.date(from: Stime)

            var components = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: Date())
            let calendar = Calendar.current
            components.hour = calendar.component(.hour, from: t ?? Date())
            components.minute = calendar.component(.minute, from: t ?? Date())
            components.second = 0

            return Calendar(identifier: .gregorian).date(from: components) ?? Date()
        }
    }
    
    var body: some View {
        VStack{
            if(lek.name != "Warfin" && lek.name != "Sintrom"){
                Form{
                    Section{
                        TextField("Nazwa leku", text: $viewmodel.Name)
                        if(viewmodel.isNameEmpty){Text(viewmodel.conformMedNameEmptyPrompt)}
                        if(!viewmodel.isNameValid){Text(viewmodel.conformMedNamePrompt)}
                        Picker("Postać leku", selection: $postac_wartosc){
                            ForEach(postac.allCases){ option in
                                Text(String(describing: option))
                            }
                        }.disabled(AuthViewModel.PreviewMode).pickerStyle(.segmented)
                        Picker("Jednostka", selection: $Unit){
                            ForEach(unit.allCases){ option in
                                Text(String(describing: option))
                            }
                        }.disabled(AuthViewModel.PreviewMode).pickerStyle(.menu)
                    }
                    ForEach($plans, id: \.self) { $plan in
                        Section{
                            HStack{
                                Text("Przyjmuję")
                                Picker("", selection: $plan.dose){
                                    ForEach(Array(stride(from: 0.25, to: 10.00, by: 0.25)), id: \.self){index in
                                        Text("\(index, specifier: "%.2f")").tag(index)
                                    }
                                }.disabled(AuthViewModel.PreviewMode).pickerStyle(.wheel).clipped().frame(height: 120)
                                Text(Unit.rawValue)
                            }
                            Text("W następujące dni:")
                            if(self.dynamicTypeSize > DynamicTypeSize.xxLarge){
                                VStack{
                                    HStack{
                                        ForEach((1...4), id: \.self){i in
                                            if AuthViewModel.PreviewMode{
                                                ZStack{
                                                    Rectangle().frame(width: 40, height: 40).cornerRadius(5).foregroundColor(plan.days_of_week.contains(i) ? .blue : .gray)
                                                    Text(viewmodel.weekDayName(i: i))
                                                }
                                            }else{
                                                Button(viewmodel.weekDayName(i: i)){
                                                    if(plan.days_of_week.contains(i)){
                                                        plan.days_of_week.removeAll(where: {$0 == i})
                                                    }
                                                    else{
                                                        removeDayFromOtherPlans(day: i)
                                                        plan.days_of_week.append(i)
                                                    }
                                                }.if(plan.days_of_week.contains(i)){$0.buttonStyle(.borderedProminent)}
                                                    .if(!plan.days_of_week.contains(i)){$0.buttonStyle(.bordered)}
                                            }
                                        }
                                    }
                                    HStack{
                                        ForEach((5...7), id: \.self){i in
                                            if AuthViewModel.PreviewMode{
                                                ZStack{
                                                    Rectangle().frame(width: 40, height: 40).cornerRadius(5).foregroundColor(plan.days_of_week.contains(i) ? .blue : .gray)
                                                    Text(viewmodel.weekDayName(i: i))
                                                }
                                            }else{
                                                Button(viewmodel.weekDayName(i: i)){
                                                    if(plan.days_of_week.contains(i)){
                                                        plan.days_of_week.removeAll(where: {$0 == i})
                                                    }
                                                    else{
                                                        removeDayFromOtherPlans(day: i)
                                                        plan.days_of_week.append(i)
                                                    }
                                                }.if(plan.days_of_week.contains(i)){$0.buttonStyle(.borderedProminent)}
                                                    .if(!plan.days_of_week.contains(i)){$0.buttonStyle(.bordered)}
                                            }
                                        }
                                    }
                                }
                            }else{
                                HStack{
                                    ForEach((1...7), id: \.self){i in
                                        if AuthViewModel.PreviewMode{
                                            ZStack{
                                                Rectangle().frame(width: 40, height: 40).cornerRadius(5).foregroundColor(plan.days_of_week.contains(i) ? .blue : .gray)
                                                Text(viewmodel.weekDayName(i: i))
                                            }
                                        }else{
                                            Button(viewmodel.weekDayName(i: i)){
                                                if(plan.days_of_week.contains(i)){
                                                    plan.days_of_week.removeAll(where: {$0 == i})
                                                }
                                                else{
                                                    removeDayFromOtherPlans(day: i)
                                                    plan.days_of_week.append(i)
                                                }
                                            }.if(plan.days_of_week.contains(i)){$0.buttonStyle(.borderedProminent)}
                                                .if(!plan.days_of_week.contains(i)){$0.buttonStyle(.bordered)}
                                        }
                                    }
                                }
                            }
                            if !AuthViewModel.PreviewMode{
                                if(plans.count > 1){
                                    Button(role: .destructive){
                                        withAnimation(.easeInOut){
                                            plans.removeAll(where: {$0.hashValue == plan.hashValue})
                                        }
                                    }label: {
                                        Text("Usuń ten harmonogram").frame(maxWidth: .infinity)
                                    }.buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                    if !AuthViewModel.PreviewMode{
                        Button("Dodaj Harmonogram"){
                            withAnimation(.easeInOut){
                                plans.append(week_plan(dose: 0.25, time: "00:00", days_of_week: [], datetime: Date()))
                            }
                        }.disabled(plans.count >= 7)
                    }
                }
                if !AuthViewModel.PreviewMode{
                    Button{saveOtherMed()}label: {
                        Text("Zapisz zmiany").frame(maxWidth: .infinity)
                    }.disabled(viewmodel.Name.isEmpty).buttonStyle(.borderedProminent)
                }
            }else{
                Form{
                    Section{
                        Text(viewmodel.Name)
                        Text("Tabletka")
                    }
                    if !AuthViewModel.PreviewMode{
                        HStack{
                            Text("Powiadomienia: ")
                            Button{
                                if(notifiEnabled){
                                    disableNotifications()
                                }else{
                                    askForNotifications()
                                }
                            } label: {
                                if(notifiEnabled){
                                    Text("Wyłącz powiaomienia").frame(maxWidth: .infinity)
                                }else{
                                    Text("Włącz powiadomienia").frame(maxWidth: .infinity)
                                }
                            }.buttonStyle(.borderedProminent).tint(notifiEnabled ? .green : .blue)
                        }
                        if(notificationsPermissionsDisabled){
                            Text("Brak uprawnień do wysyłania powiadomień! Włącz je w ustawieniach iPhone: Ustawienia -> CardioGo -> Powiadomienia")
                        }
                    }
//                    Button("Check"){
//                        checkNotifications()
//                    }
                    ForEach($plans, id: \.self) { $plan in
                        Section{
                            HStack{
                                Text("Przyjmuję")
                                Picker("", selection: $plan.dose){
                                    ForEach(Array(stride(from: 0.25, to: 10.00, by: 0.25)), id: \.self){index in
                                        Text("\(index, specifier: "%.2f")").tag(index)
                                    }
                                }.disabled(AuthViewModel.PreviewMode).pickerStyle(.wheel).clipped().frame(height: 120)
                                Text("mg")
                            }
                            Text("W następujące dni")
                            if(self.dynamicTypeSize > DynamicTypeSize.xxLarge){
                                VStack{
                                    HStack{
                                        ForEach((1...4), id: \.self){i in
                                            if AuthViewModel.PreviewMode{
                                                ZStack{
                                                    Rectangle().frame(width: 40, height: 40).cornerRadius(5).foregroundColor(plan.days_of_week.contains(i) ? .blue : .gray)
                                                    Text(viewmodel.weekDayName(i: i))
                                                }
                                            }else{
                                                Button(viewmodel.weekDayName(i: i)){
                                                    if(plan.days_of_week.contains(i)){
                                                        plan.days_of_week.removeAll(where: {$0 == i})
                                                    }
                                                    else{
                                                        removeDayFromOtherPlans(day: i)
                                                        plan.days_of_week.append(i)
                                                    }
                                                }.if(plan.days_of_week.contains(i)){$0.buttonStyle(.borderedProminent)}
                                                    .if(!plan.days_of_week.contains(i)){$0.buttonStyle(.bordered)}
                                            }
                                        }
                                    }
                                    HStack{
                                        ForEach((5...7), id: \.self){i in
                                            if AuthViewModel.PreviewMode{
                                                ZStack{
                                                    Rectangle().frame(width: 40, height: 40).cornerRadius(5).foregroundColor(plan.days_of_week.contains(i) ? .blue : .gray)
                                                    Text(viewmodel.weekDayName(i: i))
                                                }
                                            }else{
                                                Button(viewmodel.weekDayName(i: i)){
                                                    if(plan.days_of_week.contains(i)){
                                                        plan.days_of_week.removeAll(where: {$0 == i})
                                                    }
                                                    else{
                                                        removeDayFromOtherPlans(day: i)
                                                        plan.days_of_week.append(i)
                                                    }
                                                }.if(plan.days_of_week.contains(i)){$0.buttonStyle(.borderedProminent)}
                                                    .if(!plan.days_of_week.contains(i)){$0.buttonStyle(.bordered)}
                                            }
                                        }
                                    }
                                }
                            }else{
                                HStack{
                                    ForEach((1...7), id: \.self){i in
                                        if AuthViewModel.PreviewMode{
                                            ZStack{
                                                Rectangle().frame(width: 40, height: 40).cornerRadius(5).foregroundColor(plan.days_of_week.contains(i) ? .blue : .gray)
                                                Text(viewmodel.weekDayName(i: i))
                                            }
                                        }else{
                                            Button(viewmodel.weekDayName(i: i)){
                                                if(plan.days_of_week.contains(i)){
                                                    plan.days_of_week.removeAll(where: {$0 == i})
                                                }
                                                else{
                                                    removeDayFromOtherPlans(day: i)
                                                    plan.days_of_week.append(i)
                                                }
                                            }.if(plan.days_of_week.contains(i)){$0.buttonStyle(.borderedProminent)}
                                                .if(!plan.days_of_week.contains(i)){$0.buttonStyle(.bordered)}
                                        }
                                    }
                                }
                            }
                            if !AuthViewModel.PreviewMode{
                                if(notifiEnabled){
                                    DatePicker("Wybierz godzinę powiadomienia", selection: $plan.datetime, displayedComponents: .hourAndMinute)
                                }
                                if(plans.count > 1){
                                    Button(role: .destructive){
                                        withAnimation(.easeInOut){
                                            plans.removeAll(where: {$0.hashValue == plan.hashValue})
                                        }
                                    }label: {
                                        Text("Usuń ten harmonogram").frame(maxWidth: .infinity)
                                    }.buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                    if !AuthViewModel.PreviewMode{
                        Button("Dodaj Harmonogram"){
                            withAnimation(.easeInOut){
                                plans.append(week_plan(dose: 0.25, time: "17:30", days_of_week: [], datetime: Date()))
                            }
                        }.disabled(plans.count >= 7)
                    }
                }
                if !AuthViewModel.PreviewMode{
                    Button{saveMed()}label: {
                        Text("Zapisz zmiany").frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                }
            }
            Spacer()
        }.onAppear{
            viewmodel.Name = lek.name
            @AppStorage("NotificationsEnabled") var ne: Bool?
            notifiEnabled = ne ?? false
        }
        
    }
    func formatDate(dt: Date) -> String{
        let components = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: dt)
        return "\(components.hour ?? 17):\(components.minute ?? 30)"
    }
    func formatDate() -> [week_plan]{
        var final: [week_plan] = Array()
        for plan in plans{
            final.append(week_plan(dose: plan.dose, time: formatDate(dt: plan.datetime), days_of_week: plan.days_of_week, datetime: plan.datetime))
        }
        return final
    }
    
    func unitToggleText() -> unit{
        if unitToggle {return .ml}
        else {return .mg}
    }
    
    func saveMed(){
        let l = Lek(name: viewmodel.Name, form: postac_wartosc, plans: formatDate(), unit: unitToggleText())
        viewmodel.Lekk = l
        viewmodel.zapiszLek()
        //if(!viewmodel.Leki.contains(where: {$0.nazwa == l.nazwa})){viewmodel.Leki.append(l)}
        if(notifiEnabled){
            notifications()
        }
        dismiss()
    }
    func saveOtherMed(){
        let l = Lek(name: viewmodel.Name, form: postac_wartosc, plans: formatDate(), unit: unitToggleText())
        viewmodel.Lekk = l
        viewmodel.saveOtherMed()
        dismiss()
    }
    
    func askForNotifications(){
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings(completionHandler: {(settings) in
            if settings.authorizationStatus == .notDetermined{
                center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {(granted, error) in
                    if granted{
                        print("Notification permissions granted")
                        UserDefaults.standard.setValue(true, forKey: "NotificationsEnabled")
                        notifiEnabled = true
                        scheduleNotifications()
                    }else{
                        print("Notification permissions denied")
                        UserDefaults.standard.setValue(false, forKey: "NotificationsEnabled")
                        notifiEnabled = false
                    }
                })
            }else if settings.authorizationStatus == .denied{
                print("Go to settings reenable notifications")
                notifiEnabled = false
                notificationsPermissionsDisabled = true
            }else if settings.authorizationStatus == .authorized{
                print("Notification permissions granted before")
                UserDefaults.standard.setValue(true, forKey: "NotificationsEnabled")
                notifiEnabled = true
                scheduleNotifications()
            }
        })
    }
    
    func disableNotifications(){
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        UserDefaults.standard.setValue(false, forKey: "NotificationsEnabled")
        notifiEnabled = false
    }
    
    func notifications(){
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings(completionHandler: {(settings) in
            if settings.authorizationStatus == .notDetermined{
                center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {(granted, error) in
                    if granted{
                        print("Granted")
                        scheduleNotifications()
                    }else{
                        print("Denied")
                    }
                })
            }else if settings.authorizationStatus == .denied{
                print("Go to settings reenable notifications")
                notificationsPermissionsDisabled = true
            }else if settings.authorizationStatus == .authorized{
                scheduleNotifications()
            }
        })
    }
    
    func scheduleNotifications(){
        let center = UNUserNotificationCenter.current()
        
        center.removeAllPendingNotificationRequests()
        for plan in plans{
            let content = UNMutableNotificationContent()
            
            content.title = "Przypomnienie o przyjęciu leku"
            content.body = "Dziś do przyjęcia masz \(plan.dose) \(Unit.rawValue) leku \(viewmodel.Name)"
            content.categoryIdentifier = "alarm"
            content.userInfo = ["Test":"Test"]
            content.sound = UNNotificationSound.default
            
            for d in plan.days_of_week{
                var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: plan.datetime)
                let weekday = viewmodel.weekdayINT(day: d)
                dateComponents.weekday = weekday
                dateComponents.second = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(viewmodel.Name)|\(weekday)|\(dateComponents.hour!):\(dateComponents.minute!)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
    
    func checkNotifications(){
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: {requests in
            if(requests.isEmpty){
                print("No notifications")
                return
            }
            for request in requests {
                print(request)
            }
        })
    }
    
    func removeDayFromOtherPlans(day: Int){
        $plans.forEach { $plan in
            plan.days_of_week.removeAll(where: {$0 == day})
        }
    }
}

struct LekDetail_Previews: PreviewProvider {
    static var previews: some View {
        LekDetail(lek: Lek.empty)
    }
}

extension View {
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> TupleView<(Self?, Content?)> {
        if conditional {
            return TupleView((nil, content(self)))
        } else {
            return TupleView((self, nil))
        }
    }
}
