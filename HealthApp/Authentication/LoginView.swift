//
//  LoginView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 07/10/2023.
//

import SwiftUI
import GoogleSignInSwift
import _AuthenticationServices_SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var viewModel: AuthenticationViewModel
    
    @State private var blad = false
    @State private var GoogleBlad = false
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        ZStack{
            Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fit).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
            ScrollView{
                VStack{
                    VStack{
                        Text("Logowanie").foregroundColor(.cyan).font(.largeTitle).padding(.bottom, 40)
                        VStack(alignment: .leading){
                            Text("Adres email:").font(.title3)
                            TextField("Email", text: $viewModel.email).textFieldStyle(TFTextStyle())
                            Text(viewModel.conformEmailPrompt).foregroundColor(.red)
                            Text("Hasło:").font(.title3).padding(.top, 20)
                            SecureField("Hasło", text: $viewModel.haslo).textFieldStyle(TFTextStyle())
                            Text(viewModel.conformPwEmptyPrompt).foregroundColor(.red)
                        }
                        Button{
                            viewModel.switchFlow(f: .passwordReset)
                        } label: {
                            Text("Nie pamiętasz hasła?").frame(maxWidth: .infinity)
                        }
                        Button(action: CheckUser){
                            Text("Zaloguj").frame(maxWidth: .infinity)
                        }.disabled(!viewModel.canLogin).buttonStyle(.borderedProminent).padding(.top, 20)
                        if(blad){Text("Błąd logowania spróbuj ponownie później").foregroundColor(.red)}
                        Button(action: { viewModel.switchFlow(f: .signup) }){
                            Text("Nie masz konta? Zarejestruj się.").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                        //                SignInWithAppleButton{ request in
                        //                    viewModel.handleSignInWithAppleRequest(request)
                        //                } onCompletion: { result in
                        //                    viewModel.signInWithAppleCompletion(result)
                        //                }.frame(maxWidth: .infinity, maxHeight: 50)
                        
//                        Button(action: GoogleSignIn){
//                            Text("Zaloguj się używając Google").frame(maxWidth: .infinity)
//                        }.buttonStyle(.bordered)
                        GoogleSignInButton(action: GoogleSignIn)
                        if(GoogleBlad){Text("Błąd logowania przez Google").foregroundColor(.red)}
                    }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                }.padding()
            }
        }
    }
    
    func CheckUser(){
        Task{
            if await viewModel.SignIn() == true{
                print("Zalogowany pomyslnie")
            }else{
                blad = true
            }
        }
    }
    func GoogleSignIn(){
        Task{
            if await viewModel.signInWithGoogle() == true{
                print("Zalogowano pomyslnie uzywajac Google")
            }
            else{
                GoogleBlad = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(AuthenticationViewModel())
    }
}
