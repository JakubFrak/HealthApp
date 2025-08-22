//
//  LekiObjawy.swift
//  HealthApp
//
//  Created by Jakub Frąk on 14/11/2023.
//

import SwiftUI

enum Symptom: String, Codable, CaseIterable, Identifiable{
    case Headache, Bleeding, Bruises, Chest_Pain, Leg_Swelling, Palpitations, Dizzyness, Hot_Flush, Coughing
    var id: Self {self}
    
    var description: String{
        switch self{
        case .Headache: return "Ból głowy"
        case .Bleeding: return "Krwawienie z nieznanej przyczyny"
        case .Bruises: return "Siniaki z nieznanej przyczyny"
        case .Chest_Pain: return "Ból w klatce piersiowej"
        case .Leg_Swelling: return "Opuchlizna nóg"
        case .Palpitations: return "Kołatanie serca"
        case .Dizzyness: return "Zawroty głowy"
        case .Hot_Flush: return "Uderzenie gorąca"
        case .Coughing: return "Kaszel"
        }
    }
}

struct LekiView: View {
    @StateObject var viewmodel = LekiViewModel()
    @EnvironmentObject var AuthViewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @State var symptoms_presented = false
    @State var diff_symptom_alert = false
    @State var diff_symptom_TF: String = ""
    @State var calendarPrestented = false
    @State var diffMedSheet = false
    @State var symptomsList = false
    
    @State var medSelection: Medication = .Warfin
    let columns = [GridItem(.adaptive(minimum: 110, maximum: 150))]
    let columnsAccessability = [GridItem(.adaptive(minimum: 250, maximum: 300))]
    
    @GestureState var deletion = false
    @State private var selected: String? = nil
    
