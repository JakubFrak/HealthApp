//
//  DietView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 09/12/2023.
//

import SwiftUI

enum DefaultIntake: String, Codable, CaseIterable, Identifiable{
    case Green_vegetables, Caffeine, Nicotine, Alcohol, Other
    var id: Self {self}
    
    var description: String{
        switch self{
        case .Green_vegetables: return "Warzywa Zielone"
        case .Caffeine: return "Kofeina"
        case .Nicotine: return "Nikotyna"
        case .Alcohol: return "Alkohol"
        case .Other: return "Inne używki"
        }
    }
    var symbol: String{
        switch self{
        case .Green_vegetables: return "🥬"
        case .Caffeine: return "☕️"
        case .Nicotine: return "🚬"
        case .Alcohol: return "🍺"
        case .Other: return "Inne"
        }
    }
}

struct DietView: View {
    @StateObject var viewmodel = DietViewModel()
    @EnvironmentObject var AuthViewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State var intake_presented = false
    @State var intakeList = false
    
    let columns = [GridItem(.adaptive(minimum: 80))]
    
    @GestureState var deletion = false
    @State private var selected: String? = nil
    
    @State var intakeDescription = ""
    
    var body: some View {
        ZStack{
            Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fit).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
            ScrollView{
                VStack{
                    VStack{
                        Text("Dzisiejsze spożycie:").font(.largeTitle).foregroundColor(.blue).padding()
                        if AuthViewModel.PreviewMode{
                            ForEach(viewmodel.intakesTodayOtherUser.intake_arr, id: \.name){ i in
                                ZStack{
                                    Rectangle().frame(height: 90).cornerRadius(10).foregroundColor(.cyan)
                                    VStack{
                                        Text("\(viewmodel.convertIntakeRawValue(intake: i.name)) \(viewmodel.symbolForInake(intake: i.name))").foregroundColor(.white).font(.title2)
                                        if(i.name != DefaultIntake.Other.rawValue){
                                            Text("\(String(i.amount))\(viewmodel.unitForIntake(intake: i.name))").foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }else{
                            ForEach(viewmodel.intakesToday.intake_arr, id: \.name){ i in
                                ZStack{
                                    if(self.selected == i.name){
                                        Rectangle().frame(maxWidth: .infinity, minHeight: 90, maxHeight: 200).cornerRadius(10).foregroundColor(deletion ? .red : .cyan).animation(.easeInOut, value: deletion)
                                    }else{
                                        Rectangle().frame(maxWidth: .infinity, minHeight: 90, maxHeight: 200).cornerRadius(10).foregroundColor(.cyan)
                                    }
                                    VStack{
                                        Text("\(viewmodel.convertIntakeRawValue(intake: i.name)) \(viewmodel.symbolForInake(intake: i.name))").foregroundColor(.white).font(.title2)
                                        if(i.name != DefaultIntake.Other.rawValue){
                                            Text("\(String(i.amount))\(viewmodel.unitForIntake(intake: i.name))").foregroundColor(.white)
                                        }
                                    }.frame(maxWidth: .infinity, minHeight: 90)
                                }.gesture(
                                    LongPressGesture().updating($deletion, body: {(currentstate, state, transaction) in
                                        self.selected = i.name
                                        state = currentstate
                                        transaction.animation = Animation.easeInOut
                                    }).onEnded{ _ in
                                        self.selected = nil
                                        withAnimation{
                                            viewmodel.deleteIntake(intake: i.name)
                                        }
                                    }
                                )
                            }
                        }
                        if !AuthViewModel.PreviewMode{
                            ZStack{
                                //Rectangle().frame(height: 90).cornerRadius(10).foregroundColor(.cyan)
                                HStack{
                                    Image(systemName: "plus.app.fill").resizable().frame(width: 30, height: 30).foregroundColor(.white)
                                    Text("Dodaj").multilineTextAlignment(.center).foregroundColor(.white).font(.title2).padding(.leading, 10)
                                }.frame(maxWidth: .infinity, minHeight: 80)
                                
                            }.background(.cyan).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)).onTapGesture{
                                intake_presented.toggle()
                            }.sheet(isPresented: $intake_presented, onDismiss: {
                                if(!viewmodel.intakesToday.intake_arr.isEmpty){
                                    viewmodel.saveIntakes()
                                }
                            }){
                                ScrollView{
                                    VStack{
                                        Text("Wybierz dzisiejsze spożycie").font(.title)
                                        LazyVGrid(columns: columns){
                                            ForEach(DefaultIntake.allCases){ i in
                                                ZStack{
                                                    Rectangle().frame(width: 60, height: 60).cornerRadius(10).foregroundColor(isIntakeChosen(intake: i.rawValue) ? .green : .cyan).animation(.easeInOut, value: isIntakeChosen(intake: i.rawValue))
                                                    Text(i.symbol).multilineTextAlignment(.center).foregroundColor(.white)
                                                }.onTapGesture {
                                                    toggleIntake(intake: i.rawValue)
                                                }
                                            }
                                        }
                                        ForEach($viewmodel.intakesToday.intake_arr, id: \.name){ $i in
                                            IntakeAmountView(intake: $i)
                                        }
                                        Button("Gotowe"){
                                            if(!viewmodel.intakesToday.intake_arr.isEmpty){
                                                viewmodel.saveIntakes()
                                            }
                                            intake_presented.toggle()
                                        }.buttonStyle(.borderedProminent)
                                    }.padding([.leading, .trailing, .top])
                                }
                                
                            }
                        }
                        
                        if(AuthViewModel.PreviewMode){
                            Button{
                                if(viewmodel.intakesPaginatedOtherUser.isEmpty){viewmodel.getMoreIntakesOtherUser(userId: AuthViewModel.PreviewUserID)}
                                intakeList.toggle()
                            } label: {
                                Text("Historia spożycia").frame(maxWidth: .infinity)
                            }.sheet(isPresented: $intakeList){
                                VStack{
                                    Text("Historia spożycia").font(.title).foregroundColor(.cyan)
                                    List{
                                        ForEach(viewmodel.intakesPaginatedOtherUser, id: \.day){intakes in
                                            Section(header: Text(formatDate(dt: intakes.day))){
                                                ForEach(intakes.intake_arr, id: \.name){ i in
                                                    Text("\(viewmodel.convertIntakeRawValue(intake: i.name)): \(i.amount) \(viewmodel.unitForIntake(intake: i.name))")
                                                }
                                            }
                                        }
                                    }
                                    Button{
                                        viewmodel.getMoreIntakesOtherUser(userId: AuthViewModel.PreviewUserID)
                                    } label: {
                                        Text("Pobierz więcej dni").frame(maxWidth: .infinity)
                                    }.buttonStyle(.borderedProminent)
                                }.padding()
                            }
                        }else{
                            Button{
                                if(viewmodel.intakesPaginated.isEmpty){viewmodel.getMoreIntakes()}
                                intakeList.toggle()
                            } label: {
                                Text("Historia spożycia").frame(maxWidth: .infinity)
                            }.sheet(isPresented: $intakeList){
                                VStack{
                                    Text("Historia spożycia").font(.title).foregroundColor(.cyan)
                                    List{
                                        ForEach(viewmodel.intakesPaginated, id: \.day){intakes in
                                            Section(header: Text(formatDate(dt: intakes.day))){
                                                ForEach(intakes.intake_arr, id: \.name){ i in
                                                    Text("\(viewmodel.convertIntakeRawValue(intake: i.name)): \(i.amount) \(viewmodel.unitForIntake(intake: i.name))")
                                                }
                                                Button(role: .destructive){
                                                    viewmodel.deleteIntakes(id: intakes.id!)
                                                    withAnimation(.easeOut){
                                                        viewmodel.intakesPaginated.removeAll(where: {$0.id == intakes.id})
                                                    }
                                                } label: {
                                                    Text("Usuń").frame(maxWidth: .infinity)
                                                }.buttonStyle(.bordered).tint(.red)
                                            }
                                        }
                                    }
                                    Button{
                                        viewmodel.getMoreIntakes()
                                    } label: {
                                        Text("Pobierz więcej dni").frame(maxWidth: .infinity)
                                    }.buttonStyle(.bordered)
                                    Button{
                                        intakeList.toggle()
                                    } label: {
                                        Text("Gotowe").frame(maxWidth: .infinity)
                                    }.buttonStyle(.borderedProminent)
                                }.padding()
                            }
                        }
                        
                        Spacer()
                    }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                }.padding().onAppear{
                    if AuthViewModel.PreviewMode{
                        viewmodel.getIntakesOtherUser(userId: AuthViewModel.PreviewUserID)
                    }
                }
            }
        }
    }
    
    func isIntakeChosen(intake: String) -> Bool{
        if(viewmodel.intakesToday.intake_arr.contains(where: {$0.name == intake})){
            return true
        }
        return false
    }
    
    func toggleIntake(intake: String, amnt: Int = 0){
        if(isIntakeChosen(intake: intake)){
            withAnimation(.easeInOut){
                viewmodel.intakesToday.intake_arr.removeAll(where: {$0.name == intake})
            }
        }else{
            withAnimation(.easeIn){
                viewmodel.intakesToday.intake_arr.append(Intake(name: intake, amount: amnt))
            }
        }
    }
    
    func formatDate(dt: Date) -> String{
        let components = Calendar.current.dateComponents([.day, .month, .year], from: dt)
        return "\(components.day ?? 01).\(components.month ?? 01).\(components.year ?? 2000)"
    }
}

struct DietView_Previews: PreviewProvider {
    static var previews: some View {
        DietView()
    }
}
