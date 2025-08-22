//
//  UserView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 07/10/2023.
//

import SwiftUI
import FirebaseAuth
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers
import CodeScanner

struct UserView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    @State var editSheet = false
    @State var shareUid = false
    @State var logoutAlert = false
    @State var INRRangeSheet = false
    @State var showingScanner = false
    @State var otherUsersProfilesSheet = false
    @State var notifiSheet = false
    @State var accessabilitySheet = false
    @State var pendingReadAccessList = false
    @State var readAccessList = false
    
    
    
    @State var notifiEnabled: Bool
    @State var notificationsPermissionsDisabled = false
    
    @State var INRUpperLimit = ""
    @State var INRLowerLimit = ""
    @State var qrScanResult = ""
    
    @State var sliderPosition: ClosedRange<Float> = 2...3
    
    @AppStorage("INRLowerLimit") var lowerLimit: Double?
    @AppStorage("INRUpperLimit") var upperLimit: Double?
    
    
    init(){
        @AppStorage("NotificationsEnabled") var ne: Bool?
        _notifiEnabled = State(initialValue: ne ?? false)
        _sliderPosition = State(initialValue: ClosedRange<Float>(uncheckedBounds: (lower: Float(lowerLimit ?? 2), upper: Float(upperLimit ?? 3))) )
    }
    
    var body: some View {
            switch viewModel.astate{
            case .authed:
                ZStack{
                    Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fit).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
                    ScrollView{
                        VStack{
                            VStack{
                                if !viewModel.PreviewMode{Text("Witaj \(viewModel.displayName)").font(.title)}
                                Divider()
                                if viewModel.PreviewMode{
                                    Text("Dane użytkownika \(viewModel.otherUsername)").font(.title2)
                                    VStack(alignment: .leading){
                                        Text("Data rejestracji: \(formatDate(dt: viewModel.regDateOtherUser))")
                                        Text("Imię i nazwisko: \(viewModel.firstNameOtherUser) \(viewModel.lastNameOtherUser)")
                                        Text("Kraj: \(viewModel.countryOtherUser.image) \(viewModel.countryOtherUser.description)")
                                        Text("Główna choroba: \(viewModel.illnessOhterUser)")
                                        Text("Główny lek: \(viewModel.medicationOtherUser.rawValue)")
                                    }
                                }else{
                                    Text("Dane użytkownika").font(.title2)
                                    VStack(alignment: .leading){
                                        Text("Data rejestracji: \(formatDate(dt: viewModel.regDate))")
                                        Text("Imię i nazwisko: \(viewModel.first_name) \(viewModel.last_name)")
                                        Text("Kraj: \(viewModel.country.image) \(viewModel.country.description)")
                                        Text("Główna choroba: \(viewModel.illness)")
                                        Text("Główny lek: \(viewModel.medication.rawValue)")
                                    }
                                }
                            }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                            VStack{
                                Text("Ustawienia").font(.title2)
                                
                                Button{
                                    accessabilitySheet.toggle()
                                }label: {
                                    HStack{
                                        Text("Ustawienia dostępności")
                                        Spacer()
                                    }.frame(maxWidth: .infinity)
                                }.disabled(viewModel.PreviewMode).buttonStyle(.bordered).sheet(isPresented: $accessabilitySheet){
                                    VStack{
                                        Text("Dostępność").font(.title).foregroundColor(.cyan)
                                        Text("Aplikacja wspiera dynamiczną wielkość czcionki. Możesz ją zmienić w ustawieniach iPhone: Ustawienia -> Dostępność -> Ekran i wielkość tekstu -> Większy tekst")
                                        Text("Aplikacja wspiera tryb zwiększonego kontrastu. Możesz go włączyć w ustawieniach iPhone: Ustawienia -> Dostępność -> Ekran i wielkość tekstu -> Większy kontrast")
                                    }.padding()
                                }
                                Button{
                                    notifiSheet.toggle()
                                }label: {
                                    HStack{
                                        Text("Ustawienia powiadomień")
                                        Spacer()
                                    }.frame(maxWidth: .infinity)
                                }.disabled(viewModel.PreviewMode).buttonStyle(.bordered).sheet(isPresented: $notifiSheet){
                                    VStack(spacing: 20){
                                        Text("Ustawienia powiadomień").font(.title).foregroundColor(.cyan).multilineTextAlignment(.center)
                                        Text(notifiEnabled ? "Powiadomienia są włączone" : "Powiadomienia są wyłączone, ustaw harmonogram głównego leku aby je włączyć.")
                                        Button{
                                            disableNotifications()
                                        } label: {
                                            Text("Wyłącz powiadomienia").frame(maxWidth: .infinity)
                                        }.buttonStyle(.bordered).disabled(!notifiEnabled)
                                        Button{
                                            otherUsersProfilesSheet.toggle()
                                        } label: {
                                            Text("Zamknij").frame(maxWidth: .infinity)
                                        }.buttonStyle(.borderedProminent)
                                    }.padding()
                                }.onAppear{
                                    @AppStorage("NotificationsEnabled") var ne: Bool?
                                    notifiEnabled = ne ?? false
                                }
                                Button{
                                    INRRangeSheet.toggle()
                                }label: {
                                    HStack{
                                        Text("Ustaw przedział terapeutyczny")
                                        Spacer()
                                    }.frame(maxWidth: .infinity)
                                    
                                }.buttonStyle(.bordered).sheet(isPresented: $INRRangeSheet){
                                    VStack(alignment: .center){
                                        Text("Wybierz przedział za pomocą suwaka").multilineTextAlignment(.center).font(.title).foregroundColor(.cyan)
                                        RangedSliderView(value: $sliderPosition, bounds: 0...6).padding()
                                        Button{
                                            saveInrRange()
                                            INRRangeSheet.toggle()
                                        } label: {
                                            Text("Zapisz").frame(maxWidth: .infinity)
                                        }.buttonStyle(.borderedProminent)
                                        Button{
                                            INRRangeSheet.toggle()
                                        } label: {
                                            Text("Anuluj").frame(maxWidth: .infinity)
                                        }.buttonStyle(.bordered).padding(.bottom, 20)
                                    }.padding().presentationDetents([.medium])
                                }.disabled(viewModel.PreviewMode)
                                
                                if(viewModel.role != "patient"){
                                    Button{
                                        if(viewModel.otherUserProfile.isEmpty){viewModel.getAccessUsersProfiles()}
                                        otherUsersProfilesSheet.toggle()
                                    }label: {
                                        HStack{
                                            Text("Przejżyj profil innego użytkownika")
                                            Spacer()
                                        }.frame(maxWidth: .infinity)
                                        
                                    }.buttonStyle(.bordered).sheet(isPresented: $otherUsersProfilesSheet){
                                        if(viewModel.PreviewUserID != viewModel.user!.uid){
                                            VStack{
                                                Text("Przeglądasz profil użytkownika \(viewModel.otherUsername)").font(.title).foregroundColor(.cyan)
                                                Button{
                                                    viewModel.switchBackToUser()
                                                }label: {
                                                    Text("Wróć do swojego profilu").frame(maxWidth: .infinity)
                                                }.buttonStyle(.borderedProminent)
                                                Button{
                                                    otherUsersProfilesSheet.toggle()
                                                } label: {
                                                    Text("Zamknij").frame(maxWidth: .infinity)
                                                }.buttonStyle(.borderedProminent)
                                            }.padding().presentationDetents([.medium])
                                        }else{
                                            VStack(spacing: 20){
                                                Text("Masz dostęp do następujących użytkowników:").font(.title).foregroundColor(.cyan).multilineTextAlignment(.center)
                                                Text("Przesuń nazwę użytkownika w prawo aby przejrzeć jego profil")
                                                List{
                                                    ForEach(viewModel.GivenReadAccessBy, id: \.self){grab in
                                                        Text(OtherUserProfileText(userId: grab)).swipeActions(edge: .leading){
                                                            Button{
                                                                viewModel.switchToOtherUser(userId: grab)
                                                            }label: {
                                                                Label("Przełącz widok na tego użytkownika", systemImage: "person.crop.circle.badge.checkmark")
                                                            }.tint(.blue)
                                                        }
                                                    }
                                                }
                                                Button{
                                                    otherUsersProfilesSheet.toggle()
                                                } label: {
                                                    Text("Zamknij").frame(maxWidth: .infinity)
                                                }.buttonStyle(.borderedProminent)
                                            }.padding()
                                        }
                                    }
                                }
                                
                                Button{
                                    shareUid.toggle()
                                }label: {
                                    HStack{
                                        Text("Udostępnij profil")
                                        Spacer()
                                    }.frame(maxWidth: .infinity)
                                }.buttonStyle(.bordered).disabled(viewModel.PreviewMode).sheet(isPresented: $shareUid){
                                    ScrollView{
                                        Text("Daj ten kod do zeskanowania osobie której chcesz udostępnić profil").multilineTextAlignment(.center).font(.title2).foregroundColor(.cyan)
                                        Image(uiImage: generateQRCode(from: "\(viewModel.user!.uid)")).interpolation(.none).resizable().scaledToFit().frame(width: 150, height: 150)
                                        //                                        HStack{
                                        //                                            Text("lub wyślij jej swoje")
                                        //                                            HStack{
                                        //                                                Text("ID").foregroundColor(.blue)
                                        //                                                Image(systemName: "doc.on.doc").foregroundColor(.blue)
                                        //                                            }.onTapGesture {
                                        //                                                UIPasteboard.general.setValue(viewModel.user!.uid, forPasteboardType: UTType.plainText.identifier)
                                        //                                            }
                                        //                                        }
                                        Button{
                                            showingScanner.toggle()
                                            qrScanResult = ""
                                            viewModel.sentReadRequest = false
                                        }label:{
                                            Text("Zeskanuj kod QR").frame(maxWidth: .infinity)
                                        }.buttonStyle(.borderedProminent).padding(.bottom, 20).sheet(isPresented: $showingScanner){
                                            CodeScannerView(codeTypes: [.qr], simulatedData: "F4QNgv6lTVQtNVcAo1eQU24GlwY2", completion: handleScan)
                                        }
                                        if(!qrScanResult.isEmpty){
                                            if(viewModel.GivenReadAccessBy.contains(qrScanResult)){
                                                Text("Masz już dostęp do tego użytkownika")
                                            }else{
                                                if(!viewModel.sentReadRequest){
                                                    Text("Zeskanowano kod \(qrScanResult)")
                                                    Button("Wyślij prośbę o udostępnienie danych"){
                                                        viewModel.sendReadAccessRequest(userId: qrScanResult)
                                                        viewModel.sentReadRequest = true
                                                    }.padding(.bottom, 20)
                                                }else{
                                                    Text("Prośba wysłana ✅").padding(.bottom, 20)
                                                }
                                            }
                                        }
                                        Spacer()
                                        Group{
                                            Button{
                                                if(viewModel.otherUserProfile.isEmpty){viewModel.getAccessUsersProfiles()}
                                                pendingReadAccessList.toggle()
                                            } label: {
                                                Text("Prośby o udostępnienie").frame(maxWidth: .infinity)
                                            }.buttonStyle(.borderedProminent).sheet(isPresented: $pendingReadAccessList){
                                                VStack{
                                                    Text("Użytkownicy którzy proszą o udostępnienie profilu:").font(.title).foregroundColor(.cyan).multilineTextAlignment(.center)
                                                    Text("Przesuń w prawo aby dać temu użytkownikowi dostęp do profilu lub w lewo aby zignorować prośbę")
                                                    List{
                                                        ForEach(viewModel.pendingReadAccess, id: \.self){ pra in
                                                            Text(OtherUserProfileText(userId: pra)).swipeActions(edge: .trailing){
                                                                Button(role: .destructive){
                                                                    viewModel.removePendingAccessRequest(userId: pra)
                                                                } label: {
                                                                    Label("Usuń", systemImage: "trash")
                                                                }
                                                            }.swipeActions(edge: .leading){
                                                                Button{
                                                                    viewModel.acceptReadAccessRequest(userId: pra)
                                                                }label: {
                                                                    Label("Zaakceptuj", systemImage: "person.crop.circle.badge.checkmark")
                                                                }.tint(.green)
                                                            }
                                                        }
                                                    }
                                                    Button{
                                                        if(viewModel.otherUserProfile.isEmpty){viewModel.getAccessUsersProfiles()}
                                                        pendingReadAccessList.toggle()
                                                    } label: {
                                                        Text("Zamknij").frame(maxWidth: .infinity)
                                                    }.buttonStyle(.borderedProminent)
                                                }.padding()
                                            }
                                            Button{
                                                if(viewModel.otherUserProfile.isEmpty){viewModel.getAccessUsersProfiles()}
                                                readAccessList.toggle()
                                            } label: {
                                                Text("Użytkownicy z dostępem do twojego profilu").frame(maxWidth: .infinity)
                                            }.buttonStyle(.borderedProminent).sheet(isPresented: $readAccessList){
                                                VStack{
                                                    Text("Użytkownicy którzy mają dostęp do twojego profilu:").font(.title).foregroundColor(.cyan).multilineTextAlignment(.center)
                                                    Text("Przesuń w lewo aby odebrać dostęp do profilu")
                                                    List{
                                                        ForEach(viewModel.readAccess, id: \.self){ ra in
                                                            Text(OtherUserProfileText(userId: ra)).swipeActions(edge: .trailing){
                                                                Button(role: .destructive){
                                                                    viewModel.removeReadAccess(userId: ra)
                                                                } label: {
                                                                    Label("Delete", systemImage: "trash")
                                                                }
                                                            }
                                                        }
                                                    }
                                                    Button{
                                                        readAccessList.toggle()
                                                    } label: {
                                                        Text("Zamknij").frame(maxWidth: .infinity)
                                                    }.buttonStyle(.borderedProminent)
                                                }.padding()
                                            }
                                        }
                                        Button{
                                            shareUid.toggle()
                                        } label: {
                                            Text("Zamknij").frame(maxWidth: .infinity)
                                        }.buttonStyle(.borderedProminent)
                                    }.padding()
                                }
                                Button{
                                    editSheet.toggle()
                                }label: {
                                    HStack{
                                        Text("Edytuj dane")
                                        Spacer()
                                    }.frame(maxWidth: .infinity)
                                }.buttonStyle(.bordered).disabled(viewModel.PreviewMode).sheet(isPresented: $editSheet){
                                    List{
                                        Section{
                                            VStack{
                                                TextField("Imię", text: $viewModel.first_name).textFieldStyle(TFTextStyle())
                                                TextField("Nazwisko", text: $viewModel.last_name).textFieldStyle(TFTextStyle())
                                                TextField("Nazwa użytkownika", text: $viewModel.username).textFieldStyle(TFTextStyle())
                                                Picker("Płeć", selection: $viewModel.gender){
                                                    ForEach(genders.allCases){ g in
                                                        Text(g.description).tag(g)
                                                    }
                                                }.pickerStyle(.menu)
                                                Picker("Państwo", selection: $viewModel.country){
                                                    ForEach(countries.allCases){ c in
                                                        Text("\(c.image) \(c.description)").tag(c)
                                                    }
                                                    Text("Other")
                                                }.pickerStyle(.menu)
                                                TextField("Główna choroba", text: $viewModel.illness).textFieldStyle(TFTextStyle())
                                            }
                                        }
                                        Section{
                                            Button("Zapisz dane"){
                                                viewModel.updateUserData()
                                            }
                                            Button("Anuluj"){
                                                editSheet.toggle()
                                            }.foregroundColor(.red)
                                        }
                                    }
                                }
                                Button{
                                    logoutAlert.toggle()
                                } label: {
                                    HStack{
                                        Text("Wyloguj")
                                        Spacer()
                                    }.frame(maxWidth: .infinity)
                                }.buttonStyle(.bordered).disabled(viewModel.PreviewMode).foregroundColor(.red).tint(.red).alert("Czy napewno chcesz się wylogować?", isPresented: $logoutAlert){
                                    Button("Wyloguj", action: wyloguj).foregroundColor(.red)
                                    Button("Anuluj", role: .cancel){}.keyboardShortcut(.defaultAction)
                                }
                            }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                        }.padding()
                    }.onAppear{
                        if viewModel.PreviewMode{
                            viewModel.retrieveOtherUserData(userId: viewModel.PreviewUserID)
                        }
                    }
                }
                
            default:
                Text("Nie jesteś zalogowany!")
            }
    }
    
    func saveInrRange(){
        UserDefaults.standard.set(Double(sliderPosition.lowerBound), forKey: "INRLowerLimit")
        UserDefaults.standard.set(Double(sliderPosition.upperBound), forKey: "INRUpperLimit")
    }
    
    func wyloguj(){
        viewModel.country = .ratherNotSay
        viewModel.first_name = ""
        viewModel.last_name = ""
        viewModel.gender = .ratherNotSay
        viewModel.illness = ""
        viewModel.medication = .Warfin
        viewModel.username = ""
        viewModel.email = ""
        viewModel.haslo = ""
        viewModel.displayName = ""
        viewModel.SignOut()
    }
    
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    func handleScan(result: Result<ScanResult, ScanError>){
        showingScanner = false
        switch result{
        case .success(let result):
            qrScanResult = result.string
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    func formatDate(dt: Date) -> String{
        let components = Calendar.current.dateComponents([.hour, .minute, .day, .month, .year], from: dt)
        return "\(components.day ?? 01).\(components.month ?? 01).\(components.year ?? 2000)"
    }
    
    func disableNotifications(){
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        UserDefaults.standard.setValue(false, forKey: "NotificationsEnabled")
        notifiEnabled = false
    }
    
    func OtherUserProfileText(userId: String) -> String{
        if let profile = viewModel.otherUserProfile.first(where: {$0.id == userId}){
            var message = ""
            if(!profile.userName.isEmpty){message += profile.userName}
            if(profile.ctry != .ratherNotSay){message += profile.ctry.image}
            if(!profile.userName.isEmpty || profile.ctry != .ratherNotSay){message += "\n"}
            if(!profile.firstName.isEmpty){message += profile.firstName + " "}
            if(!profile.lastName.isEmpty){message += profile.lastName}
            if(!profile.firstName.isEmpty || !profile.lastName.isEmpty){message += "\n"}
            return message + "identyfikator: \(profile.id)"
        }
        return "Błąd pobierania danych innego użytkownika"
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView().environmentObject(AuthenticationViewModel())
    }
}
