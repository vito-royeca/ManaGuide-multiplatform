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
    private var queries = [String: DatabaseQuery]()
    private var online = false
    
    // MARK: user data
    var favoriteMIDs = [NSManagedObjectID]()
    var ratedCardMIDs = [NSManagedObjectID]()
    
    // MARK: update methods
    func updateUser(email: String?, photoURL: URL?, displayName: String?, completion: @escaping (_ error: Error?) -> Void) {
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.photoURL = photoURL
            changeRequest.commitChanges { (error) in
                if let error = error {
                    completion(error)
                } else {
                    let ref = Database.database().reference().child("users").child(user.uid)
                    
                    ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                        var providerData = [String]()
                        for pd in user.providerData {
                            providerData.append(pd.providerID)
                        }
                        
                        if var post = currentData.value as? [String : Any] {
                            post["displayName"] = displayName ?? ""
                            
                            // Set value and report transaction success
                            currentData.value = post
                            return TransactionResult.success(withValue: currentData)
                            
                        } else {
                            ref.setValue(["displayName": displayName ?? ""])
                            return TransactionResult.success(withValue: currentData)
                        }
                        
                    }) { (error, committed, snapshot) in
                        if committed {
                            completion(error)
                        } else {
                            self.updateUser(email: email, photoURL: photoURL, displayName: displayName, completion: completion)
                        }
                    }
                }
            }
        } else {
            completion(nil)
        }
    }

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
                
                ratings[userRef.key] = rating
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
                                  FCCard.Keys.Ratings : [userRef.key: rating]])
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
    
    func incrementCardViews(_ key: String, firstAttempt: Bool) {
        let ref = Database.database().reference().child("cards").child(key)
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : Any] {
                var views = post[FCCard.Keys.Views] as? Int ?? 0
                views += 1
                post[FCCard.Keys.Views] = views
                
                // Set value and report transaction success
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
                
            } else {
                if firstAttempt {
                    return TransactionResult.abort()
                } else {
                    ref.setValue([FCCard.Keys.Views: 1])
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
                
                card.views = Int64(fcard.views == nil ? 1 : fcard.views!)
                
                ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                    try! backgroundContext.save()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                                    object: nil,
                                                    userInfo: ["card": card])
                }

            } else {
                // retry again, if we were aborted from above
                self.incrementCardViews(key, firstAttempt: false)
            }
        }
    }
    
    func toggleCardFavorite(_ key: String, favorite: Bool, firstAttempt: Bool) {
        if let _ = Auth.auth().currentUser,
            let userRef = userRef {
            userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : Any] {
                    var dict: [String: Any]?
                    
                    if let d = post["favorites"] as? [String : Any] {
                        dict = d
                    } else {
                        dict = [String: Any]()
                    }
                    
                    if favorite {
                        dict![key] = true
                    } else {
                        dict![key] = nil
                    }
                    
                    post["favorites"] = dict

                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)

                } else {
                    if firstAttempt {
                        return TransactionResult.abort()
                    } else {
                        userRef.setValue(["favorites": [key: favorite ? true : nil]])
                        return TransactionResult.success(withValue: currentData)
                    }
                }

            }) { (error, committed, snapshot) in
                if !committed {
                    // retry again, if we were aborted from above
                    self.toggleCardFavorite(key, favorite: favorite, firstAttempt: false)
                }
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
    
    // MARK: Data monitors
    func monitorUser() {
        if let user = Auth.auth().currentUser {
            userRef = Database.database().reference().child("users").child(user.uid)
            
            userRef!.observe(.value, with: { snapshot in
                if let value = snapshot.value as? [String : Any] {
                    if let dict = value["favorites"] as? [String : Any] {
                        self.favoriteMIDs = self.cardMIDs(withIds: Array(dict.keys))
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                        object: nil,
                                                        userInfo: nil)
                    }
                    
                    if let dict = value["ratedCards"] as? [String : Any] {
                        self.ratedCardMIDs = self.cardMIDs(withIds: Array(dict.keys))
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                        object: nil,
                                                        userInfo: nil)
                    }
                }
            })
        }
    }
    
    func demonitorTopCharts() {
        let ref = Database.database().reference().child("cards")
        ref.keepSynced(false)
        
        if let query = queries["topViewed"] {
            query.removeAllObservers()
            queries["topViewed"] = nil
        }
        
        if let query = queries["topRated"] {
            query.removeAllObservers()
            queries["topRated"] = nil
        }
    }
    
    func demonitorUser() {
        if let userRef = userRef {
            userRef.removeAllObservers()
        }
        
        userRef = nil
        favoriteMIDs = [NSManagedObjectID]()
        ratedCardMIDs = [NSManagedObjectID]()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                        object: nil,
                                        userInfo: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                        object: nil,
                                        userInfo: nil)
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
