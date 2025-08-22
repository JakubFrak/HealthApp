//
//  Signup2View.swift
//  HealthApp
//
//  Created by Jakub Frąk on 11/12/2023.
//

import SwiftUI

struct Signup2View: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    
    @State private var blad = false
    
    @State private var showAlert = false
    
    var body: some View {
        ZStack{
            Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fit).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
            ScrollView{
                VStack{
                    VStack{
                        Text("Rejestracja").foregroundColor(.cyan).font(.largeTitle).padding(.bottom, 20)
                        VStack(alignment: .leading){
                            Text("Imię:")
                            TextField("Imię", text: $viewModel.first_name).textFieldStyle(TFTextStyle())
                            Text("Nazwisko")
                            TextField("Nazwisko", text: $viewModel.last_name).textFieldStyle(TFTextStyle())
                            HStack{
                                Text("Płeć:")
                                Spacer()
                                Picker("Płeć", selection: $viewModel.gender){
                                    ForEach(genders.allCases){ g in
                                        Text(g.description).tag(g)
                                    }
                                }.pickerStyle(.menu)
                            }.padding(.bottom, 20)
                            HStack{
                                Text("Państwo:")
                                Spacer()
                                Picker("Państwo", selection: $viewModel.country){
                                    ForEach(countries.allCases){ c in
                                        Text("\(c.image) \(c.description)").tag(c)
                                    }
                                }.pickerStyle(.menu)
                            }.padding(.bottom, 20)
                            Text("Podaj główną chorobę którą leczysz:")
                            TextField("Główna choroba", text: $viewModel.illness).textFieldStyle(TFTextStyle())
                        }
                        if(blad){Text("Błąd rejestracji, spróbuj ponownie później.").foregroundColor(.red)}
                        if !areAllFieldsFilled(){
                            Button(action: {showAlert.toggle()}){
                                Text("Zarejestruj się").frame(maxWidth: .infinity)
                            }.alert("Niektóre pola są puste! Czy chcesz pominąć wypełnianie?", isPresented: $showAlert){
                                Button("Pomiń", action: CreateUser)
                                Button("Anuluj", role: .cancel){}.keyboardShortcut(.defaultAction)
                            }.buttonStyle(.bordered)
                        }else{
                            Button(action: CreateUser){
                                Text("Zarejestruj się").frame(maxWidth: .infinity)
                            }.buttonStyle(.borderedProminent)
                        }
                        
                        Button(action: {viewModel.switchFlow(f: .login)}){
                            Text("Powrót").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                    }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                }.padding()
            }
        }
    }
    
    func CreateUser(){
        print(viewModel.haslo)
        Task{
            if await viewModel.SignUp() == true{
                print("Zarejestrowano pomyslnie")
            }else{
                blad = true
            }
        }
    }
    
    func areAllFieldsFilled() -> Bool{
        return !viewModel.first_name.isEmpty && !viewModel.last_name.isEmpty && !viewModel.illness.isEmpty
    }
}

struct Signup2View_Previews: PreviewProvider {
    static var previews: some View {
        Signup2View().environmentObject(AuthenticationViewModel())
    }
}
