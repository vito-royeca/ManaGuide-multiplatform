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
        
        viewModel.saveUserMetadata()
        updateDisplay()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLogin" {
            guard let dest = segue.destination as? UINavigationController else {
                return
            }
            guard let loginVC = dest.childViewControllers.first as? LoginViewController else {
                return
            }
            
            loginVC.delegate = self
            
        } else if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any],
                let request = dict["request"] as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request,
                                             andTitle: dict["title"] as? String)
            dest.delegate = self
        } else if segue.identifier == "showDecks" {
            guard let dest = segue.destination as? DecksViewController else {
                return
            }
        } else if segue.identifier == "showCollections" {
            guard let dest = segue.destination as? CollectionsViewController else {
                return
            }
        } else if segue.identifier == "showLists" {
            guard let dest = segue.destination as? ListsViewController else {
                return
            }
        }
    }
    
    // Custom methods
    @objc func userLoggedIn(_ notification: Notification) {
        viewModel.saveUserMetadata()
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
    
    func favoritesRequest() -> NSFetchRequest<CMCard> {
        guard let user = viewModel.getLoggedInUser() else {
            fatalError("No logged in User")
        }
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        
        if let favorites = user.favorites,
            let cards = favorites.allObjects as? [CMCard] {
            request.predicate = NSPredicate(format: "id IN %@", cards.map({ $0.id }))
        } else {
            // fetch non-existent cards
            request.predicate = NSPredicate(format: "id = %@", "-1")
        }
        
        return request
    }
    
    func ratedCardsRequest() -> NSFetchRequest<CMCard> {
        guard let user = viewModel.getLoggedInUser() else {
            fatalError("No logged in User")
        }
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        
        if let ratings = user.ratings,
            let cardRatings = ratings.allObjects as? [CMCardRating] {
            request.predicate = NSPredicate(format: "id IN %@", cardRatings.map({ $0.card! }).map( { $0.id } ))
        } else {
            // fetch non-existent cards
            request.predicate = NSPredicate(format: "id = %@", "-1")
        }
        
        return request
    }
}

// MARK: UITableViewDataSource
extension AccountViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Auth.auth().currentUser != nil ? AccountSection.count : 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        switch indexPath.row {
        case AccountSection.accountHeader.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: AccountHeroTableViewCell.reuseIdentifier) as? AccountHeroTableViewCell else {
                fatalError("\(AccountHeroTableViewCell.reuseIdentifier) not found")
            }
            c.user = Auth.auth().currentUser
            cell = c

        case AccountSection.favorites.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                let label = c.textLabel,
                let imageView = c.imageView else {
                fatalError("BasicCell not found")
            }
            imageView.image = AccountSection.favorites.imageIcon
            label.text = AccountSection.favorites.description
            c.accessoryType = .disclosureIndicator
            cell = c

        case AccountSection.ratedCards.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                let label = c.textLabel,
                let imageView = c.imageView else {
                    fatalError("BasicCell not found")
            }
            imageView.image = AccountSection.ratedCards.imageIcon
            label.text = AccountSection.ratedCards.description
            c.accessoryType = .disclosureIndicator
            cell = c

        case AccountSection.decks.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                let label = c.textLabel,
                let imageView = c.imageView else {
                    fatalError("BasicCell not found")
            }
            imageView.image = AccountSection.decks.imageIcon
            label.text = AccountSection.decks.description
            c.accessoryType = .disclosureIndicator
            cell = c
        
        case AccountSection.collections.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                let label = c.textLabel,
                let imageView = c.imageView else {
                    fatalError("BasicCell not found")
            }
            imageView.image = AccountSection.collections.imageIcon
            label.text = AccountSection.collections.description
            c.accessoryType = .disclosureIndicator
            cell = c
            
        case AccountSection.lists.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                let label = c.textLabel,
                let imageView = c.imageView else {
                    fatalError("BasicCell not found")
            }
            imageView.image = AccountSection.lists.imageIcon
            label.text = AccountSection.lists.description
            c.accessoryType = .disclosureIndicator
            cell = c
            
        default:
            ()
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension AccountViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)
        
        switch indexPath.row {
        case AccountSection.accountHeader.rawValue:
            height = 88
        default:
            height = UITableViewAutomaticDimension
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        var path: IndexPath?
        
        switch indexPath.row {
        case AccountSection.accountHeader.rawValue:
            ()
        default:
            path = indexPath
        }
        
        return path
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case AccountSection.favorites.rawValue:
            viewModel.accountSection = .favorites
            performSegue(withIdentifier: "showSearch",
                         sender: ["title": "Favorites",
                                  "request": favoritesRequest()])
        case AccountSection.ratedCards.rawValue:
            viewModel.accountSection = .ratedCards
            performSegue(withIdentifier: "showSearch",
                         sender: ["title": "Rated Cards",
                                  "request": ratedCardsRequest()])
        case AccountSection.decks.rawValue:
            viewModel.accountSection = .decks
            performSegue(withIdentifier: "showDecks",
                         sender: nil)
        case AccountSection.collections.rawValue:
            viewModel.accountSection = .collections
            performSegue(withIdentifier: "showCollections",
                         sender: nil)
        case AccountSection.lists.rawValue:
            viewModel.accountSection = .lists
            performSegue(withIdentifier: "showLists",
                         sender: nil)
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
            viewModel.saveUserMetadata()
            updateDisplay()
        }
    }
}

// MARK: SearchViewControllerDelegate
extension AccountViewController: SearchViewControllerDelegate {
    func reloadViewModel() -> SearchViewModel {
        switch viewModel.accountSection {
        case .favorites:
            return SearchViewModel(withRequest: favoritesRequest(),
                                   andTitle: "Favorites")
        case .ratedCards:
            return SearchViewModel(withRequest: ratedCardsRequest(),
                                   andTitle: "Rated Cards")
        default:
            return SearchViewModel(withRequest: favoritesRequest(),
                                   andTitle: "Favorites")
        }
    }
}


