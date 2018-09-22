//
//  FirebaseManager.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 15/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import ManaKit
import PromiseKit

class FirebaseManager: NSObject {
    private var userRef: DatabaseReference?
    private var online = false
    
    // MARK: user data
//    var favoriteMIDs = [NSManagedObjectID]()
//    var ratedCardMIDs = [NSManagedObjectID]()
    
    // MARK: update methods
    func updateCardRatings(_ key: String, rating: Double, firstAttempt: Bool) {
        guard let _ = Auth.auth().currentUser else {
            return
        }
        guard let userRef = userRef else {
            return
        }
            
        let ref = Database.database().reference().child("cards").child(key)
            
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : Any] {
                var ratings = post[FCCard.Keys.Ratings] as? [String: Double] ?? [String: Double]()
                var tmpRating = Double(0)
                
                ratings[userRef.key!] = rating
                for (_,v) in ratings {
                    tmpRating += v
                }
                tmpRating = tmpRating / Double(ratings.keys.count)
                
                post[FCCard.Keys.Rating] = tmpRating
                post[FCCard.Keys.Ratings] = ratings
                
                // Set value and report transaction success
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
                
            } else {
                if firstAttempt {
                    return TransactionResult.abort()
                } else {
                    ref.setValue([FCCard.Keys.Rating: rating,
                                  FCCard.Keys.Ratings : [userRef.key!: rating]])
                    return TransactionResult.success(withValue: currentData)
                }
            }
            
        }) { (error, committed, snapshot) in
            if committed {
                guard let snapshot = snapshot else {
                    return
                }
                let fcard = FCCard(snapshot: snapshot)
                
                guard let cardMID = self.cardMIDs(withIds: [snapshot.key]).first,
                    let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: cardMID) as? CMCard else {
                    return
                }
                
                card.rating = fcard.rating == nil ? rating : fcard.rating!
                card.ratings = fcard.ratings == nil ? Int32(1) : Int32(fcard.ratings!.count)
                
                ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                    try! backgroundContext.save()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                    object: nil,
                                                    userInfo: ["card": card])
                    
                    self.updateUserRatings(key, rating: rating, firstAttempt: true)
                }
                
            } else {
                // retry again, if we were aborted from above
                self.updateCardRatings(key, rating: rating, firstAttempt: false)
            }
        }
    }
    
    func updateUserRatings(_ key: String, rating: Double, firstAttempt: Bool) {
        if let _ = Auth.auth().currentUser,
            let userRef = userRef {
            userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : Any] {
                    var dict: [String: Any]?
                    
                    if let d = post["ratedCards"] as? [String : Double] {
                        dict = d
                        dict![key] = rating
                    } else {
                        dict = [key: rating]
                    }
                    
                    post["ratedCards"] = dict
                    
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                    
                } else {
                    if firstAttempt {
                        return TransactionResult.abort()
                    } else {
                        userRef.setValue(["ratedCards": [key: rating]])
                        return TransactionResult.success(withValue: currentData)
                    }
                }
                
            }) { (error, committed, snapshot) in
                if !committed {
                    // retry again, if we were aborted from above
                    self.updateUserRatings(key, rating: rating, firstAttempt: false)
                }
            }
        }
    }
    
    // MARK: Custom methods
    func cardMIDs(withIds ids: [String]) -> [NSManagedObjectID] {
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)
        var array = [NSManagedObjectID]()

        for card in try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) {
            array.append(card.objectID)
        }

        return array
    }

    func cards(withMIDs mids: [NSManagedObjectID]) -> [CMCard] {
        var cards = [CMCard]()

        for mid in mids {
            if let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: mid) as? CMCard {
                cards.append(card)
            }
        }

        return cards
    }
    
    // MARK: - Shared Instance
    static let sharedInstance = FirebaseManager()
}
