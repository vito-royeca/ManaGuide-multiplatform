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

class LoginViewController: UIViewController {

    // MARK: Actions
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func loginAction(_ sender: UIButton) {
        
    }
    
    @IBAction func forgotPasswordAction(_ sender: UIButton) {
        
    }
    
    @IBAction func signupAction(_ sender: UIButton) {
        
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
                        MBProgressHUD.hide(for: self.view, animated: true)

                        if let error = error {
                            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            self.dismiss(animated: true, completion: nil)
//                            self.updateUser()
                        }
                    })
                }
            }
        })
    }
    
    @IBAction func googleAction(_ sender: UIButton) {
        
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
            errors.append("Empty Email.")
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

}