    var body: some View {
        NavigationStack{
            ZStack{
                Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fit).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
                ScrollView{
                    VStack{
                        VStack{
                            Text("Leki").font(.title)
                            if AuthViewModel.PreviewMode{
                                ForEach(viewmodel.MedsOtherUser, id: \.Med.name){ MedTak in
                                    if(MedTak.Med.name == AuthViewModel.medicationOtherUser.rawValue){
                                            //RoundedRectangle(cornerRadius: 10).frame(height: 90).foregroundColor(MedTak.isTaken ? .green : .blue)
                                            VStack{
                                                HStack{
                                                    Text(MedTak.Med.name).foregroundColor(.white).padding([.bottom], 5)
                                                    Spacer()
                                                    NavigationLink{
                                                        LekDetail(lek: MedTak.Med).environmentObject(AuthViewModel)
                                                    } label: {
                                                        Image(systemName: "info.square.fill").foregroundColor(.white)
                                                    }
                                                }.frame(maxWidth: .infinity)
                                            }.padding().background(MedTak.isTaken ? .green : .blue).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        Button("Kalendarz przyjęć leku"){
                                            calendarPrestented.toggle()
                                        }.sheet(isPresented: $calendarPrestented){
                                            CalendarView(interval: DateInterval(start: viewmodel.getLastMonth(), end: viewmodel.getEndOfMonth()), data: $viewmodel.medTakenCalendarOtherUser)
                                        }.onAppear{
                                            viewmodel.getDatesMedTakenOtherUser(Med: MedTak.Med, userId: AuthViewModel.PreviewUserID)
                                        }.buttonStyle(.bordered)
                                    }
                                }
                            }else{
                                ForEach(viewmodel.Leki, id: \.Med.name){ MedTak in
                                    if(MedTak.Med.name == AuthViewModel.medication.rawValue){
                                            VStack{
                                                HStack{
                                                    Text(MedTak.Med.name).foregroundColor(.white).padding([.bottom], 5)
                                                    Spacer()
                                                    NavigationLink{
                                                        LekDetail(lek: MedTak.Med).environmentObject(AuthViewModel)
                                                    } label: {
                                                        Image(systemName: "square.and.pencil").foregroundColor(.white)
                                                    }
                                                }.frame(maxWidth: .infinity)
                                                HStack{
                                                    Button(viewmodel.isTakenText(taken: MedTak.isTaken)){
                                                        toggleMed(Med: MedTak.Med)
                                                        viewmodel.changeMedArray(MT: MedTaken(Med: MedTak.Med, isTaken: !MedTak.isTaken))
                                                    }.buttonStyle(.bordered).foregroundColor(.white).accessibilityIdentifier("checkTakingMed")
                                                    Button{
                                                        calendarPrestented.toggle()
                                                    } label: {
                                                        Image(systemName: "calendar").foregroundColor(.white)
                                                    }.sheet(isPresented: $calendarPrestented){
                                                        CalendarView(interval: DateInterval(start: viewmodel.getLastMonth(), end: viewmodel.getEndOfMonth()), data: $viewmodel.medTakenCalendar)
                                                    }.onAppear{
                                                        viewmodel.getDatesMedTaken(Med: MedTak.Med)
                                                    }.buttonStyle(.bordered)
                                                }
                                            }.padding().background(MedTak.isTaken ? .green : .blue).animation(.easeInOut, value: MedTak.isTaken).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        
                                        Button("Zmień główny lek"){
                                            diffMedSheet.toggle()
                                        }.sheet(isPresented: $diffMedSheet, onDismiss: {
                                            medSelection = AuthViewModel.medication
                                        }){
                                            VStack{
                                                ForEach(viewmodel.Leki, id: \.Med.name){ MedTak2 in
                                                        //RoundedRectangle(cornerRadius: 10).frame(height: 90).foregroundColor(MedTak2.Med.nazwa == AuthViewModel.medication.rawValue ? .green : .blue).animation(.easeInOut, value: MedTak2.isTaken)
                                                        VStack{
                                                            HStack{
                                                                Text(MedTak2.Med.name).foregroundColor(.white).padding([.bottom], 5)
                                                                Spacer()
                                                            }.frame(maxWidth: .infinity)
                                                            Button("Wybierz"){
                                                                AuthViewModel.medication = Medication(rawValue: MedTak2.Med.name)!
                                                                AuthViewModel.updateUserDataField(field: "medication", value: MedTak2.Med.name)
                                                                viewmodel.medTakenCalendar.removeAll()
                                                            }.disabled(MedTak2.Med.name == AuthViewModel.medication.rawValue).buttonStyle(.bordered).foregroundColor(.white)
                                                        }.padding().background(MedTak2.Med.name == AuthViewModel.medication.rawValue ? .green : .blue).animation(.easeInOut, value: MedTak2.isTaken).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                }
                                                Spacer()
                                                HStack{
                                                    Text("Dodaj inny lek: ")
                                                    Picker("Główny lek", selection: $medSelection){
                                                        ForEach(Medication.allCases){m in
                                                            Text(m.rawValue).tag(m)
                                                        }
                                                    }
                                                }
                                                Button{
                                                    viewmodel.addMainMed(med: medSelection.rawValue)
                                                } label: {
                                                    Text("Dodaj \(medSelection.rawValue)").frame(maxWidth: .infinity)
                                                }.disabled(viewmodel.Leki.contains(where: {$0.Med.name == medSelection.rawValue})).buttonStyle(.borderedProminent)
                                                Button{
                                                    diffMedSheet.toggle()
                                                } label: {
                                                    Text("Gotowe").frame(maxWidth: .infinity)
                                                }.buttonStyle(.borderedProminent)
                                            }.padding()
                                        }.onAppear{
                                            medSelection = AuthViewModel.medication
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Text("Inne Leki").font(.title).frame(alignment: .leading)
                            if AuthViewModel.PreviewMode{
                                LazyVStack{
                                    ForEach(viewmodel.otherMedsOtherUser){med in
                                        ZStack{
                                            //Capsule().frame(height: 50).foregroundColor(.cyan)
                                            HStack{
                                                Text(med.name).foregroundColor(.white)
                                                NavigationLink(destination: LekDetail(lek: med), label: {
                                                    Image(systemName: "info.square.fill").foregroundColor(.white)
                                                })
                                                Spacer()
                                                Image(systemName: "trash.fill").foregroundColor(.red)
                                            }.frame(maxWidth: .infinity)
                                        }.padding().background(.cyan).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                            }else{
                                LazyVStack{
                                    ForEach(viewmodel.otherMeds){med in
                                        ZStack{
                                            //Capsule().frame(height: 50).foregroundColor(.cyan)
                                            HStack{
                                                Text(med.name).foregroundColor(.white)
                                                NavigationLink(destination: LekDetail(lek: med), label: {
                                                    Image(systemName: "square.and.pencil").foregroundColor(.white)
                                                })
                                                Spacer()
                                                Button{
                                                    withAnimation(.easeOut){
                                                        viewmodel.deleteOtherMed(med: med)
                                                    }
                                                } label: {
                                                    Image(systemName: "trash.fill").foregroundColor(.red)
                                                }
                                            }.frame(maxWidth: .infinity)
                                        }.padding().background(.cyan).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        
                                    }
                                }.onAppear{
                                    viewmodel.getOtherMeds()
                                }
                            }
                            if !AuthViewModel.PreviewMode{
                                NavigationLink(destination: LekDetail(lek: Lek.empty), label: {Text("Dodaj Lek")}).buttonBorderShape(.capsule)
                            }
                        }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                        
                        
                        VStack{
                            Text("Dzisiejsze symptomy:").padding(.bottom, 10)
                            if AuthViewModel.PreviewMode{
                                ForEach(viewmodel.SymptomsTodayOtherUser.symptom_arr, id: \.self){ s in
                                    ZStack{
                                        Rectangle().frame(width: 150, height: 150).cornerRadius(10).foregroundColor(.cyan)
                                        Text(viewmodel.convertSymptomRawValue(sym: s)).multilineTextAlignment(.center).foregroundColor(.white).frame(width: 130, height: 130)
                                    }
                                }
                            }else{
                                LazyVGrid(columns: self.dynamicTypeSize.isAccessibilitySize ? columnsAccessability : columns){
                                    ForEach(viewmodel.Symptoms_today.symptom_arr, id: \.self){ s in
                                        ZStack{
                                            if(self.dynamicTypeSize.isAccessibilitySize){
                                                if(self.selected == s){
                                                    Rectangle().frame(width: 300, height: 150).cornerRadius(10).foregroundColor(deletion ? .red : .cyan).animation(.easeInOut, value: deletion)
                                                }else{
                                                    Rectangle().frame(width: 300, height: 150).cornerRadius(10).foregroundColor(.cyan)
                                                }
                                                Text(viewmodel.convertSymptomRawValue(sym: s)).multilineTextAlignment(.center).foregroundColor(.white).frame(width: 280, height: 130)
                                            }else{
                                                if(self.selected == s){
                                                    Rectangle().frame(width: 150, height: 150).cornerRadius(10).foregroundColor(deletion ? .red : .cyan).animation(.easeInOut, value: deletion)
                                                }else{
                                                    Rectangle().frame(width: 150, height: 150).cornerRadius(10).foregroundColor(.cyan)
                                                }
                                                Text(viewmodel.convertSymptomRawValue(sym: s)).multilineTextAlignment(.center).foregroundColor(.white).frame(width: 130, height: 130)
                                            }
                                        }.gesture(
                                            LongPressGesture().updating($deletion, body: {(currentstate, state, transaction) in
                                                self.selected = s
                                                state = currentstate
                                                transaction.animation = Animation.easeInOut
                                            }).onEnded{ _ in
                                                self.selected = nil
                                                
                                                withAnimation{
                                                    viewmodel.deleteSymptom(Sym: s)
                                                }
                                            }
                                        )
                                    }
                                    ZStack{
                                        if(self.dynamicTypeSize.isAccessibilitySize){
                                            Rectangle().frame(width: 300, height: 150).cornerRadius(10).foregroundColor(.cyan)
                                            Text("➕ \nDodaj").multilineTextAlignment(.center).foregroundColor(.white).frame(width: 280, height: 130)
                                        }else{
                                            Rectangle().frame(width: 150, height: 150).cornerRadius(10).foregroundColor(.cyan)
                                            Text("➕ \nDodaj").multilineTextAlignment(.center).foregroundColor(.white).frame(width: 130, height: 130)
                                        }
                                        
                                    }.onTapGesture {
                                        symptoms_presented.toggle()
                                    }.sheet(isPresented: $symptoms_presented, onDismiss: {
                                        if(!viewmodel.Symptoms_today.symptom_arr.isEmpty){
                                            viewmodel.saveSymptoms()
                                        }
                                    }){
                                        ScrollView{
                                            Text("Wybierz objawy").font(.title)
                                            LazyVGrid(columns: self.dynamicTypeSize.isAccessibilitySize ? columnsAccessability : columns){
                                                ForEach(Symptom.allCases){ s in
                                                    ZStack{
                                                        if(self.dynamicTypeSize.isAccessibilitySize){
                                                            Rectangle().frame(width: 300, height: 150).cornerRadius(10).foregroundColor(isSymptomChosen(Sym: s.rawValue) ? .green : .cyan).animation(.easeInOut, value: isSymptomChosen(Sym: s.rawValue))
                                                            Text(s.description).multilineTextAlignment(.center).foregroundColor(.white).frame(width: 280, height: 130)
                                                        }else{
                                                            Rectangle().frame(width: 120, height: 120).cornerRadius(10).foregroundColor(isSymptomChosen(Sym: s.rawValue) ? .green : .cyan).animation(.easeInOut, value: isSymptomChosen(Sym: s.rawValue))
                                                            Text(s.description).multilineTextAlignment(.center).foregroundColor(.white).frame(width: 110, height: 110)
                                                        }
                                                    }.onTapGesture {
                                                        toggleSymptom(Sym: s.rawValue)
                                                    }
                                                }
                                                ZStack{
                                                    if(self.dynamicTypeSize.isAccessibilitySize){
                                                        Rectangle().frame(width: 300, height: 150).cornerRadius(10).foregroundColor(.cyan)
                                                        Text("Inny").foregroundColor(.white).frame(width: 280, height: 120)
                                                    }else{
                                                        Rectangle().frame(width: 120, height: 120).cornerRadius(10).foregroundColor(.cyan)
                                                        Text("Inny").foregroundColor(.white).frame(width: 110, height: 110)
                                                    }
                                                }.onTapGesture {
                                                    diff_symptom_alert.toggle()
                                                }.sheet(isPresented: $diff_symptom_alert, onDismiss: {diff_symptom_TF = ""}){
                                                    VStack{
                                                        TextField("Wpisz nazwę", text: $diff_symptom_TF).textFieldStyle(TFTextStyle())
                                                        if(diff_symptom_TF.isEmpty){
                                                            Text("Pole nie może być puste")
                                                        }
                                                        Button{
                                                            toggleSymptom(Sym: diff_symptom_TF)
                                                            viewmodel.saveSymptoms()
                                                            diff_symptom_TF = ""
                                                            symptoms_presented.toggle()
                                                        } label: {
                                                            Text("Zapisz").frame(maxWidth: .infinity)
                                                        }.disabled(diff_symptom_TF.isEmpty).buttonStyle(.borderedProminent)
                                                        Button{
                                                            diff_symptom_TF = ""
                                                            diff_symptom_alert.toggle()
                                                        } label: {
                                                            Text("Anuluj").frame(maxWidth: .infinity)
                                                        }.buttonStyle(.bordered).tint(.red)
                                                    }.padding().presentationDetents([.medium])
                                                }
                                            }
                                            Button{
                                                if(!viewmodel.Symptoms_today.symptom_arr.isEmpty){
                                                    viewmodel.saveSymptoms()
                                                }
                                                symptoms_presented.toggle()
                                            }label: {
                                                Text("Gotowe").frame(maxWidth: .infinity)
                                            }.buttonStyle(.borderedProminent)
                                        }.padding()
                                    }
                                }
                            }
                            
                            if(AuthViewModel.PreviewMode){
                                Button{
                                    if(viewmodel.symptomsPaginatedOtherUser.isEmpty){viewmodel.getMoreSymptomsOtherUser(userId: AuthViewModel.PreviewUserID)}
                                    symptomsList.toggle()
                                } label: {
                                    Text("Historia objawów").frame(maxWidth: .infinity)
                                }.sheet(isPresented: $symptomsList){
                                    VStack{
                                        Text("Historia objawów").font(.title).foregroundColor(.cyan)
                                        List{
                                            ForEach(viewmodel.symptomsPaginatedOtherUser, id: \.day){symptoms in
                                                Section(header: Text(viewmodel.formatDate(dt: symptoms.day))){
                                                    ForEach(symptoms.symptom_arr, id: \.self){ s in
                                                        Text("\(viewmodel.convertSymptomRawValue(sym: s))")
                                                    }
                                                }
                                            }
                                        }
                                        Button{
                                            viewmodel.getMoreSymptomsOtherUser(userId: AuthViewModel.PreviewUserID)
                                        } label: {
                                            Text("Pobierz więcej dni").frame(maxWidth: .infinity)
                                        }.buttonStyle(.borderedProminent)
                                    }.padding()
                                }
                            }else{
                                Button{
                                    if(viewmodel.symptomsPaginated.isEmpty){viewmodel.getMoreSymptoms()}
                                    symptomsList.toggle()
                                } label: {
                                    Text("Historia objawów").frame(maxWidth: .infinity)
                                }.sheet(isPresented: $symptomsList){
                                    VStack{
                                        Text("Historia objawów").font(.title).foregroundColor(.cyan)
                                        List{
                                            ForEach(viewmodel.symptomsPaginated, id: \.day){symptoms in
                                                Section(header: Text(viewmodel.formatDate(dt: symptoms.day))){
                                                    ForEach(symptoms.symptom_arr, id: \.self){ s in
                                                        Text("\(viewmodel.convertSymptomRawValue(sym: s))")
                                                    }
                                                    Button(role: .destructive){
                                                        viewmodel.deleteSymptoms(id: symptoms.id!)
                                                        withAnimation(.easeOut){
                                                            viewmodel.symptomsPaginated.removeAll(where: {$0.id == symptoms.id})
                                                        }
                                                    } label: {
                                                        Text("Usuń").frame(maxWidth: .infinity)
                                                    }.buttonStyle(.bordered).tint(.red)
                                                }
                                            }
                                        }
                                        Button{
                                            viewmodel.getMoreSymptoms()
                                        } label: {
                                            Text("Pobierz więcej dni").frame(maxWidth: .infinity)
                                        }.buttonStyle(.bordered)
                                        Button{
                                            symptomsList.toggle()
                                        } label: {
                                            Text("Gotowe").frame(maxWidth: .infinity)
                                        }.buttonStyle(.borderedProminent)
                                    }.padding()
                                }
                            }
                        }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10).frame(maxWidth: .infinity)
                    }.padding()
                }.navigationTitle("Zdrowie").onAppear{
                    if AuthViewModel.PreviewMode{
                        viewmodel.getMedsOtherUser(userId: AuthViewModel.PreviewUserID)
                        viewmodel.getOtherMedsOtherUser(userId: AuthViewModel.PreviewUserID)
                        viewmodel.getSymptomsOtherUser(userId: AuthViewModel.PreviewUserID)
                    }else{
                        viewmodel.MedsOtherUser.removeAll()
                        viewmodel.otherMedsOtherUser.removeAll()
                        viewmodel.medTakenCalendarOtherUser.removeAll()
                    }
                }
            }
        }
    }
    
    func isSymptomChosen(Sym: String) -> Bool{
        if(viewmodel.Symptoms_today.symptom_arr.contains(Sym)){
            return true
        }
        return false
    }
    
    func toggleSymptom(Sym: String){
        if(isSymptomChosen(Sym: Sym)){
            viewmodel.Symptoms_today.symptom_arr.removeAll(where: {$0 == Sym})
        }else{
            viewmodel.Symptoms_today.symptom_arr.append(Sym)
        }
    }
    func toggleMed(Med: Lek){
        viewmodel.toggleTakingMedicine(Med: Med)
    }
    
}

struct LekiObjawy_Previews: PreviewProvider {
    static var previews: some View {
        LekiView()
    }
}
