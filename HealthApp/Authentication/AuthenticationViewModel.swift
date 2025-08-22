//
//  AuthenticationViewModel.swift
//  HealthApp
//
//  Created by Jakub Frąk on 10/10/2023.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import GoogleSignInSwift
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

enum AuthState{
    case unatuh
    case authing
    case authed
}

enum AuthenticationFlow{
    case login
    case signup
    case signup2
    case passwordReset
}

enum Medication: String, CaseIterable, Identifiable{
    case Warfin
    case Sintrom
    
    var id: Self {self}
}

enum genders: String, Codable, CaseIterable, Identifiable{
    case male, female, ratherNotSay
    var id: Self {self}
    
    var description: String{
        switch self{
        case .male: return "Mężczyzna"
        case .female: return "Kobieta"
        case .ratherNotSay: return "Wolę nie podawać"
        }
    }
}

enum countries: String, Codable, CaseIterable, Identifiable{
    case pl, gb, us, aus, cd, nz, ratherNotSay
    var id: Self {self}
    
    var description: String{
        switch self{
        case .pl: return "Polska"
        case .gb: return "Wielka Brytania"
        case .us: return "Stany Zjednoczone"
        case .aus: return "Australia"
        case .cd: return "Kanada"
        case .nz: return "Nowa Zelandia"
        case .ratherNotSay: return "Wolę nie podawać"
        }
    }
    
    var image: String{
        switch self{
        case .pl: return "🇵🇱"
        case .gb: return "🇬🇧"
        case .us: return "🇺🇸"
        case .aus: return "🇦🇺"
        case .cd: return "🇨🇦"
        case .nz: return "🇳🇿"
        case .ratherNotSay: return ""
        }
    }
}

@MainActor class AuthenticationViewModel: ObservableObject{
    @Published var email = ""
    @Published var haslo = ""
    @Published var confirmPassword = ""
    @Published var role = ""
    @Published var first_name = ""
    @Published var last_name = ""
    @Published var country: countries = .ratherNotSay
    @Published var gender: genders = .ratherNotSay
    @Published var username = ""
    @Published var medication: Medication = .Warfin
    @Published var illness = ""
    @Published var regDate = Date()
    @Published var readAccess: [String] = []
    @Published var pendingReadAccess: [String] = []
    @Published var GivenReadAccessBy: [String] = []
    @Published var otherUserProfile: [(id: String, firstName: String, lastName: String, userName: String, ctry: countries)] = []
    @Published private var errorMsg = ""
    
    @Published var firstNameOtherUser = ""
    @Published var lastNameOtherUser = ""
    @Published var countryOtherUser: countries = .ratherNotSay
    @Published var genderOtherUser: genders = .ratherNotSay
    @Published var otherUsername = ""
    @Published var medicationOtherUser: Medication = .Warfin
    @Published var illnessOhterUser = ""
    @Published var regDateOtherUser = Date()
    
