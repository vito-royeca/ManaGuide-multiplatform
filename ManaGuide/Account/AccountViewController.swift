//
//  AccountViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 24/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import ManaKit
import SDWebImage

enum AccountViewControllerSection: Int {
    case accountHeader
    case favorites
    case ratedCards
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .accountHeader: return ""
        case .favorites: return "Favorites"
        case .ratedCards: return "Rated Cards"
        }
    }
    
    var imageIcon : UIImage? {
        switch self {
        case .accountHeader:
            return nil
        case .favorites:
            return UIImage(bgIcon: .FAHeart,
                           orientation: UIImageOrientation.up,
                           bgTextColor: UIColor.lightGray,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FAHeart,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        case .ratedCards:
            return UIImage(bgIcon: .FAStar,
                           orientation: UIImageOrientation.up,
                           bgTextColor: UIColor.lightGray,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FAStar,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        }
    }
    
    static var count: Int {
        return 3
    }
}

class AccountViewController: BaseViewController {

    // MARK: Variables
    var viewModel = AccountViewModel()

    // MARK Outlets
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    @IBAction func loginAction(_ sender: UIBarButtonItem) {
        if let _ = Auth.auth().currentUser {
            do {
                try Auth.auth().signOut()
                viewModel.demonitorUser()
                updateDisplay()
            } catch let error {
                print("\(error)")
            }
        } else {
            performSegue(withIdentifier: "showLogin",
                         sender: nil)
        }
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.UserLoggedIn),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userLoggedIn(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.UserLoggedIn),
                                               object: nil)
        
        if let _ = Auth.auth().currentUser {
            viewModel.monitorUser()
            updateDisplay()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dict = sender as? [String: Any]  else {
            return
        }
        
        if segue.identifier == "showLogin" {
            guard let dest = segue.destination as? UINavigationController else {
                return
            }
            guard let loginVC = dest.childViewControllers.first as? LoginViewController else {
                return
            }
            
            loginVC.delegate = self
            
        } else if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController else {
                return
            }
            
            dest.request = dict["request"] as? NSFetchRequest<CMCard>
            dest.title = dict["title"] as? String
            dest.customSectionName = "nameSection"
        }
    }
    
    // Custom methods
    func userLoggedIn(_ notification: Notification) {
        viewModel.monitorUser()
        updateDisplay()
    }
    
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
        case AccountViewControllerSection.ratedCards.rawValue:
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
            guard let c = tableView.dequeueReusableCell(withIdentifier: "AccountCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            guard let imageView = c.viewWithTag(100) as? UIImageView,
                let label = c.viewWithTag(200) as? UILabel else {
                    return UITableViewCell(frame: CGRect.zero)
            }
            
            imageView.layer.cornerRadius = imageView.frame.height / 2
            
            if let user = Auth.auth().currentUser {
                imageView.sd_setImage(with: user.photoURL, completed: {(image: UIImage?, error: Error?, cacheType: SDImageCacheType, imageURL: URL?) in
                    if image == nil {
                        imageView.image = UIImage(bgIcon: .FAUserCircle,
                                                  orientation: UIImageOrientation.up,
                                                  bgTextColor: UIColor.lightGray,
                                                  bgBackgroundColor: UIColor.clear,
                                                  topIcon: .FAUserCircle,
                                                  topTextColor: UIColor.clear,
                                                  bgLarge: true,
                                                  size: CGSize(width: 60, height: 60))
                    }
                })
                label.text = user.displayName
            } else {
                imageView.image = UIImage(bgIcon: .FAUserCircle,
                                          orientation: UIImageOrientation.up,
                                          bgTextColor: UIColor.lightGray,
                                          bgBackgroundColor: UIColor.clear,
                                          topIcon: .FAUserCircle,
                                          topTextColor: UIColor.clear,
                                          bgLarge: true,
                                          size: CGSize(width: 60, height: 60))
                label.text = "Not logged in"
            }
            
            c.accessoryType = .none
            cell = c

        case AccountViewControllerSection.favorites.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            guard let label = c.textLabel,
                let imageView = c.imageView else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            imageView.image = AccountViewControllerSection.favorites.imageIcon
            label.text = AccountViewControllerSection.favorites.description
            
            c.accessoryType = .disclosureIndicator
            cell = c

        case AccountViewControllerSection.ratedCards.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            guard let label = c.textLabel,
                let imageView = c.imageView else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            imageView.image = AccountViewControllerSection.ratedCards.imageIcon
            label.text = AccountViewControllerSection.ratedCards.description
            
            c.accessoryType = .disclosureIndicator
            cell = c

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
        case AccountViewControllerSection.favorites.rawValue,
             AccountViewControllerSection.ratedCards.rawValue:
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
        case AccountViewControllerSection.ratedCards.rawValue:
            path = indexPath
        default:
            ()
        }
        
        return path
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case AccountViewControllerSection.favorites.rawValue:
            let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            let mids = FirebaseManager.sharedInstance.favoriteMIDs
            let cards = FirebaseManager.sharedInstance.cards(withMIDs: mids)
            
            request.predicate = NSPredicate(format: "id IN %@", cards.map({ $0.id }))
            request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                       NSSortDescriptor(key: "name", ascending: true),
                                       NSSortDescriptor(key: "set.releaseDate", ascending: true)]
            performSegue(withIdentifier: "showSearch", sender: ["title": "Favorites",
                                                                "request": request])
        case AccountViewControllerSection.ratedCards.rawValue:
            let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            let mids = FirebaseManager.sharedInstance.ratedCardMIDs
            let cards = FirebaseManager.sharedInstance.cards(withMIDs: mids)
            
            request.predicate = NSPredicate(format: "id IN %@", cards.map({ $0.id }))
            request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                       NSSortDescriptor(key: "name", ascending: true),
                                       NSSortDescriptor(key: "set.releaseDate", ascending: true)]
            performSegue(withIdentifier: "showSearch", sender: ["title": "Rated Cards",
                                                                "request": request])
        default:
            ()
        }
    }
}

// MARK: LoginViewControllerDelegate
extension AccountViewController : LoginViewControllerDelegate {
    func actionAfterLogin(error: Error?) {
        if let error = error {
            
        } else {
            viewModel.monitorUser()
            updateDisplay()
        }
    }
}
