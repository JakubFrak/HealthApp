//
//  PomiarView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 07/10/2023.
//

import SwiftUI
import Charts

struct chartData: Identifiable{
    let id = UUID()
    let time: Date
    let value: Double
    
    init(time: Date, value: Double) {
        self.time = time
        self.value = value
    }
}

enum dateRange: CaseIterable, Identifiable{
    case week, month, months3, months6
    
    static let INRdateRange: [dateRange] = [.month, .months3]
    static let INRdateRangeDoc: [dateRange] = [.month, .months3, .months6]
    static let BPdateRangePatient: [dateRange] = [.week, .month]
    static let BPdateRangeDoc: [dateRange] = [.week, .month, .months3]
    
    var id: Self {self}
    var dsc: String{
        switch self{
        case .week: return "Tydzień"
        case .month: return "Miesiąc"
        case .months3: return "3 miesiące"
        case .months6: return "6 miesięcy"
        //case .months6: return "6 Miesięcy"
        //case .year: return "Rok"
        }
    }
}

struct PomiarView: View {
    @StateObject var viewModel = PomiarViewModel()
    @EnvironmentObject var AuthViewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @State var INRPresented = false
    @State var TetnoPresented = false
    @State var INRListSheet = false
    @State var BPListSheet = false
    let calendar = Calendar.current
    
    let date = Date()
    @State var refresh: Bool = false
    
    @State var INRDetails = false
    @State var BPDetails = false
    @State var dateRng: dateRange = .week
    
