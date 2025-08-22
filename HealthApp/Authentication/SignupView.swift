//
//  SignupView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 07/10/2023.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @State private var passwordConfirm = ""
    
    
    var body: some View {
        ZStack{
            Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fit).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
            ScrollView{
                VStack{
                    VStack{
                        Text("Rejestracja").foregroundColor(.cyan).font(.largeTitle).padding(.bottom, 40)
                        VStack(alignment: .leading){
                            Group{
                                Text("Adres email*:")
                                TextField("Email", text: $viewModel.email).textFieldStyle(TFTextStyle())
                                Text(viewModel.conformEmailPrompt).foregroundColor(.red)
                                Text("Nazwa użytkownika")
                                TextField("Nazwa użytkownika", text: $viewModel.username).textFieldStyle(TFTextStyle())
                                Text(viewModel.conformUserNamePropmpt).foregroundColor(.red)
                            }
                            Text("Hasło*:").padding(.top, 20)
                            SecureField("Hasło", text: $viewModel.haslo).textFieldStyle(TFTextStyle())
                            Text(viewModel.conformPwPrompt).foregroundColor(.red)
                            SecureField("Powtórz hasło", text: $viewModel.confirmPassword).textFieldStyle(TFTextStyle())
                            Text(viewModel.conformPwConPrompt).foregroundColor(.red)
                        }
                        HStack{
                            Text("Wybierz lek którego używasz: ")
                            Spacer()
                            Picker("Wybierz lek którego używasz", selection: $viewModel.medication){
                                ForEach(Medication.allCases){ m in
                                    Text(m.rawValue).tag(m)
                                }
                            }.pickerStyle(.menu)
                        }.padding([.top, .bottom], 30)
                        Button(action: {viewModel.switchFlow(f: .signup2)}){
                            Text("Kontynuuj").frame(maxWidth: .infinity)
                        }.disabled(!viewModel.canContinue).buttonStyle(.borderedProminent).padding(.bottom, 10)
                        Button(action: { viewModel.switchFlow(f: .login) }){
                            Text("Powrót").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                    }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                }.padding()
            }
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView().environmentObject(AuthenticationViewModel())
    }
}
