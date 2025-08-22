//
//  ContentView.swift
//  HealthApp
//
//  Created by Jakub Frąk on 26/09/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    
    init(){
        let apparence = UITabBarAppearance()
        apparence.configureWithOpaqueBackground()
        if #available(iOS 15.0, *) {UITabBar.appearance().scrollEdgeAppearance = apparence}
    }
    
    var body: some View {
        if(viewModel.PreviewMode){
            VStack{
                Text("Przeglądasz profil użytkownika " + viewModel.otherUsername)
                Button{
                    viewModel.switchBackToUser()
                }label: {
                    Text("Wróć do swojego profilu").frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent)
            }.padding([.leading, .trailing])
        }
        TabView{
            PomiarView().tabItem{
                Label("Pomiary", systemImage: "timer")
            }.environmentObject(viewModel)
            LekiView().tabItem{
                Label("Zdrowie", systemImage: "heart.fill")
            }.environmentObject(viewModel)
            DietView().tabItem{
                Label("Spożycie", systemImage: "fork.knife")
            }.environmentObject(viewModel)
            UserView().tabItem{
                Label("Uzytkownik", systemImage: "person.circle")
            }.environmentObject(viewModel)
        }.onAppear{
            let apparence = UITabBarAppearance()
            apparence.configureWithOpaqueBackground()
            if #available(iOS 15.0, *) {UITabBar.appearance().scrollEdgeAppearance = apparence}
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AuthenticationViewModel())
    }
}
