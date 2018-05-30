//
//  AccountViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 24/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

enum AccountViewControllerSection: Int {
    case accountHeader
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .accountHeader: return ""
        }
    }
    
    static var count: Int {
        return 1
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateDisplay()
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
                
                cell = c
            }
        default:
            ()
        }
        
        return cell!
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return AccountViewControllerSection.count
    }
}

// MARK: UITableViewDelegate
extension AccountViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = UITableViewAutomaticDimension
        
        switch indexPath.section {
        case AccountViewControllerSection.accountHeader.rawValue:
            height = 88
        default:
            ()
        }
        
        return height
    }
}

