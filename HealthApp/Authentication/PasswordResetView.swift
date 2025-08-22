//
//  PasswordResetView.swift
//  CardioGo
//
//  Created by Jakub Frąk on 02/01/2024.
//

import SwiftUI

struct PasswordResetView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    
    var body: some View {
        ZStack{
            Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fit).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
            VStack{
                VStack{
                    Text("Resetowanie hasła").foregroundColor(.cyan).font(.largeTitle).padding(.bottom, 40)
                    VStack(alignment: .leading){
                        Text("Adres email:").font(.title3)
                        TextField("Email", text: $viewModel.email).padding(.leading, 10).autocapitalization(.none).autocorrectionDisabled().frame(height: self.dynamicTypeSize.isAccessibilitySize ? 80 : 40).background(Color(.secondarySystemBackground)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2))
                        Text(viewModel.conformEmailPrompt).foregroundColor(.red)
                    }
                    Button(action: {viewModel.sendPasswordResetEmail()}){
                        Text("Wyślij email").frame(maxWidth: .infinity)
                    }.disabled(!viewModel.isEmailValid).buttonStyle(.borderedProminent).padding(.top, 20)
                    Button(action: {
                        viewModel.switchFlow(f: .login)
                    }, label: {
                        Text("Anuluj").frame(maxWidth: .infinity)
                    }).buttonStyle(.bordered)
                    //if(blad){Text("Błąd logowania spróbuj ponownie później").foregroundColor(.red)}
                }.padding().background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)).shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
            }.padding()
        }
    }
}

struct PasswordResetView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordResetView()
    }
}
