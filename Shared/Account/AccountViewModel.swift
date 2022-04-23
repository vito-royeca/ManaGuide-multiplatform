//
//  AccountViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 14.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import Firebase
import FontAwesome_swift
import ManaKit
import PromiseKit

enum AccountSection: Int {
    case accountHeader
    case favorites
    case ratedCards
    case decks
    case collections
    case lists
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .accountHeader: return ""
        case .favorites: return "Favorites"
        case .ratedCards: return "Rated Cards"
        case .decks: return "Decks"
        case .collections: return "Collections"
        case .lists: return "Lists"
        }
    }
    
    var imageIcon : UIImage? {
        switch self {
        case .accountHeader:
            return nil
        case .favorites:
            return UIImage.fontAwesomeIcon(name: .heart,
                                           style: .solid,
                                           textColor: LookAndFeel.GlobalTintColor,
                                           size: CGSize(width: 20, height: 20))
        case .ratedCards:
            return UIImage.fontAwesomeIcon(name: .star,
                                           style: .solid,
                                           textColor: LookAndFeel.GlobalTintColor,
                                           size: CGSize(width: 20, height: 20))
        case .decks:
            return UIImage.fontAwesomeIcon(name: .cubes,
                                           style: .solid,
                                           textColor: LookAndFeel.GlobalTintColor,
                                           size: CGSize(width: 20, height: 20))
        case .collections:
            return UIImage.fontAwesomeIcon(name: .folder,
                                           style: .solid,
                                           textColor: LookAndFeel.GlobalTintColor,
                                           size: CGSize(width: 20, height: 20))
        case .lists:
            return UIImage.fontAwesomeIcon(name: .list,
                                           style: .solid,
                                           textColor: LookAndFeel.GlobalTintColor,
                                           size: CGSize(width: 20, height: 20))
        }
    }
    
    static var count: Int {
        return 3 // return 6 if Decks, Collection, and Lists are included
    }
}

class AccountViewModel: NSObject {
    var accountSection: AccountSection = .favorites
    
    // MARK: Data monitors
    func saveUserMetadata() {
        guard let fbUser = Auth.auth().currentUser else {
            return
        }
        
        let userRef = Database.database().reference().child("users").child(fbUser.uid)
        
        userRef.observeSingleEvent(of: .value, with: { snapshot in
            guard let user = self.saveUser(id: fbUser.uid,
                                           displayName: fbUser.displayName,
                                           avatarURL: fbUser.photoURL),
                let userId = user.id,
                let value = snapshot.value as? [String : Any] else {
                return
            }
            
            try! ManaKit.sharedInstance.realm.write {
                // remove the favorites
                for card in user.favorites {
                    for u in card.firebaseUserFavorites {
                        if u.id == user.id,
                            let index = card.firebaseUserFavorites.index(of: u) {
                            card.firebaseUserFavorites.remove(at: index)
                            ManaKit.sharedInstance.realm.add(card)
                        }
                    }
                }
                // add any found favorites
                if let dict = value["favorites"] as? [String : Any] {
                    for (k,_) in dict {
                        if let card = ManaKit.sharedInstance.realm.objects(CMCard.self).filter("firebaseID = %@", k).first {
                            card.firebaseUserFavorites.append(user)
                            ManaKit.sharedInstance.realm.add(card)
                        }
                    }
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                object: nil,
                                                userInfo: nil)
            
                // remove the ratedCards
                for rating in user.ratings {
                    ManaKit.sharedInstance.realm.delete(rating)
                }
                user.ratings.removeAll()
                ManaKit.sharedInstance.realm.add(user)
                
                // add any found ratedCards
                if let dict = value["ratedCards"] as? [String : Any] {
                    for (k,v) in dict {
                        if  let rating = v as? Double,
                            let card = ManaKit.sharedInstance.realm.objects(CMCard.self).filter("firebaseID = %@", k).first {
                            var cardRating = ManaKit.sharedInstance.realm.objects(CMCardRating.self).filter("user.id = %@ AND card.id = %@", userId, k).first
                            if cardRating == nil {
                                cardRating = CMCardRating()
                            }
                            cardRating!.card = card
                            cardRating!.user = user
                            cardRating!.rating = rating
                            ManaKit.sharedInstance.realm.add(cardRating!)
                            user.ratings.append(cardRating!)
                            ManaKit.sharedInstance.realm.add(user)
                        }
                    }
                }
            }
        })
    }
    
    func saveUser(id: String, displayName: String?, avatarURL: URL?) -> CMUser? {
        var user = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", id).first
        if user == nil {
            user = CMUser()
            user!.id = id
        }
        
        try! ManaKit.sharedInstance.realm.write {
            user!.displayName = displayName
            user!.avatarURL = avatarURL?.absoluteString
            ManaKit.sharedInstance.realm.add(user!)
        }
        
        return user
    }
    
    func getLoggedInUser() -> CMUser? {
        guard let fbUser = Auth.auth().currentUser,
            let user = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", fbUser.uid).first else {
            return nil
        }
        
        return user
    }
}