    @Published var sentReadRequest = false
    @Published var isEmailValid = false
    @Published var isPasswordValid = false
    @Published var isPasswordConfirmValid = false
    @Published var isPasswordEmpty = false
    @Published var isUserNameEmpty = false
    @Published var canContinue = false
    @Published var canLogin = false
    private var cancellables: Set<AnyCancellable> = []
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])")
    let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$")
    
    @Published var flow: AuthenticationFlow = .login
    @Published var astate: AuthState = .unatuh
    
    @Published var user: User?
    @Published var displayName = "test"
    
    @Published var PreviewUserID = ""
    @Published var PreviewMode = false
    
    private var db = Firestore.firestore()
    private var currentNonce: String?
    
    init(){
        self.astate = .authing
        registerAuthStateHandler()
        
        $email.map{email in
            return self.emailPredicate.evaluate(with: email)
        }.assign(to: \.isEmailValid, on: self).store(in: &cancellables)
        $haslo.map{password in
            return self.passwordPredicate.evaluate(with: password)
        }.assign(to: \.isPasswordValid, on: self).store(in: &cancellables)
        $haslo.map{password in
            return password.isEmpty
        }.assign(to: \.isPasswordEmpty, on: self).store(in: &cancellables)
        $username.map{username in
            return username.isEmpty
        }.assign(to: \.isUserNameEmpty, on: self).store(in: &cancellables)
        Publishers.CombineLatest($haslo, $confirmPassword).map{ haslo, confirmPassword in
            return haslo == confirmPassword
        }.assign(to: \.isPasswordConfirmValid, on: self).store(in: &cancellables)
        Publishers.CombineLatest4($isEmailValid, $isPasswordValid, $isPasswordConfirmValid, $isUserNameEmpty).map{ isEmailValid, isPasswordValid, isPasswordConfirmValid, isUsernameEmpty in
            return (isEmailValid && isPasswordValid && isPasswordConfirmValid && !isUsernameEmpty)
        }.assign(to: \.canContinue, on: self).store(in: &cancellables)
        Publishers.CombineLatest($isEmailValid, $isPasswordEmpty).map{ isEmailValid, isPasswordEmpty in
            return (isEmailValid && !isPasswordEmpty)
        }.assign(to: \.canLogin, on: self).store(in: &cancellables)
    }
    
    var conformPwPrompt: String{
        isPasswordValid ? "" : "Hasło musi mieć przynajmniej 8 znaków i posiadać przynamniej 1 literę oraz cyfrę"
    }
    var conformPwEmptyPrompt: String{
        isPasswordEmpty ? "Pole nie może być puste" : ""
    }
    var conformEmailPrompt: String{
        isEmailValid ? "" : "Proszę wpisać poprawny adres email"
    }
    var conformPwConPrompt: String{
        isPasswordConfirmValid ? "" : "Powtórzone hasło musi być takie same"
    }
    var conformUserNamePropmpt: String{
        isUserNameEmpty ? "Pole nie może być puste" : ""
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    func registerAuthStateHandler(){
        if authStateHandler == nil{
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                self.astate = user == nil ? .unatuh : .authed
                self.displayName = user?.email ?? "Blad pobieranie nazwy maila"
                if self.astate == .authed{
                    self.retrieveUserData()
                }
                self.PreviewUserID = user?.uid ?? ""
            }
        }
    }
    
    func switchFlow(f: AuthenticationFlow){
        if(f == AuthenticationFlow.login){
            self.email = ""
            self.haslo = ""
            self.confirmPassword = ""
            self.first_name = ""
            self.last_name = ""
            self.country = .ratherNotSay
            self.gender = .ratherNotSay
            self.username = ""
            self.medication = .Warfin
            self.illness = ""
        }
        self.flow = f
        errorMsg = ""
    }
}
//Logowanie
extension AuthenticationViewModel{
    func SignIn() async -> Bool{
        astate = .authing
        do{
            print("\(self.email), \(self.haslo)")
            let authResult = try await Auth.auth().signIn(withEmail: self.email, password: self.haslo)
            self.user = authResult.user
            displayName = user?.email ?? "Blad wczytywania emaila"
            return true
        }catch{
            astate = .unatuh
            print(error)
            self.errorMsg = error.localizedDescription
            return false
        }
    }
    
    func SignUp() async -> Bool{
        astate = .authing
        let emptyArray: [String] = []
        do{
            try await Auth.auth().createUser(withEmail: email, password: haslo)
            try await db.collection("Users").document(user!.uid).setData([
                "Role": "patient",
                "country": self.country.rawValue,
                "first_name": self.first_name,
                "gender": self.gender.rawValue,
                "last_name": self.last_name,
                "registration_date": regDate,
                "username": self.username,
                "medication": medication.rawValue,
                "illness": self.illness,
                "readAccess": emptyArray,
                "pendingReadAccess": emptyArray,
                "GivenReadAccessBy": emptyArray,
                "sentAccessRequestTo": emptyArray
            ])
            switch medication{
            case .Warfin:
                try db.collection("Users").document(user!.uid).collection("Medications").document("Warfin").setData(from: Lek(name: "Warfin", form: .tabletka, plans: [week_plan(dose: 0.25, time: "17:30", days_of_week: [1,2,3,4,5,6,7])], unit: .mg))
                try await db.collection("Users").document(user!.uid).collection("Medications").document("Warfin").collection("MedicineTaken").document().setData([
                    "date": Date(),
                    "isTaken": false
                ])
            case .Sintrom:
                try db.collection("Users").document(user!.uid).collection("Medications").document("Sintrom").setData(from: Lek(name: "Sintrom", form: .tabletka, plans: [week_plan(dose: 0.25, time: "17:30", days_of_week: [1,2,3,4,5,6,7])], unit: .mg))
                try await db.collection("Users").document(user!.uid).collection("Medications").document("Sintrom").collection("MedicineTaken").document().setData([
                    "date": Date(),
                    "isTaken": false
                ])
            }
            return true
        }catch{
            print(error)
            self.errorMsg = error.localizedDescription
            astate = .unatuh
            return false
        }
    }
    
