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

class AccountViewModel: NSObject {
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
