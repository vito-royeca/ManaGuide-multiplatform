//
//  LoginViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 11.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import PromiseKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import OAuthSwift

class LoginViewModel: NSObject {
    func updateUser(email: String?,
                    photoURL: URL?,
                    displayName: String?,
                    completion: @escaping (_ error: Error?) -> Void) {
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.photoURL = photoURL
            changeRequest.commitChanges { (error) in
                if let error = error {
                    completion(error)
                } else {
                    let ref = Database.database().reference().child("users").child(user.uid)

                    ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                        var providerData = [String]()
                        for pd in user.providerData {
                            providerData.append(pd.providerID)
                        }

                        if var post = currentData.value as? [String : Any] {
                            post["displayName"] = displayName ?? ""

                            // Set value and report transaction success
                            currentData.value = post
                            return TransactionResult.success(withValue: currentData)

                        } else {
                            ref.setValue(["displayName": displayName ?? ""])
                            return TransactionResult.success(withValue: currentData)
                        }

                    }) { (error, committed, snapshot) in
                        if committed {
                            completion(error)
                        } else {
                            self.updateUser(email: email,
                                            photoURL: photoURL,
                                            displayName: displayName,
                                            completion: completion)
                        }
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
    
    func validate(name: String) -> [String] {
        var errors = [String]()
        
        if name.count < 4 {
            errors.append("Name must be at least 4 characters.")
        }
        
        return errors
    }
    
    func validate(email: String) -> [String] {
        var errors = [String]()
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        
        if email.count == 0 {
            errors.append("Email is empty.")
        } else {
            if !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) {
                errors.append("Invalid email.")
            }
        }
        
        return errors
    }
    
    func validate(password: String) -> [String] {
        var errors = [String]()
        
        if password.count == 0 {
            errors.append("Password is empty.")
        }
        
        return errors
    }
    
    func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let count = UInt32(letters.count)
        
        var randomString = ""
        for _ in 0..<length {
            let rand = arc4random_uniform(count)
            let idx = letters.index(letters.startIndex, offsetBy: Int(rand))
            let letter = letters[idx]
            randomString += String(letter)
        }
        return randomString
    }
    
    // MARK: Promises
    func authSignIn(with email: String, password: String) -> Promise<AuthDataResult?> {
        return Promise { seal  in
            let completion = {(authResult: AuthDataResult?, error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(authResult)
                }
            }
            
            Auth.auth().signIn(withEmail: email,
                               password: password,
                               completion: completion)
        }
    }
    
    func authSetPasswordReset(email: String) -> Promise<Void> {
        return Promise { seal  in
            let completion = { (error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }
            
            Auth.auth().sendPasswordReset(withEmail: email,
                                          completion: completion)
        }
    }
    
    func authCreateUser(email: String, password: String) -> Promise<AuthDataResult?> {
        return Promise { seal  in
            let completion = { (authResult: AuthDataResult?, error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(authResult)
                }
            }
            
            Auth.auth().createUser(withEmail: email,
                                   password: password,
                                   completion: completion)
        }
    }
    
    func authSignInAndRetrieveData(credential: AuthCredential) -> Promise<AuthDataResult?> {
        return Promise { seal  in
            let completion = {(authResult: AuthDataResult?, error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(authResult)
                }
            }
            
            Auth.auth().signInAndRetrieveData(with: credential,
                                              completion: completion)
        }
    }
    
    func facebookLogin(withViewController vc: UIViewController) -> Promise<AuthCredential> {
        return Promise { seal in
            let login = FBSDKLoginManager()
            let handler = { (result: FBSDKLoginManagerLoginResult?, error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    if let result = result {
                        if result.isCancelled {
                            let error = NSError(domain: "400", code: 400, userInfo: [NSLocalizedDescriptionKey: "Login cancelled."])
                            seal.reject(error)
                        } else {
                            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                            seal.fulfill(credential)
                        }
                    }
                }
            }
            
            login.logIn(withReadPermissions: ["public_profile"],
                        from: vc,
                        handler: handler)
        }
    }
    
    func githubLogin(withViewController vc: UIViewController) -> Promise<AuthCredential> {
        return Promise { seal in
            let oauthswift = OAuth2Swift(consumerKey: GitHubSettings.ConsumerKey,
                                         consumerSecret: GitHubSettings.ConsumerSecret,
                                         authorizeUrl: GitHubSettings.AuthorizeUrl,
                                         accessTokenUrl: GitHubSettings.AccessTokenUrl,
                                         responseType: "code")
            let safari = SafariURLHandler(viewController: vc,
                                          oauthSwift: oauthswift)//OAuthSwiftOpenURLExternally.sharedInstance
            let state = generateRandomString(length: 20)
            
//            safari.delegate = vc
            oauthswift.authorizeURLHandler = safari
            
            let _ = oauthswift.authorize(
                withCallbackURL: URL(string: GitHubSettings.CallbackURL)!,
                scope: "user,repo",
                state: state,
                success: { credential, response, parameters in
                    let c = GitHubAuthProvider.credential(withToken: credential.oauthToken)
                    seal.fulfill(c)
                },
                failure: { error in
                    seal.reject(error)
                }
            )
        }
    }
    
    func syncUser(email: String?, photoURL: URL?, displayName: String?) -> Promise<Void> {
        return Promise { seal in
            let completion = { (error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }

            self.updateUser(email: email,
                            photoURL: photoURL,
                            displayName: displayName,
                            completion: completion)
        }
    }
}