    func SignOut(){
        do{
            try Auth.auth().signOut()
        }catch{
            print(error)
            self.errorMsg = error.localizedDescription
        }
    }
    
    func sendPasswordResetEmail(){
        Auth.auth().sendPasswordReset(withEmail: email){error in
            print(error?.localizedDescription ?? "")
        }
    }
    
    func retrieveUserData(){
        Task{
            do{
                let docRef = try await db.collection("Users").document(self.user!.uid).getDocument()
                self.first_name = docRef.get("first_name") as? String ?? ""
                self.last_name = docRef.get("last_name") as? String ?? ""
                self.username = docRef.get("username") as? String ?? ""
                self.role = docRef.get("Role") as? String ?? "patient"
                self.gender = genders(rawValue: docRef.get("gender") as! String) ?? .ratherNotSay
                self.illness = docRef.get("illness") as? String ?? ""
                self.country = countries(rawValue: docRef.get("country") as! String) ?? .ratherNotSay
                self.medication = Medication(rawValue: docRef.get("medication") as! String) ?? .Warfin
                let regDateTS = docRef.get("registration_date") as? Timestamp ?? .init()
                self.regDate = regDateTS.dateValue()
                self.readAccess = docRef.get("readAccess") as? [String] ?? []
                self.pendingReadAccess = docRef.get("pendingReadAccess") as? [String] ?? []
                self.GivenReadAccessBy = docRef.get("GivenReadAccessBy") as? [String] ?? []
            }
            catch{
                print(error.localizedDescription)
            }
        }
        db.collection("Users").document(self.user!.uid).addSnapshotListener{ querySnapshot, error in
            do{
                if let pendingReadAccess = querySnapshot?.get("pendingReadAccess") as? [String]{
                    //print("Assigning pending read access \(pendingReadAccess)")
                    self.pendingReadAccess = pendingReadAccess
                }
            }
        }
        db.collection("Users").document(self.user!.uid).addSnapshotListener{ querySnapshot, error in
            do{
                if let givenreadaccess = querySnapshot?.get("GivenReadAccessBy") as? [String]{
                    //print("Assigning given read access \(givenreadaccess)")
                    self.GivenReadAccessBy = givenreadaccess
                }
            }
        }
    }
    
