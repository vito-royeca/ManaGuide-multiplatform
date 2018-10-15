//
//  AccountViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 14.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import Firebase
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
            return UIImage(bgIcon: .FAHeart,
                           orientation: UIImage.Orientation.up,
                           bgTextColor: LookAndFeel.GlobalTintColor,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FAHeart,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        case .ratedCards:
            return UIImage(bgIcon: .FAStar,
                           orientation: UIImage.Orientation.up,
                           bgTextColor: LookAndFeel.GlobalTintColor,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FAStar,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        case .decks:
            return UIImage(bgIcon: .FACubes,
                           orientation: UIImage.Orientation.up,
                           bgTextColor: LookAndFeel.GlobalTintColor,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FACubes,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        case .collections:
            return UIImage(bgIcon: .FAFolder,
                           orientation: UIImage.Orientation.up,
                           bgTextColor: LookAndFeel.GlobalTintColor,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FAFolder,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        case .lists:
            return UIImage(bgIcon: .FAList,
                           orientation: UIImage.Orientation.up,
                           bgTextColor: LookAndFeel.GlobalTintColor,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FAList,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
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
            
            // remove the favorites
            if let set = user.favorites,
                let favorites = set.allObjects as? [CMCard] {
                for card in favorites {
                    user.removeFromFavorites(card)
                }
            }
            // add any found favorites
            if let dict = value["favorites"] as? [String : Any] {
                for (k,_) in dict {
                    if let card = ManaKit.sharedInstance.findObject("CMCard",
                                                                 objectFinder: ["id": k as AnyObject],
                                                                 createIfNotFound: false) as? CMCard {
                        user.addToFavorites(card)
                    }
                }
            }
            try! ManaKit.sharedInstance.dataStack?.mainContext.save()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                            object: nil,
                                            userInfo: nil)
            
            // remove the ratedCards
            if let set = user.ratings,
                let ratings = set.allObjects as? [CMCardRating] {
                for rating in ratings {
                    user.removeFromRatings(rating)
                }
            }
            // add any found ratedCards
            if let dict = value["ratedCards"] as? [String : Any] {
                for (k,v) in dict {
                    if  let rating = v as? Double,
                        let card = ManaKit.sharedInstance.findObject("CMCard",
                                                                    objectFinder: ["id": k as AnyObject],
                                                                    createIfNotFound: false) as? CMCard,
                        let cardRating = ManaKit.sharedInstance.findObject("CMCardRating",
                                                                           objectFinder: ["user.id": userId as AnyObject,
                                                                                          "card.id": k as AnyObject],
                                                                           createIfNotFound: true) as? CMCardRating {
                        cardRating.card = card
                        cardRating.user = user
                        cardRating.rating = rating
                        user.addToRatings(cardRating)
                    }
                }
                
            }
            try! ManaKit.sharedInstance.dataStack?.mainContext.save()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                            object: nil,
                                            userInfo: nil)
        })
    }
    
    func saveUser(id: String, displayName: String?, avatarURL: URL?) -> CMUser? {
        guard let user = ManaKit.sharedInstance.findObject("CMUser",
                                                           objectFinder: ["id": id as AnyObject],
                                                           createIfNotFound: true) as? CMUser else {
            return nil
        }
        
        user.id = id
        user.displayName = displayName
        user.avatarURL = avatarURL?.absoluteString
        try! ManaKit.sharedInstance.dataStack?.mainContext.save()
        
        return user
    }
    
    func getLoggedInUser() -> CMUser? {
        guard let fbUser = Auth.auth().currentUser,
            let user = ManaKit.sharedInstance.findObject("CMUser",
                                                         objectFinder: ["id": fbUser.uid as AnyObject],
                                                         createIfNotFound: true) as? CMUser else {
            return nil
        }
        
        return user
    }
}
