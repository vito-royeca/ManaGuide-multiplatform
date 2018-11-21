//
//  LoginViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 26/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import Firebase
import FontAwesome_swift
import GoogleSignIn
import MBProgressHUD
import PromiseKit
import SafariServices

protocol LoginViewControllerDelegate {
    func actionAfterLogin(error: Error?)
}

class LoginViewController: BaseViewController {

    // MARK: Variables
    var delegate: LoginViewControllerDelegate?
    var viewModel = LoginViewModel()
    
    // MARK: Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var githubButton: UIButton!
    
    // MARK: Actions
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func loginAction(_ sender: UIButton) {
        guard let email = usernameTextField.text,
            let password = passwordTextField.text else {
            return
        }
        
        var errors = [String]()
        for error in viewModel.validate(email: email) {
            errors.append(error)
        }
        for error in viewModel.validate(password: password) {
            errors.append(error)
        }
        
        if errors.count > 0 {
            showMessage(title: "Error",
                        message: errors.joined(separator: "\n"))
        } else {
            MBProgressHUD.showAdded(to: self.view,
                                    animated: true)
            
            firstly {
                viewModel.authSignIn(with: email,
                                     password: password)
            }.then { (authResult: AuthDataResult?) in
                self.viewModel.syncUser(email: authResult?.user.email,
                                        photoURL: authResult?.user.photoURL,
                                        displayName: authResult?.user.displayName)
            }.done {
                self.dismiss(animated: true, completion: {
                    self.delegate?.actionAfterLogin(error: nil)
                })
            }.catch { error in
                MBProgressHUD.hide(for: self.view,
                                   animated: true)
                self.showMessage(title: "Error",
                                 message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func forgotPasswordAction(_ sender: UIButton) {
        let title = "Retrieve Password"
        let alertController = UIAlertController(title: title,
                                                message: "We will send instructions to the email below on how to retrive your password.",
                                                preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Submit",
                                          style: .default) { (_) in
            if let fields = alertController.textFields {
                let email = fields[0].text
                
                var errors = [String]()
                for error in self.viewModel.validate(email: email!) {
                    errors.append(error)
                }

                if errors.count > 0 {
                    self.showMessage(title: "Error", message: errors.joined(separator: "\n"))
                } else {
                    MBProgressHUD.showAdded(to: self.view,
                                            animated: true)
                    
                    firstly {
                        self.viewModel.authSetPasswordReset(email: email!)
                    }.done {
                        MBProgressHUD.hide(for: self.view,
                                           animated: true)
                        self.showMessage(title: "Success",
                                         message: "Check the email you provided for instructions.")
                    }.catch { error in
                            MBProgressHUD.hide(for: self.view,
                                               animated: true)
                            self.showMessage(title: "Error",
                                             message: error.localizedDescription)
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
        let alertController = UIAlertController(title: "Sign Up",
                                                message: nil,
                                                preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            guard let fields = alertController.textFields else {
                return
            }
            
            guard let name = fields[0].text,
                let email = fields[1].text,
                let password = fields[2].text else {
                return
            }
            
            let completion = { (_ error: Error?) in
                if let error = error {
                    self.showMessage(title: "Error",
                                     message: error.localizedDescription)
                }
            }

            var errors = [String]()
            for error in self.viewModel.validate(name: name) {
                errors.append(error)
            }
            for error in self.viewModel.validate(email: email) {
                errors.append(error)
            }
            for error in self.viewModel.validate(password: password) {
                errors.append(error)
            }
            
            if errors.count > 0 {
                self.showMessage(title: "Error", message: errors.joined(separator: "\n"))
            } else {
                MBProgressHUD.showAdded(to: self.view, animated: true)
                
                firstly {
                    self.viewModel.authCreateUser(email: email, password: password)
                }.map { (authResult: AuthDataResult?) -> () in
                    self.viewModel.updateUser(email: authResult?.user.email,
                                              photoURL: authResult?.user.photoURL,
                                              displayName: name,
                                              completion: completion)
                }.done {
                    self.dismiss(animated: true, completion: {
                        self.delegate?.actionAfterLogin(error: nil)
                    })
                }.catch { error in
                    MBProgressHUD.hide(for: self.view,
                                       animated: true)
                    self.showMessage(title: "Error",
                                     message: error.localizedDescription)
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
        let completion = { (_ error: Error?) in
            if let error = error {
                self.showMessage(title: "Error",
                                 message: error.localizedDescription)
            }
        }
        
        firstly {
            viewModel.facebookLogin(withViewController: self)
        }.then { (credential: AuthCredential) in
            self.viewModel.authSignInAndRetrieveData(credential: credential)
        }.map { (authResult: AuthDataResult?) -> Void in
            self.viewModel.updateUser(email: authResult?.user.email,
                                      photoURL: authResult?.user.photoURL,
                                      displayName: authResult?.user.displayName,
                                      completion: completion)
        }.done {
            self.dismiss(animated: true, completion: {
                self.delegate?.actionAfterLogin(error: nil)
            })
        }.catch { error in
            self.showMessage(title: "Error",
                             message: error.localizedDescription)
        }
    }
    
    @IBAction func googleAction(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func githubAction(_ sender: UIButton) {
        let completion = { (_ error: Error?) in
            if let error = error {
                self.showMessage(title: "Error",
                                 message: error.localizedDescription)
            }
        }
        
        firstly {
            viewModel.githubLogin(withViewController: self)
        }.then { (credential: AuthCredential) in
            self.viewModel.authSignInAndRetrieveData(credential: credential)
        }.map { (authResult: AuthDataResult?) -> Void in
            self.viewModel.updateUser(email: authResult?.user.email,
                                      photoURL: authResult?.user.photoURL,
                                      displayName: authResult?.user.displayName,
                                      completion: completion)
        }.done {
            self.dismiss(animated: true, completion: {
                self.delegate?.actionAfterLogin(error: nil)
            })
        }.catch { error in
            self.showMessage(title: "Error",
                             message: error.localizedDescription)
        }
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        facebookButton.setImage(UIImage.fontAwesomeIcon(name: .facebook,
                                                        style: .brands,
                                                        textColor: LookAndFeel.GlobalTintColor,
                                                        size: CGSize(width: 30, height: 30)),
                                for: .normal)
        googleButton.setImage(UIImage.fontAwesomeIcon(name: .google,
                                                      style: .brands,
                                                      textColor: LookAndFeel.GlobalTintColor,
                                                      size: CGSize(width: 30, height: 30)),
                                for: .normal)
        githubButton.setImage(UIImage.fontAwesomeIcon(name: .github,
                                                      style: .brands,
                                                      textColor: LookAndFeel.GlobalTintColor,
                                                      size: CGSize(width: 30, height: 30)),
                              for: .normal)
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
        viewModel = LoginViewModel()
    }


    // MARK: Custom methods
    func showMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK",
                                                style: UIAlertAction.Style.default,
                                                handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: GIDSignInDelegate
extension LoginViewController : GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            self.showMessage(title: "Error", message: error.localizedDescription)
        } else {
            guard let authentication = user.authentication else {
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                           accessToken: authentication.accessToken)
            
            firstly {
                viewModel.authSignInAndRetrieveData(credential: credential)
            }.then { (authResult: AuthDataResult?) in
                self.viewModel.syncUser(email: authResult?.user.email,
                                        photoURL: authResult?.user.photoURL,
                                        displayName: authResult?.user.displayName)
            }.done {
                self.dismiss(animated: true, completion: {
                    self.delegate?.actionAfterLogin(error: nil)
                })
            }.catch { error in
                self.showMessage(title: "Error",
                                 message: error.localizedDescription)
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

