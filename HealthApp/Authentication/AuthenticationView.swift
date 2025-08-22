//
//  AuthenticationView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 10/10/2023.
//

import SwiftUI

struct TFNumberStyle: TextFieldStyle{
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    func _body(configuration: TextField<Self._Label>) -> some View{
        configuration.keyboardType(.numberPad).padding(.leading, 10).autocapitalization(.none).autocorrectionDisabled().frame(height: self.dynamicTypeSize.isAccessibilitySize ? 80 : 40).background(Color(.secondarySystemBackground)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2))
    }
}

struct TFTextStyle: TextFieldStyle{
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    func _body(configuration: TextField<Self._Label>) -> some View{
        configuration.padding(.leading, 10).autocapitalization(.none).autocorrectionDisabled().frame(height: self.dynamicTypeSize.isAccessibilitySize ? 80 : 40).background(Color(.secondarySystemBackground)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2))
    }
}

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack{
            switch viewModel.astate{
            case .unatuh:
                switch viewModel.flow{
                case .login:
                    LoginView().environmentObject(viewModel)
                case .signup:
                    SignupView().environmentObject(viewModel)
                case .signup2:
                    Signup2View().environmentObject(viewModel)
                case .passwordReset:
                    PasswordResetView().environmentObject(viewModel)
                }
            case .authing:
                ZStack{
                    Image(colorScheme == .dark ? "BackgroundDark" : "Background").resizable().aspectRatio(contentMode: .fill).frame(maxWidth: .infinity).edgesIgnoringSafeArea(.all)
                    VStack{
                        Image(uiImage: UIImage(named: colorScheme == .dark ? "CardioGoIconDark" : "AppIcon") ?? UIImage()).interpolation(.none).resizable().frame(width: 300, height: 300)
                        ProgressView().controlSize(.large)
                    }
                }
            case .authed:
                ContentView().environmentObject(self.viewModel)
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
