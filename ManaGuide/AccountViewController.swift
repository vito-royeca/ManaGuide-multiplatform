//
//  AccountViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 24/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import Firebase
import SDWebImage

enum AccountViewControllerSection: Int {
    case accountHeader
    case favorites
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .accountHeader: return ""
        case .favorites: return "Favorites"
        }
    }
    
    var imageIcon : UIImage? {
        switch self {
        case .accountHeader:
            return nil
        case .favorites:
            return UIImage(bgIcon: .FAHeart, orientation: UIImageOrientation.up, bgTextColor: UIColor.lightGray, bgBackgroundColor: UIColor.clear, topIcon: .FAHeart, topTextColor: UIColor.clear, bgLarge: false, size: CGSize(width: 20, height: 20))
        }
    }
    
    static var count: Int {
        return 2
    }
}

class AccountViewController: UIViewController {

    // MARK Outlets
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    @IBAction func loginAction(_ sender: UIBarButtonItem) {
        if let _ = Auth.auth().currentUser {
            do {
                try Auth.auth().signOut()
                FirebaseManager.sharedInstance.demonitorUser()
                updateDisplay()
            } catch let error {
                print("\(error)")
            }
        } else {
            performSegue(withIdentifier: "showLogin", sender: nil)
        }
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        updateDisplay()
        // FirebaseManager
        FirebaseManager.sharedInstance.monitorUser()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLogin" {
            if let dest = segue.destination as? UINavigationController {
                if let loginVC = dest.childViewControllers.first as? LoginViewController {
                    loginVC.delegate = self
                }
            }
        } else if segue.identifier == "showSearch" {
            if let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any] {
                
                dest.request = dict["request"] as? NSFetchRequest<NSFetchRequestResult>
                dest.title = dict["title"] as? String
                dest.customSectionName = "nameSection"
            }
        }
    }
    
    // Custom methods
    func updateDisplay() {
        if let _ = Auth.auth().currentUser {
            loginButton.title = "Logout"
        } else {
            loginButton.title = "Login"
        }
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource
extension AccountViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        
        switch section {
        case AccountViewControllerSection.accountHeader.rawValue:
            rows = 1
        case AccountViewControllerSection.favorites.rawValue:
            rows = 1
        default:
            ()
        }
        
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        switch indexPath.section {
        case AccountViewControllerSection.accountHeader.rawValue:
            if let c = tableView.dequeueReusableCell(withIdentifier: "AccountCell") {
                if let imageView = c.viewWithTag(100) as? UIImageView,
                    let label = c.viewWithTag(200) as? UILabel {
                
                    imageView.layer.cornerRadius = imageView.frame.height / 2
                    
                    if let user = Auth.auth().currentUser {
                        imageView.sd_setImage(with: user.photoURL, completed: {(image: UIImage?, error: Error?, cacheType: SDImageCacheType, imageURL: URL?) in
                            if image == nil {
                                imageView.image = UIImage(bgIcon: .FAUserCircle, orientation: UIImageOrientation.up, bgTextColor: UIColor.lightGray, bgBackgroundColor: UIColor.clear, topIcon: .FAUserCircle, topTextColor: UIColor.clear, bgLarge: true, size: CGSize(width: 60, height: 60))
                            }
                        })
                        label.text = user.displayName
                    } else {
                        imageView.image = UIImage(bgIcon: .FAUserCircle, orientation: UIImageOrientation.up, bgTextColor: UIColor.lightGray, bgBackgroundColor: UIColor.clear, topIcon: .FAUserCircle, topTextColor: UIColor.clear, bgLarge: true, size: CGSize(width: 60, height: 60))
                        label.text = "Not logged in"
                    }
                }
                
                c.accessoryType = .none
                cell = c
            }
        case AccountViewControllerSection.favorites.rawValue:
            if let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell") {
                if let label = c.textLabel,
                    let imageView = c.imageView {
                    imageView.image = AccountViewControllerSection.favorites.imageIcon
                    label.text = AccountViewControllerSection.favorites.description
                }
                
                c.accessoryType = .disclosureIndicator
                cell = c
            }
        default:
            ()
        }
        
        return cell!
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 1
        
        if let _ = Auth.auth().currentUser {
            sections = AccountViewControllerSection.count
        }
        
        return sections
    }
}

// MARK: UITableViewDelegate
extension AccountViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)
        
        switch indexPath.section {
        case AccountViewControllerSection.accountHeader.rawValue:
            height = 88
        case AccountViewControllerSection.favorites.rawValue:
            height = UITableViewAutomaticDimension
        default:
            ()
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        var path: IndexPath?
        
        switch indexPath.section {
        case AccountViewControllerSection.accountHeader.rawValue:
            ()
        case AccountViewControllerSection.favorites.rawValue:
            path = indexPath
        default:
            ()
        }
        
        return path
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case AccountViewControllerSection.favorites.rawValue:
            let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
            let names = FirebaseManager.sharedInstance.favorites.map({ $0.id })
            
            request.predicate = NSPredicate(format: "id IN %@", names)
            request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                       NSSortDescriptor(key: "name", ascending: true),
                                       NSSortDescriptor(key: "set.releaseDate", ascending: true)]
            performSegue(withIdentifier: "showSearch", sender: ["title": "Favorites",
                                                                "request": request])
        default:
            ()
        }
    }
}

// MARK: LoginViewControllerDelegate
extension AccountViewController : LoginViewControllerDelegate {
    func actionAfterLogin(success: Bool) {
        if success {
            updateDisplay()
        }
    }
}
