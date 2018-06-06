//
//  LoginViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 26/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import GoogleSignIn
import MBProgressHUD
import PromiseKit

class LoginViewController: UIViewController {

    // MARK: Variables
    var actionAfterLogin: ((Bool) -> Void)?
    
    // MARK: Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: Actions
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: {
            if let actionAfterLogin = self.actionAfterLogin {
                actionAfterLogin(false)
            }
        })
    }

    @IBAction func loginAction(_ sender: UIButton) {
        let email = usernameTextField.text
        let password = passwordTextField.text
        
        if let email = email,
            let password = password {
            
            var errors = [String]()
            for error in validate(email: email) {
                errors.append(error)
            }
            for error in validate(password: password) {
                errors.append(error)
            }
            
            if errors.count > 0 {
                showMessage(title: "Error", message: errors.joined(separator: "\n"))
            } else {
                MBProgressHUD.showAdded(to: self.view, animated: true)
                
                firstly {
                    authSignIn(with: email, password: password)
                    }.then { (authResult: AuthDataResult?) in
                    self.updateUser(email: authResult?.user.email, photoURL: authResult?.user.photoURL, displayName: authResult?.user.displayName)
                }.done {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    
                    self.dismiss(animated: true, completion: {
                        if let actionAfterLogin = self.actionAfterLogin {
                            actionAfterLogin(true)
                        }
                    })
                }.catch { error in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.showMessage(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func forgotPasswordAction(_ sender: UIButton) {
        let title = "Retrieve Password"
        let alertController = UIAlertController(title: title, message: "We will send instructions to the email below on how to retrive your password.", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let fields = alertController.textFields {
                let email = fields[0].text
                
                var errors = [String]()
                for error in self.validate(email: email!) {
                    errors.append(error)
                }

                if errors.count > 0 {
                    self.showMessage(title: "Error", message: errors.joined(separator: "\n"))
                } else {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    
                    firstly {
                        self.authSetPasswordReset(email: email!)
                    }.done {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.showMessage(title: "Success", message: "Check the email you provided for instructions.")
                    }.catch { error in
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.showMessage(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Email"
        }
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func signupAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Sign Up", message: nil, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let fields = alertController.textFields {
                let name = fields[0].text
                let email = fields[1].text
                let password = fields[2].text
                
                var errors = [String]()
                for error in self.validate(name: name!) {
                    errors.append(error)
                }
                for error in self.validate(email: email!) {
                    errors.append(error)
                }
                for error in self.validate(password: password!) {
                    errors.append(error)
                }
                
                if errors.count > 0 {
                    self.showMessage(title: "Error", message: errors.joined(separator: "\n"))
                } else {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    
                    firstly {
                        self.authCreateUser(email: email!, password: password!)
                    }.then { (authResult: AuthDataResult?) in
                        self.updateUser(email: authResult?.user.email, photoURL: authResult?.user.photoURL, displayName: name!)
                    }.done {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        
                        self.dismiss(animated: true, completion: {
                            if let actionAfterLogin = self.actionAfterLogin {
                                actionAfterLogin(true)
                            }
                        })
                    }.catch { error in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.showMessage(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Name"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Email"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func facebookAction(_ sender: UIButton) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        firstly {
            self.facebookLogin()
        }.then { (credential: AuthCredential) in
            self.authSignInandRetrieveData(credential: credential)
        }.then { (authResult: AuthDataResult?) in
            self.updateUser(email: authResult?.user.email, photoURL: authResult?.user.photoURL, displayName: authResult?.user.displayName)
        }.done {
            MBProgressHUD.hide(for: self.view, animated: true)
            
            self.dismiss(animated: true, completion: {
                if let actionAfterLogin = self.actionAfterLogin {
                    actionAfterLogin(true)
                }
            })
        }.catch { error in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.showMessage(title: "Error", message: error.localizedDescription)
        }
    }
    
    @IBAction func googleAction(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }


    // MARK: Custom methods
    func showMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
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
    
    func updateUser(email: String?, photoURL: URL?, displayName: String?, completion: @escaping (_ error: Error?) -> Void) {
        FirebaseManager.sharedInstance.updateUser(email: email, photoURL: photoURL, displayName: displayName, completion: completion)
        FirebaseManager.sharedInstance.monitorUser()
    }
    
    // MARK: Promises
    func authSignIn(with email: String, password: String) -> Promise<AuthDataResult?> {
        return Promise { seal  in
            Auth.auth().signIn(withEmail: email, password: password,  completion: {(authResult: AuthDataResult?, error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(authResult)
                }
            })
        }
    }
    
    func authSetPasswordReset(email: String) -> Promise<Void> {
        return Promise { seal  in
            Auth.auth().sendPasswordReset(withEmail: email, completion: { error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill()
                }
            })
        }
    }
    
    func authCreateUser(email: String, password: String) -> Promise<AuthDataResult?> {
        return Promise { seal  in
            Auth.auth().createUser(withEmail: email, password: password,  completion: {(authResult: AuthDataResult?, error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(authResult)
                }
            })
        }
    }
    
    func authSignInandRetrieveData(credential: AuthCredential) -> Promise<AuthDataResult?> {
        return Promise { seal  in
            Auth.auth().signInAndRetrieveData(with: credential, completion: {(authResult: AuthDataResult?, error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(authResult)
                }
            })
        }
    }
    
    func facebookLogin() -> Promise<AuthCredential> {
        return Promise { seal in
            let login = FBSDKLoginManager()
            
            login.logIn(withReadPermissions: ["public_profile"], from: self, handler: {(result: FBSDKLoginManagerLoginResult?, error: Error?) in
                if let error = error {
                    seal.reject(error)
                } else {
                    let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                    seal.fulfill(credential)
                }
                
            })
        }
    }
    
    func updateUser(email: String?, photoURL: URL?, displayName: String?) -> Promise<Void> {
        return Promise { seal in
            FirebaseManager.sharedInstance.updateUser(email: email, photoURL: photoURL, displayName: displayName, completion: {(error: Error?) in
                if let error = error {
                    FirebaseManager.sharedInstance.demonitorUser()
                    seal.reject(error)
                } else {
                    FirebaseManager.sharedInstance.monitorUser()
                    seal.fulfill()
                }
                
            })
        }
    }
}

// MARK: GIDSignInDelegate
extension LoginViewController : GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            self.showMessage(title: "Error", message: error.localizedDescription)
        } else {
            
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                           accessToken: authentication.accessToken)
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            firstly {
                self.authSignInandRetrieveData(credential: credential)
            }.then { (authResult: AuthDataResult?) in
                self.updateUser(email: authResult?.user.email, photoURL: authResult?.user.photoURL, displayName: authResult?.user.displayName)
            }.done {
                MBProgressHUD.hide(for: self.view, animated: true)
                
                self.dismiss(animated: true, completion: {
                    if let actionAfterLogin = self.actionAfterLogin {
                        actionAfterLogin(true)
                    }
                })
            }.catch { error in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.showMessage(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}

// MARK: GIDSignInUIDelegate
extension LoginViewController : GIDSignInUIDelegate {
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
//        myActivityIndicator.stopAnimating()
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
//        sleep(1) // to fix blank white screen where Google SignIn view is not loaded
        present(viewController, animated: true, completion: nil)
    }


    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

