//
//  HealthAppApp.swift
//  HealthApp
//
//  Created by Jakub Frąk on 26/09/2023.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      //Auth.auth().useEmulator(withHost: "localhost", port: 9099)
    return true
  }
}

@main
struct HealthAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            NavigationView {
                AuthenticationView()
            }
        }
    }
}
