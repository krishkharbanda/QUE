//
//  SignInViewController.swift
//  QUE
//
//  Created by Krish Kharbanda on 11/11/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import CryptoKit
import AuthenticationServices

class SignInViewController: UIViewController {

    @IBOutlet weak var emailFld: UITextField!
    @IBOutlet weak var passwordFld: UITextField!
    
    let db = Firestore.firestore()
    let auth = Auth.auth()
    
    var passwordVisibility: PasswordVisibility = .hidden
    
    let utilities = Utilities()
    let userProfile = UserProfile()
    
    fileprivate var currentNonce: String?
    
    enum PasswordVisibility {
        case hidden
        case visible
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailFld.delegate = self
        passwordFld.delegate = self
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        utilities.presentAlertController(title: "Welcome!", message: "If you have an existing account, please use the provider that you signed up with, and if you are creating an account, feel free to use any provider with an unused email.", action: "Ok", viewController: self)
    }
    
    func signInPart2() {
        self.db.collection("Users").whereField("email", isEqualTo: self.userProfile.email).limit(to: 1).getDocuments { querySnapshot, err in
            if let error = err {
                print(error.localizedDescription)
                return
            }
            if let document = querySnapshot?.documents[0], document.exists {
                if document == document {
                    self.userProfile.name = document.get("name") as! String
                    self.userProfile.docId = document.documentID
                    if let documents = document.get("documents") as? NSArray, let stringDocs = documents as? Array<String> {
                        self.userProfile.documents = stringDocs
                    }
                    self.view.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "SplitVC")
                    self.view.window?.makeKeyAndVisible()
                }
            }
        }
    }
    
    @IBAction func closePressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func continuePressed(_ sender: UIButton) {
        if let email = emailFld.text?.trimmingCharacters(in: .whitespacesAndNewlines), let password = passwordFld.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty, !password.isEmpty {
            if utilities.validate(entry: email, type: .email) && utilities.validate(entry: password, type: .password) {
                self.auth.fetchSignInMethods(forEmail: email) { prov, err in
                    if let error = err {
                        print(error.localizedDescription)
                        if error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines) == "Network error (such as timeout, interrupted connection or unreachable host) has occurred." {
                            self.utilities.presentAlertController(title: "Network Error", message: "A network error has occured. Please check your connectivity and try again.", action: "Ok", viewController: self)
                        } else {
                            self.utilities.presentAlertController(title: "Invalid credentials", message: "The credentials do not match to authenticate the account. Please try again, or click 'Forgot Password?' to reset your password.", action: "Ok", viewController: self)
                        }
                        return
                    }
                    if let providers = prov, !providers.isEmpty {
                        if !providers.contains("email") {
                            self.utilities.presentAlertController(title: "Incorrect account provider", message: "Please make sure you are using the correct account provider.", action: "Ok", viewController: self)
                            return
                        }
                        self.auth.signIn(withEmail: email, password: password) { authResult, err in
                            if let error = err {
                                print(error.localizedDescription)
                                if error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines) == "Network error (such as timeout, interrupted connection or unreachable host) has occurred." {
                                    self.utilities.presentAlertController(title: "Network Error", message: "A network error has occured. Please check your connectivity and try again.", action: "Ok", viewController: self)
                                } else {
                                    self.utilities.presentAlertController(title: "Invalid credentials", message: "The credentials do not match to authenticate the account. Please try again, or click 'Forgot Password?' to reset your password.", action: "Ok", viewController: self)
                                }
                                return
                            }
                            if let result = authResult {
                                self.userProfile.email = email
                                self.userProfile.uid = result.user.uid
                                self.signInPart2()
                            }
                        }
                    } else {
                        let alertController = UIAlertController(title: "Account creation", message: "This email is not linked to an account. Would you like to proceed with account creation?", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                            self.auth.createUser(withEmail: email, password: password) { authResult, err in
                                if let error = err {
                                    print(error.localizedDescription)
                                    return
                                }
                                if let result = authResult {
                                    self.userProfile.email = email
                                    self.userProfile.uid = result.user.uid
                                    let alertCont = UIAlertController(title: "Enter name", message: "Please enter your name in the field below.", preferredStyle: .alert)
                                    alertCont.view.overrideUserInterfaceStyle = .light
                                    var nameFld: UITextField?
                                    alertCont.addTextField { nameField in
                                        nameFld = nameField
                                        nameFld?.overrideUserInterfaceStyle = .light
                                        nameFld?.placeholder = "Name"
                                    }
                                    alertCont.addAction(UIAlertAction(title: "Add to Profile", style: .default, handler: { action in
                                        if let nameField = nameFld {
                                            if let text = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                                                self.userProfile.name = text
                                                self.db.collection("Users").addDocument(data: ["name": text, "email": email, "documents": []]) { err in
                                                    self.db.collection("Users").whereField("email", isEqualTo: email).limit(to: 1).getDocuments { querySnapshot, err in
                                                        if let error = err {
                                                            print(error.localizedDescription)
                                                            return
                                                        }
                                                        if let document = querySnapshot?.documents[0], document.exists {
                                                            if document == document {
                                                                self.userProfile.docId = document.documentID
                                                                self.view.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "SplitVC")
                                                                self.view.window?.makeKeyAndVisible()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }))
                                    alertCont.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                                    self.present(alertCont, animated: true, completion: nil)
                                }
                            }
                        }))
                        alertController.addAction(UIAlertAction(title: "No", style: .cancel))
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            } else {
                utilities.presentAlertController(title: "Invalid fields", message: "Please check to make sure that all fields are properly formatted:\nEmail: @domain.com\nPassword: At least 8 characters, 1 uppercase, 1 number, 1 special character.", action: "Ok", viewController: self)
            }
        } else {
            utilities.presentAlertController(title: "Missing fields", message: "Please check to make sure that all fields are completed.", action: "Ok", viewController: self)
        }
    }
    @IBAction func signInWithApplePressed(_ sender: UIButton) {
        self.startSignInWithAppleFlow()
    }
    @IBAction func signInWithGoogle(_ sender: UIButton) {
        
    }
    
    @IBAction func togglePasswordVisibilityPressed(_ sender: UIButton) {
        let configuration = UIImage.SymbolConfiguration(scale: .small)
        switch passwordVisibility {
        case .hidden:
            passwordVisibility = .visible
            sender.setImage(UIImage(systemName: "eye.fill", withConfiguration: configuration), for: UIControl.State())
            passwordFld.isSecureTextEntry = false
        case .visible:
            passwordVisibility = .hidden
            sender.setImage(UIImage(systemName: "eye.slash.fill", withConfiguration: configuration), for: UIControl.State())
            passwordFld.isSecureTextEntry = true
        }
    }
    @IBAction func forgotPasswordPressed(_ sender: UIButton) {
        if let email = emailFld.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            auth.sendPasswordReset(withEmail: email) { err in
                if let error = err {
                    print(error.localizedDescription)
                    return
                }
                self.utilities.presentAlertController(title: "Success!", message: "Please check your email to find an email with the password reset link.", action: "Ok", viewController: self)
            }
        } else {
            utilities.presentAlertController(title: "Missing email", message: "Please check to make sure that all fields are completed.", action: "Ok", viewController: self)
        }
    }
}
extension SignInViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        var type = String()
        switch textField {
        case self.emailFld:
            type = "email"
        case self.passwordFld:
            type = "password"
        default:
            print("")
        }
        if let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            switch textField {
            case self.emailFld:
                if !self.utilities.validate(entry: text, type: .email){
                    self.utilities.presentAlertController(title: "Invalid email", message: "Please make sure your email is in the correct format (...@domain.com).", action: "Ok", viewController: self)
                }
            case self.passwordFld:
                if !self.utilities.validate(entry: text, type: .password) {
                    self.utilities.presentAlertController(title: "Invalid password", message: "Please make sure your password is in the correct format: (8 characters, 1 uppercase, 1 number, 1 special character).", action: "Ok", viewController: self)
                }
            default:
                print("")
            }
        } else {
            utilities.presentAlertController(title: "Missing \(type)", message: "Please enter your \(type) in the correct format.", action: "Ok", viewController: self)
        }
        textField.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        emailFld.resignFirstResponder()
        passwordFld.resignFirstResponder()
        view.endEditing(true)
    }
}
extension SignInViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
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
    
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            guard let email = appleIDCredential.email else { return }
            var middleName = String()
            if let middle = appleIDCredential.fullName?.middleName, !middle.isEmpty {
                middleName = middle + " "
            }
            guard let firstName = appleIDCredential.fullName?.givenName else { return }
            guard let lastName = appleIDCredential.fullName?.familyName else { return }
            let name = firstName + " " + middleName + lastName
            
            self.auth.fetchSignInMethods(forEmail: email) { prov, err in
                if let error = err {
                    print(error.localizedDescription)
                    return
                }
                if let providers = prov, !providers.isEmpty {
                    if providers.contains("apple.com") {
                        self.appleSignInPart2(with: credential)
                        self.signInPart2()
                    } else {
                        self.utilities.presentAlertController(title: "Incorrect account provider", message: "Please make sure you are using the correct account provider.", action: "Ok", viewController: self)
                        return
                    }
                } else {
                    self.appleSignInPart2(with: credential)
                    self.userProfile.name = name
                    self.db.collection("Users").addDocument(data: ["name": name, "email": email, "documents": []]) { err in
                        self.db.collection("Users").whereField("email", isEqualTo: email).limit(to: 1).getDocuments { querySnapshot, err in
                            if let error = err {
                                print(error.localizedDescription)
                                return
                            }
                            if let document = querySnapshot?.documents[0], document.exists {
                                if document == document {
                                    self.userProfile.docId = document.documentID
                                    self.view.window?.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "SplitVC")
                                    self.view.window?.makeKeyAndVisible()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func appleSignInPart2(with credential: AuthCredential) {
        self.auth.signIn(with: credential) { authResult, err in
            if let error = err {
                print(error.localizedDescription)
                return
            }
            if let result = authResult {
                self.userProfile.uid = result.user.uid
                self.userProfile.email = result.user.email!
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func saveUserInKeychain(_ userIdentifier: String) {
        do {
            try KeychainItem(service: "com.KK-Can-Code.QUE", account: "userIdentifier").saveItem(userIdentifier)
        } catch {
            print("Unable to save userIdentifier to keychain.")
        }
    }
    
    func showPasswordCredentialAlert(username: String, password: String) {
        let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