    var body: some View {
        ZStack{
            Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fit).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
            ScrollView{
                VStack{
                    if !AuthViewModel.PreviewMode{
                        Text(date, format: Date.FormatStyle().weekday(.wide).day().month())
                            .font(.largeTitle)
                    }
//                    Button("test"){
//                        viewModel.saveTestValuesBP()
//                    }
                    VStack{
                        Text("Ostatnie pomiary INR")
                        if AuthViewModel.PreviewMode{
                            INRChartView(data: viewModel.INRMeasurementsOtherUser).frame(height: self.dynamicTypeSize.isAccessibilitySize ? 300 : 150)
                                .onTapGesture {
                                    INRDetails.toggle()
                                }.sheet(isPresented: $INRDetails, onDismiss: {self.dateRng = .week}){
                                    VStack{
                                        Text("Pomiary INR").font(.title)
                                        Picker("Zakres", selection: $dateRng){
                                            ForEach(dateRange.INRdateRangeDoc){ rng in
                                                Text(rng.dsc).tag(rng)
                                            }
                                        }.pickerStyle(.segmented)
                                        switch self.dateRng{
                                        case .month:
                                            INRChartView(data: viewModel.MeasurementINRmonthOtherUser)
                                                .onAppear{viewModel.getMeasurementINRmonthOtherUser(userId: AuthViewModel.PreviewUserID)}
                                        case .months3:
                                            INRChartView(data: viewModel.MeasurementINRmonth3OtherUser)
                                                .onAppear{viewModel.getMeasurementINRmonth3OtherUser(userId: AuthViewModel.PreviewUserID)}
                                        case .months6:
                                            INRChartView(data: viewModel.MeasurementINRmonth6OtherUser).onAppear{viewModel.getMeasurementINRmonth6OtherUser(userId: AuthViewModel.PreviewUserID)}
                                        default:
                                            INRChartView(data: viewModel.INRMeasurementsOtherUser)
                                        }
                                        Button("Gotowe"){
                                            self.dateRng = .week
                                            INRDetails.toggle()
                                        }.buttonStyle(.borderedProminent)
                                    }.padding().onAppear{self.dateRng = .month}
                                }
                        }
                        if(!AuthViewModel.PreviewMode){
                            INRChartView(data: viewModel.pomiaryINR).frame(height: self.dynamicTypeSize.isAccessibilitySize ? 300 : 150)
                                .onTapGesture {
                                    INRDetails.toggle()
                                }.sheet(isPresented: $INRDetails, onDismiss: {self.dateRng = .week}){
                                    VStack{
                                        Text("Pomiary INR").font(.title)
                                        Picker("Zakres", selection: $dateRng){
                                            ForEach(dateRange.INRdateRange){ rng in
                                                Text(rng.dsc).tag(rng)
                                            }
                                        }.pickerStyle(.segmented).padding(.bottom, 10)
                                        switch self.dateRng{
                                        case .month:
                                            INRChartView(data: viewModel.MeasurementINRmonth)
                                                .onAppear{viewModel.getMeasurementINRmonth()}
                                        case .months3:
                                            INRChartView(data: viewModel.MeasurementINRmonth3)
                                                .onAppear{viewModel.getMeasurementINRmonth3()}
                                        default:
                                            INRChartView(data: viewModel.pomiaryINR)
                                        }
                                        Button("Gotowe"){
                                            self.dateRng = .week
                                            INRDetails.toggle()
                                        }.buttonStyle(.borderedProminent)
                                    }.padding().onAppear{self.dateRng = .month}
                                }
                        }
                        
                        Button("Lista pomiarów"){
                            self.INRListSheet.toggle()
                        }.disabled(AuthViewModel.PreviewMode).sheet(isPresented: $INRListSheet){
                            List{
                                ForEach(viewModel.INRPaginated){ i in
                                    Text("\(viewModel.formatDate(dt: i.date)) \(i.value, specifier: "%.1f")")
                                        .swipeActions(edge: .trailing){
                                            Button(role: .destructive){
                                                viewModel.deleteINR(id: i.id!)
                                                viewModel.INRPaginated.removeAll(where: {$0.id == i.id})
                                                viewModel.pomiaryINR.removeAll(where: {$0.id == i.id})
                                            } label: {
                                                Label("Usuń", systemImage: "trash")
                                            }
                                        }.swipeActions(edge: .leading){
                                            Button{
                                                viewModel.pomiarINR = i
                                                viewModel.INRText = String(i.value)
                                                INRPresented.toggle()
                                            }label: {
                                                Label("Edytuj", systemImage: "square.and.pencil")
                                            }.tint(.blue)
                                        }.sheet(isPresented: $INRPresented){
                                            VStack{
                                                Text("Podaj pomiar").multilineTextAlignment(.center).font(.title).foregroundColor(.cyan)
                                                TextField("0.00", text: $viewModel.INRText).textFieldStyle(TFNumberStyle())
                                                Text(viewModel.conformINRPrompt).foregroundColor(.red)
                                                Button{
                                                    updateINR(inr: i)
                                                    viewModel.INRText = ""
                                                    INRPresented.toggle()
                                                } label: {
                                                    Text("Zapisz").frame(maxWidth: .infinity)
                                                }.disabled(!viewModel.isINRValid).buttonStyle(.borderedProminent)
                                                Button{
                                                    viewModel.pobierzPomiarINR()
                                                    INRPresented.toggle()
                                                } label: {
                                                    Text("Anuluj").frame(maxWidth: .infinity)
                                                }.buttonStyle(.bordered).tint(.red).padding(.bottom, 20)
                                            }
                                        }
                                }
                            }
                            Button("Pobierz więcej pomiarów"){
                                viewModel.getMoreINR()
                            }
                            Button{
                                INRListSheet.toggle()
                            }label: {
                                Text("Gotowe").frame(maxWidth: .infinity)
                            }.buttonStyle(.borderedProminent)
                        }
                        
                        if !AuthViewModel.PreviewMode{
                            if(calendar.isDateInToday(viewModel.pomiarINR.date) && viewModel.pomiarINR.value > 0.01){
                                Text("Dzisiejszy pomiar wynosi: \(viewModel.pomiarINR.value, specifier: "%.2f")").accessibilityIdentifier("todaysMeasurement")
                                Button("Zmień pomiar INR"){INRPresented.toggle()}
                                    .buttonStyle(.bordered)
                                    .sheet(isPresented: $INRPresented){
                                        VStack{
                                            Text("Wpisz wynik pomiaru").multilineTextAlignment(.center).font(.title).foregroundColor(.cyan)
                                            TextField("0.00", text: $viewModel.INRText).textFieldStyle(TFNumberStyle())
                                            Text(viewModel.conformINRPrompt).foregroundColor(.red)
                                            Button{
                                                konwerujINR()
                                                viewModel.INRText = ""
                                                INRPresented.toggle()
                                            }label:{
                                                Text("Zapisz").frame(maxWidth: .infinity)
                                            }.disabled(!viewModel.isINRValid).buttonStyle(.borderedProminent)
                                            Button{INRPresented.toggle()} label: {
                                                Text("Anuluj").frame(maxWidth: .infinity)
                                            }.buttonStyle(.borderedProminent).tint(.red).padding(.bottom, 20)
                                        }.padding()
                                    }
                            }else{
                                Button("Dodaj pomiar INR"){INRPresented.toggle()}
                                    .buttonStyle(.borderedProminent)
                                    .sheet(isPresented: $INRPresented){
                                        VStack{
                                            Text("Wpisz wynik pomiaru").multilineTextAlignment(.center).font(.title).foregroundColor(.cyan)
                                            TextField("0.00", text: $viewModel.INRText).textFieldStyle(TFNumberStyle())
                                            Text(viewModel.conformINRPrompt).foregroundColor(.red)
                                            Button{
                                                konwerujINR()
                                                viewModel.INRText = ""
                                                INRPresented.toggle()
                                            }label:{
                                                Text("Zapisz").frame(maxWidth: .infinity)
                                            }.disabled(!viewModel.isINRValid).buttonStyle(.borderedProminent)
                                            Button{INRPresented.toggle()} label: {
                                                Text("Anuluj").frame(maxWidth: .infinity)
                                            }.buttonStyle(.bordered).tint(.red).padding(.bottom, 20)
                                        }.padding()
                                    }
                            }
                        }
                    }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    
                    VStack{
                        Text("Ostatnie pomiary Tętna")
                        if AuthViewModel.PreviewMode{
                            Chart(viewModel.convertBloodMeasurements(BPData: viewModel.BPMeasurementsOtherUser), id: \.name){ data in
                                ForEach(data.data){pomiar in
                                    LineMark(
                                        x: .value("Data", pomiar.time),
                                        y: .value("Puls", pomiar.value)
                                    )
                                    .foregroundStyle(by: .value("typ", data.name))
                                    .position(by: .value("typ", data.name))
                                }
                            }
                            .chartYScale(domain: [50, 150])
                            .frame(height: self.dynamicTypeSize.isAccessibilitySize ? 300 : 150)
                            .onTapGesture {
                                BPDetails.toggle()
                            }.sheet(isPresented: $BPDetails, onDismiss: {self.dateRng = .week}){
                                VStack{
                                    Text("Pomiary ciśnienia").font(.title)
                                    Picker("Zakres", selection: $dateRng){
                                        ForEach(dateRange.BPdateRangeDoc){ rng in
                                            Text(rng.dsc).tag(rng)
                                        }
                                    }.pickerStyle(.segmented)
                                    switch self.dateRng{
                                    case .week:
                                        BPChartView(data: viewModel.MeasurementBPweekOtherUser)
                                            .onAppear{viewModel.getMeasurementBPweekOtherUser(userId: AuthViewModel.PreviewUserID)}
                                    case .month:
                                        BPChartView(data: viewModel.MeasurementBPmonthAvgOtherUser)
                                            .onAppear{viewModel.getMeasurementBPmonthOtherUser(userId: AuthViewModel.PreviewUserID)}
                                    case .months3:
                                        BPChartView(data: viewModel.MeasurementBPmonth3AvgOtherUser).onAppear{viewModel.getMeasurementBPmonth3(userId: AuthViewModel.PreviewUserID)}
                                    default:
                                        BPChartView(data: viewModel.MeasurementBPweekOtherUser)
                                    }
                                    Button("Gotowe"){
                                        self.dateRng = .week
                                        BPDetails.toggle()
                                    }.buttonStyle(.borderedProminent)
                                }.padding()
                            }
                        }else{
                            Chart(viewModel.convertBloodMeasurements(BPData: viewModel.pomiaryTetno), id: \.name){ data in
                                ForEach(data.data){pomiar in
                                    LineMark(
                                        x: .value("Data", pomiar.time),
                                        y: .value("Puls", pomiar.value)
                                    )
                                    .foregroundStyle(by: .value("typ", data.name))
                                    .position(by: .value("typ", data.name))
                                }
                            }
                            .chartYScale(domain: [40, 160])
                            .frame(height: self.dynamicTypeSize.isAccessibilitySize ? 600 : 300)
                            .onTapGesture {
                                BPDetails.toggle()
                            }.sheet(isPresented: $BPDetails, onDismiss: {self.dateRng = .week}){
                                VStack{
                                    Text("Pomiary ciśnienia").font(.title)
                                    Picker("Zakres", selection: $dateRng){
                                        ForEach(dateRange.BPdateRangePatient){ rng in
                                            Text(rng.dsc).tag(rng)
                                        }
                                    }.pickerStyle(.segmented)
                                    switch self.dateRng{
                                    case .week:
                                        BPChartView(data: viewModel.MeasurementBPweek)
                                            .onAppear{viewModel.getMeasurementBPweek()}
                                    case .month:
                                        BPChartView(data: viewModel.MeasurementBPmonthAvg)
                                            .onAppear{viewModel.getMeasurementBPmonth()}
                                    default:
                                        BPChartView(data: viewModel.MeasurementBPweek)
                                    }
                                    Button("Gotowe"){
                                        self.dateRng = .week
                                        BPDetails.toggle()
                                    }.buttonStyle(.borderedProminent)
                                }.padding()
                            }
                        }
                        
                        Button("Lista pomiarów"){
                            self.BPListSheet.toggle()
                        }.disabled(AuthViewModel.PreviewMode).sheet(isPresented: $BPListSheet){
                            List{
                                ForEach(viewModel.BPPaginated){ i in
                                    Text("\(viewModel.formatDate(dt: i.time)), puls: \(i.pulse, specifier: "%.0f")")
                                        .swipeActions(edge: .trailing){
                                            Button(role: .destructive){
                                                viewModel.deleteBP(id: i.id!)
                                                viewModel.BPPaginated.removeAll(where: {$0.id == i.id})
                                                viewModel.pomiaryTetno.removeAll(where: {$0.id == i.id})
                                            } label: {
                                                Label("Usuń", systemImage: "trash")
                                            }
                                        }.swipeActions(edge: .leading){
                                            Button{
                                                viewModel.pomiarTetno = i
                                                viewModel.pulse = String(i.pulse)
                                                viewModel.d_pressure = String(i.diastolic_pressure)
                                                viewModel.s_pressure = String(i.systolic_pressure)
                                                TetnoPresented.toggle()
                                            }label: {
                                                Label("Edytuj", systemImage: "square.and.pencil")
                                            }.tint(.blue)
                                        }.sheet(isPresented: $TetnoPresented){
                                            VStack{
                                                Group{
                                                    Text("Zmień pomiar Tętna").multilineTextAlignment(.center).font(.title).foregroundColor(.cyan)
                                                    Text("Podaj pomiar pulsu").font(.title2)
                                                    TextField("0.00", text: $viewModel.pulse).textFieldStyle(TFNumberStyle())
                                                    Text(viewModel.conformPulsePrompt).foregroundColor(.red)
                                                    Text("Podaj pomiar ciśnienia rozkurczowego").font(.title2)
                                                    TextField("0.00", text: $viewModel.d_pressure).textFieldStyle(TFNumberStyle())
                                                    Text(viewModel.conformDPPrompt).foregroundColor(.red)
                                                    Text("Podaj pomiar ciśnienia skurczowego").font(.title2)
                                                    TextField("0.00", text: $viewModel.s_pressure).textFieldStyle(TFNumberStyle())
                                                    Text(viewModel.conformSPPrompt).foregroundColor(.red)
                                                }
                                                Button{
                                                    updateBP(bp: i)
                                                    viewModel.pulse = ""
                                                    viewModel.s_pressure = ""
                                                    viewModel.d_pressure = ""
                                                    TetnoPresented.toggle()
                                                } label: {
                                                    Text("Zapisz").frame(maxWidth: .infinity)
                                                }.disabled(!viewModel.canSubmitBP).buttonStyle(.borderedProminent)
                                                Text(viewModel.conformBPPrompt).foregroundColor(.red)
                                                Button{TetnoPresented.toggle()} label: {
                                                    Text("Anuluj").frame(maxWidth: .infinity)
                                                }.buttonStyle(.bordered).tint(.red).padding(.bottom, 20)
                                            }.padding()
                                        }
                                }
                            }
                            Button("Pobierz więcej pomiarów"){
                                viewModel.getMoreBP()
                            }
                            Button{
                                BPListSheet.toggle()
                            }label: {
                                Text("Gotowe").frame(maxWidth: .infinity)
                            }.buttonStyle(.borderedProminent)
                        }
                        
                        if !AuthViewModel.PreviewMode{
                            if(viewModel.pomiarTetno.time.timeIntervalSinceNow > -3600 && viewModel.pomiarTetno.pulse > 0.01){
                                Text("Dodałeś pomiar w ciągu ostatniej godziny.")
                                Button("Zmień ostatni pomiar Tętna"){TetnoPresented.toggle()}
                                    .buttonStyle(.bordered)
                                    .sheet(isPresented: $TetnoPresented){
                                        ScrollView{
                                            Group{
                                                Text("Zmień pomiar Tętna").multilineTextAlignment(.center).font(.title).foregroundColor(.cyan)
                                                Text("Podaj pomiar pulsu").font(.title2)
                                                TextField("0.00", text: $viewModel.pulse).textFieldStyle(TFNumberStyle())
                                                Text(viewModel.conformPulsePrompt).foregroundColor(.red)
                                                Text("Podaj pomiar ciśnienia rozkurczowego").font(.title2)
                                                TextField("0.00", text: $viewModel.d_pressure).textFieldStyle(TFNumberStyle())
                                                Text(viewModel.conformDPPrompt).foregroundColor(.red)
                                                Text("Podaj pomiar ciśnienia skurczowego").font(.title2)
                                                TextField("0.00", text: $viewModel.s_pressure).textFieldStyle(TFNumberStyle())
                                                Text(viewModel.conformSPPrompt).foregroundColor(.red)
                                            }
                                            Button{
                                                konwerujTetno()
                                                TetnoPresented.toggle()
                                            } label: {
                                                Text("Zapisz").frame(maxWidth: .infinity)
                                            }.disabled(!viewModel.canSubmitBP).buttonStyle(.borderedProminent)
                                            Text(viewModel.conformBPPrompt).foregroundColor(.red)
                                            Button{TetnoPresented.toggle()} label: {
                                                Text("Anuluj").frame(maxWidth: .infinity)
                                            }.buttonStyle(.bordered).tint(.red).padding(.bottom, 20)
                                        }.padding()
                                    }
                            }else{
                                Button("Dodaj pomiar Tętna"){TetnoPresented.toggle()}
                                    .buttonStyle(.borderedProminent)
                                    .sheet(isPresented: $TetnoPresented){
                                        ScrollView{
                                            Group{
                                                Text("Zmień pomiar Tętna").multilineTextAlignment(.center).font(.title).foregroundColor(.cyan)
                                                Text("Podaj pomiar pulsu").font(.title2)
                                                TextField("0.00", text: $viewModel.pulse).textFieldStyle(TFNumberStyle())
                                                Text(viewModel.conformPulsePrompt).foregroundColor(.red)
                                                Text("Podaj pomiar ciśnienia rozkurczowego").font(.title2)
                                                TextField("0.00", text: $viewModel.d_pressure).textFieldStyle(TFNumberStyle())
                                                Text(viewModel.conformDPPrompt).foregroundColor(.red)
                                                Text("Podaj pomiar ciśnienia skurczowego").font(.title2)
                                                TextField("0.00", text: $viewModel.s_pressure).textFieldStyle(TFNumberStyle())
                                                Text(viewModel.conformSPPrompt).foregroundColor(.red)
                                            }
                                            Button{
                                                konwerujTetno()
                                                TetnoPresented.toggle()
                                            } label: {
                                                Text("Zapisz").frame(maxWidth: .infinity)
                                            }.disabled(!viewModel.canSubmitBP).buttonStyle(.borderedProminent)
                                            Text(viewModel.conformBPPrompt).foregroundColor(.red)
                                            Button{TetnoPresented.toggle()} label: {
                                                Text("Anuluj").frame(maxWidth: .infinity)
                                            }.buttonStyle(.bordered).tint(.red).padding(.bottom, 20)
                                        }.padding()
                                    }
                            }
                        }
                    }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                }.padding().onAppear{
                    if(AuthViewModel.PreviewMode){
                        viewModel.getINRMeasurementsOtherUser(userId: AuthViewModel.PreviewUserID)
                        viewModel.getMeasurementBPOtherUser(userId: AuthViewModel.PreviewUserID)
                    }else{
                        viewModel.INRMeasurementsOtherUser.removeAll()
                        viewModel.MeasurementINRmonthOtherUser.removeAll()
                        viewModel.MeasurementINRmonth3OtherUser.removeAll()
                        viewModel.BPMeasurementsOtherUser.removeAll()
                        viewModel.MeasurementBPweekOtherUser.removeAll()
                        viewModel.MeasurementBPmonthOtherUser.removeAll()
                        viewModel.MeasurementBPmonthAvgOtherUser.removeAll()
                    }
                    
                }
            }
        }
    }
    
    func konwerujINR(){
        viewModel.pomiarINR.value = Double(viewModel.INRText)!
        viewModel.zapiszPomiarINR()
    }
    func updateINR(inr: INR){
        viewModel.pomiarINR.value = Double(viewModel.INRText)!
        viewModel.updateINR()
        //viewModel.pomiaryINR[viewModel.pomiaryINR.firstIndex(where: {$0.id == inr.id})!] = viewModel.pomiarINR
        viewModel.pobierzPomiarINR()
    }
    
    func updateBP(bp: Tetno){
        viewModel.pomiarTetno.pulse = Double(viewModel.pulse)!
        viewModel.pomiarTetno.diastolic_pressure = Double(viewModel.d_pressure)!
        viewModel.pomiarTetno.systolic_pressure = Double(viewModel.s_pressure)!
        viewModel.updateBP()
        //viewModel.pomiaryINR[viewModel.pomiaryINR.firstIndex(where: {$0.id == inr.id})!] = viewModel.pomiarINR
        viewModel.pobierzPomiarTetno()
    }
    
    func konwerujTetno(){
        viewModel.pomiarTetno.pulse = Double(viewModel.pulse)!
        viewModel.pomiarTetno.diastolic_pressure = Double(viewModel.d_pressure)!
        viewModel.pomiarTetno.systolic_pressure = Double(viewModel.s_pressure)!
        viewModel.zapiszPomiarTetno()
    }
}


struct PomiarView_Previews: PreviewProvider {
    static var previews: some View {
        PomiarView()
    }
}