    func retrieveOtherUserData(userId: String){
        Task{
            do{
                let docRef = try await db.collection("Users").document(userId).getDocument()
                self.firstNameOtherUser = docRef.get("first_name") as? String ?? ""
                self.lastNameOtherUser = docRef.get("last_name") as? String ?? ""
                self.otherUsername = docRef.get("username") as? String ?? ""
                self.genderOtherUser = genders(rawValue: docRef.get("gender") as! String) ?? .ratherNotSay
                self.illnessOhterUser = docRef.get("illness") as? String ?? ""
                self.countryOtherUser = countries(rawValue: docRef.get("country") as! String) ?? .ratherNotSay
                self.medicationOtherUser = docRef.get("medication") as? Medication ?? .Warfin
                let regDateTS = docRef.get("registration_date") as? Timestamp ?? .init()
                self.regDateOtherUser = regDateTS.dateValue()
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }
    
    func getAccessUsersProfiles(){
        Task{
            for userId in pendingReadAccess{
                do{
                    let docRef = try await db.collection("Users").document(userId).getDocument()
                    let firstName = docRef.get("first_name") as? String ?? ""
                    let lastName = docRef.get("last_name") as? String ?? ""
                    let userName = docRef.get("username") as? String ?? ""
                    let country = countries(rawValue: docRef.get("country") as! String) ?? .ratherNotSay
                    await MainActor.run{
                        self.otherUserProfile.append((id: userId, firstName: firstName, lastName: lastName, userName: userName, ctry: country))
                    }
                }catch{
                    print("pendingReadAccess: " + error.localizedDescription)
                }
            }
            for userId in readAccess{
                do{
                    let docRef = try await db.collection("Users").document(userId).getDocument()
                    let firstName = docRef.get("first_name") as? String ?? ""
                    let lastName = docRef.get("last_name") as? String ?? ""
                    let userName = docRef.get("username") as? String ?? ""
                    let country = countries(rawValue: docRef.get("country") as! String) ?? .ratherNotSay
                    await MainActor.run{
                        self.otherUserProfile.append((id: userId, firstName: firstName, lastName: lastName, userName: userName, ctry: country))
                    }
                }catch{
                    print("readAccess: " + error.localizedDescription)
                }
            }
            for userId in GivenReadAccessBy{
                do{
                    let docRef = try await db.collection("Users").document(userId).getDocument()
                    let firstName = docRef.get("first_name") as? String ?? ""
                    let lastName = docRef.get("last_name") as? String ?? ""
                    let userName = docRef.get("username") as? String ?? ""
                    let country = countries(rawValue: docRef.get("country") as! String) ?? .ratherNotSay
                    await MainActor.run{
                        self.otherUserProfile.append((id: userId, firstName: firstName, lastName: lastName, userName: userName, ctry: country))
                    }
                }catch{
                    print("givenReadAccessBy: " + error.localizedDescription)
                }
            }
        }
    }
    
    func updateUserData(){
        db.collection("Users").document(user!.uid).setData([
            "country": self.country.rawValue,
            "first_name": self.first_name,
            "gender": self.gender.rawValue,
            "last_name": self.last_name,
            "username": self.username,
            "medication": medication.rawValue,
            "illness": self.illness
        ], merge: true)
    }
    
    func updateUserDataField(field: String, value: String){
        db.collection("Users").document(user!.uid).setData([
            field: value
        ], merge: true)
    }
    
    func sendReadAccessRequest(userId: String){
        if(!self.GivenReadAccessBy.contains(userId)){
            db.collection("Users").document(userId).updateData([
                "pendingReadAccess": FieldValue.arrayUnion([user!.uid])
            ])
            db.collection("Users").document(user!.uid).updateData([
                "sentAccessRequestTo": FieldValue.arrayUnion([userId])
            ])
        }
    }
    func removePendingAccessRequest(userId: String){
        db.collection("Users").document(user!.uid).updateData([
            "pendingReadAccess": FieldValue.arrayRemove([userId])
        ])
        db.collection("Users").document(userId).updateData([
            "sentAccessRequestTo": FieldValue.arrayRemove([userId])
        ])
        pendingReadAccess.removeAll(where: {$0 == userId})
    }
    func acceptReadAccessRequest(userId: String){
        db.collection("Users").document(user!.uid).updateData([
            "readAccess": FieldValue.arrayUnion([userId])
        ])
        db.collection("Users").document(user!.uid).updateData([
            "pendingReadAccess": FieldValue.arrayRemove([userId])
        ])
        db.collection("Users").document(userId).updateData([
            "GivenReadAccessBy": FieldValue.arrayUnion([user!.uid])
        ])
        db.collection("Users").document(userId).updateData([
            "sentAccessRequestTo": FieldValue.arrayRemove([user!.uid])
        ])
        readAccess.append(userId)
        pendingReadAccess.removeAll(where: {$0 == userId})
    }
    func removeReadAccess(userId: String){
        db.collection("Users").document(user!.uid).updateData([
            "readAccess": FieldValue.arrayRemove([userId])
        ])
        db.collection("Users").document(userId).updateData([
            "GivenReadAccessBy": FieldValue.arrayRemove([user!.uid])
        ])
        readAccess.removeAll(where: {$0 == userId})
    }
    
    func switchToOtherUser(userId: String){
        self.PreviewUserID = userId
        self.PreviewMode = true
    }
    func switchBackToUser(){
        self.PreviewMode = false
        self.PreviewUserID = user!.uid
    }
    
    func changeMedication(med: String){
        
    }
}

//Logowanie z Apple
extension AuthenticationViewModel{
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest){
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
    }
    
    func signInWithAppleCompletion(_ result: Result<ASAuthorization, Error>){
        if case .failure(let failure) = result {
            errorMsg = failure.localizedDescription
        }else if case .success(let success) = result {
            if let appleIDCredential = success.credential as? ASAuthorizationAppleIDCredential{
                guard let nonce = currentNonce else {
                    fatalError("Otrzymano login callback ale nie wysłano prośby o zalaogowanie.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Nie udalo sie uzyskac tokena tozsamosci")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else{
                    print("Nie udalo sie zserializowac string z danych tokena: \(appleIDToken.debugDescription)")
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
                
                Task{
                    do{
                        let result = try await Auth.auth().signIn(with: credential)
                        await updateDisplayName(for: result.user, with: appleIDCredential)
                    }catch{
                        print("Error przy autentykacji: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func updateDisplayName(for user: User, with appleIDCredential: ASAuthorizationAppleIDCredential, force: Bool = false) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user is non-empty, don't overwrite it
        }
        else {
            let changeRequest = user.createProfileChangeRequest()
            let Name = "\(appleIDCredential.fullName?.givenName ?? "ImieERR") \(appleIDCredential.fullName?.familyName ?? "NazwERR")"
            changeRequest.displayName = Name
            do {
                try await changeRequest.commitChanges()
                self.displayName = Auth.auth().currentUser?.displayName ?? ""
            }
            catch {
                print("Unable to update the user's displayname: \(error.localizedDescription)")
                errorMsg = error.localizedDescription
            }
        }
    }
    
    func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                do {
                    let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                    switch credentialState {
                    case .authorized:
                        break // The Apple ID credential is valid.
                    case .revoked, .notFound:
                        // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                        self.SignOut()
                    default:
                        break
                    }
                }
                catch {}
            }
        }
    }
}

enum AuthenticationError: Error {
  case tokenError(message: String)
}

//Logowanie z Google
extension AuthenticationViewModel{
    func signInWithGoogle() async -> Bool{
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("No client ID found in Firebase configuration")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Brak root view controller")
            return false
        }
        do{
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = userAuthentication.user
            guard let idToken = user.idToken else {
                throw AuthenticationError.tokenError(message: "Brak tokenu ID")
            }
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
            let result = try await Auth.auth().signIn(with: credential)
            let emptyArray: [String] = []
            if(result.additionalUserInfo?.isNewUser ?? false){
                try await db.collection("Users").document(self.user!.uid).setData([
                    "Role": "patient",
                    "country": self.country.rawValue,
                    "first_name": self.first_name,
                    "gender": self.gender.rawValue,
                    "last_name": self.last_name,
                    "registration_date": regDate,
                    "username": result.additionalUserInfo!.profile!["email"] as! String,
                    "medication": medication.rawValue,
                    "illness": self.illness,
                    "readAccess": emptyArray,
                    "pendingReadAccess": emptyArray,
                    "GivenReadAccessBy": emptyArray,
                    "sentAccessRequestTo": emptyArray
                ])
                switch medication{
                case .Warfin:
                    try db.collection("Users").document(self.user!.uid).collection("Medications").document("Warfin").setData(from: Lek(name: "Warfin", form: .tabletka, plans: [week_plan(dose: 0.25, time: "17:30", days_of_week: [1,2,3,4,5,6,7])], unit: .mg))
                    try await db.collection("Users").document(self.user!.uid).collection("Medications").document("Warfin").collection("MedicineTaken").document().setData([
                        "date": Date(),
                        "isTaken": false
                    ])
                case .Sintrom:
                    try db.collection("Users").document(self.user!.uid).collection("Medications").document("Sintrom").setData(from: Lek(name: "Sintrom", form: .tabletka, plans: [week_plan(dose: 0.25, time: "17:30", days_of_week: [1,2,3,4,5,6,7])], unit: .mg))
                    try await db.collection("Users").document(self.user!.uid).collection("Medications").document("Sintrom").collection("MedicineTaken").document().setData([
                        "date": Date(),
                        "isTaken": false
                    ])
                }
            }
            return true
        }
        catch{
            print(error.localizedDescription)
            errorMsg = error.localizedDescription
            return false
        }
    }
}

private func randomNonceString(length: Int = 32) -> String {
  precondition(length > 0)
  let charset: [Character] =
  Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  var result = ""
  var remainingLength = length

  while remainingLength > 0 {
    let randoms: [UInt8] = (0 ..< 16).map { _ in
      var random: UInt8 = 0
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }
      return random
    }

    randoms.forEach { random in
      if remainingLength == 0 {
        return
      }

      if random < charset.count {
        result.append(charset[Int(random)])
        remainingLength -= 1
      }
    }
  }

  return result
}

private func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashedData = SHA256.hash(data: inputData)
  let hashString = hashedData.compactMap {
    String(format: "%02x", $0)
  }.joined()

  return hashString
}
