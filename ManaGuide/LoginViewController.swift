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

protocol LoginViewControllerDelegate: NSObjectProtocol {
    func actionAfterLogin(success: Bool)
}

class LoginViewController: UIViewController {

    // MARK: Variables
    var delegate: LoginViewControllerDelegate?

    // MARK: Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: Actions
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: {
            if let delegate = self.delegate {
                delegate.actionAfterLogin(success: false)
            }
        })
    }

    @IBAction func loginAction(_ sender: UIButton) {
        let email = usernameTextField.text
        let password = passwordTextField.text
        
        if let email = email,
            let password = password {
            
            var errors = [String]()
            for error in validateEmail(email) {
                errors.append(error)
            }
            for error in validatePassword(password) {
                errors.append(error)
            }
            if errors.count > 0 {
                let alertController = UIAlertController(title: "Error", message: errors.joined(separator: "\n"), preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                
            } else {
                MBProgressHUD.showAdded(to: self.view, animated: true)
                Auth.auth().signIn(withEmail: email, password: password,  completion: {(authResult: AuthDataResult?, error: Error?) in
                    if let error = error {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        
                        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        if let authResult = authResult {
                            self.updateUser(email: authResult.user.email, photoURL: authResult.user.photoURL, displayName: authResult.user.displayName, completion: {(error: Error?) in
                                MBProgressHUD.hide(for: self.view, animated: true)
                                
                                if let error = error {
                                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                    self.present(alertController, animated: true, completion: nil)
                                } else {
                                    self.dismiss(animated: true, completion: {
                                        if let delegate = self.delegate {
                                            delegate.actionAfterLogin(success: true)
                                        }
                                    })
                                }
                            })
                        }
                    }
                })
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
                for error in self.validateEmail(email!) {
                    errors.append(error)
                }
                if errors.count > 0 {
                    let alertController = UIAlertController(title: "Error", message: errors.joined(separator: "\n"), preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    
                } else {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    Auth.auth().sendPasswordReset(withEmail: email!, completion: { error in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        var message:String?
                        
                        if let error = error {
                            message = error.localizedDescription
                        } else {
                            message = "Check the email you provided for instructions."
                        }
                        
                        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    })
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
                for error in self.validateName(name!) {
                    errors.append(error)
                }
                for error in self.validateEmail(email!) {
                    errors.append(error)
                }
                for error in self.validatePassword(password!) {
                    errors.append(error)
                }
                if errors.count > 0 {
                    let alertController = UIAlertController(title: "Error", message: errors.joined(separator: "\n"), preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    
                } else {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    Auth.auth().createUser(withEmail: email!, password: password!) { user, error in
                        if let error = error {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            
                            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            Auth.auth().signIn(withEmail: email!, password: password!,  completion: {(authResult: AuthDataResult?, error: Error?) in
                                if let error = error {
                                    MBProgressHUD.hide(for: self.view, animated: true)
                                    
                                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                    self.present(alertController, animated: true, completion: nil)
                                } else {
                                    if let authResult = authResult {
                                        self.updateUser(email: authResult.user.email, photoURL: authResult.user.photoURL, displayName: name, completion: {(error: Error?) in
                                            MBProgressHUD.hide(for: self.view, animated: true)
                                            
                                            if let error = error {
                                                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                                                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                                self.present(alertController, animated: true, completion: nil)
                                            } else {
                                                self.dismiss(animated: true, completion: {
                                                    if let delegate = self.delegate {
                                                        delegate.actionAfterLogin(success: true)
                                                    }
                                                })
                                            }
                                        })
                                    }
                                }
                            })
                        }
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
        let login = FBSDKLoginManager()

        login.logIn(withReadPermissions: ["public_profile"], from: self, handler: {(result: FBSDKLoginManagerLoginResult?, error: Error?) in
            if let error = error {
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            } else {
                if let current = FBSDKAccessToken.current() {
                    MBProgressHUD.showAdded(to: self.view, animated: true)

                    let credential = FacebookAuthProvider.credential(withAccessToken: current.tokenString)
                    Auth.auth().signInAndRetrieveData(with: credential, completion: {(authResult: AuthDataResult?, error: Error?) in

                        if let error = error {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            
                            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            if let authResult = authResult {
                                self.updateUser(email: authResult.user.email, photoURL: authResult.user.photoURL, displayName: authResult.user.displayName, completion: {(error: Error?) in
                                    MBProgressHUD.hide(for: self.view, animated: true)
                                    
                                    if let error = error {
                                        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                                        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                        self.present(alertController, animated: true, completion: nil)
                                    } else {
                                        self.dismiss(animated: true, completion: {
                                            if let delegate = self.delegate {
                                                delegate.actionAfterLogin(success: true)
                                            }
                                        })
                                    }
                                })
                            }
                        }
                    })
                }
            }
        })
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
    func validateName(_ name: String) -> [String] {
        var errors = [String]()
        
        if name.count < 4 {
            errors.append("Name must be at least 3 characters.")
        }
        
        return errors
    }
    
    func validateEmail(_ email: String) -> [String] {
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
    
    func validatePassword(_ password: String) -> [String] {
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
}

// MARK: GIDSignInDelegate
extension LoginViewController : GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        } else {
            
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                           accessToken: authentication.accessToken)
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            Auth.auth().signInAndRetrieveData(with: credential, completion: {(authResult: AuthDataResult?, error: Error?) in
                
                if let error = error {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    if let authResult = authResult {
                        self.updateUser(email: authResult.user.email, photoURL: authResult.user.photoURL, displayName: authResult.user.displayName, completion: {(error: Error?) in
                            MBProgressHUD.hide(for: self.view, animated: true)
                            
                            if let error = error {
                                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                self.present(alertController, animated: true, completion: nil)
                            } else {
                                self.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                }
            })
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
    
    func signIn(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        //        sleep(1) // to fix blank white screen where Google SignIn view is not loaded
        present(viewController, animated: true, completion: nil)
    }


    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true, completion: nil)
//        self.updateUser()
    }
}

