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

let kMaxFetchTopViewed = UInt(10)
let kMaxFetchTopRated  = UInt(10)
let kCardViewUpdatedNotification = "kCardViewUpdatedNotification"

class FirebaseManager: NSObject {
    var userRef: DatabaseReference?
    var queries = [String: DatabaseQuery]()
    var online = false
    
    // MARK: user data
    var favorites = [CMCard]()
    
    // MARK: update methods
    func updateUser(email: String?, photoURL: URL?, displayName: String?, completion: @escaping (_ error: Error?) -> Void) {
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.photoURL = photoURL
            changeRequest.commitChanges { (error) in
                if let error = error {
                    print(error.localizedDescription)
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
                        completion(error)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }

    func updateCardRatings(_ key: String) {
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
                ref.setValue([FCCard.Keys.Views: 1])
                return TransactionResult.success(withValue: currentData)
            }
            
        }) { (error, committed, snapshot) in
            if let snapshot = snapshot {
                let fcard = FCCard(snapshot: snapshot)
                let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                request.predicate = NSPredicate(format: "id == %@", snapshot.key)
                
                if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
                    if let card = result.first {
                        card.views = Int64(fcard.views == nil ? 0 : fcard.views!)
                        try! ManaKit.sharedInstance.dataStack!.mainContext.save()
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: kCardViewUpdatedNotification), object: nil, userInfo: ["card": card])
                    }
                }
            }
        }
    }
    
    func incrementCardViews(_ key: String) {
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
                ref.setValue([FCCard.Keys.Views: 1])
                return TransactionResult.success(withValue: currentData)
            }
            
        }) { (error, committed, snapshot) in
            if let snapshot = snapshot {
                let fcard = FCCard(snapshot: snapshot)
                let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                request.predicate = NSPredicate(format: "id == %@", snapshot.key)
                
                if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
                    if let card = result.first {
                        card.views = Int64(fcard.views == nil ? 0 : fcard.views!)
                        try! ManaKit.sharedInstance.dataStack!.mainContext.save()

                        NotificationCenter.default.post(name: Notification.Name(rawValue: kCardViewUpdatedNotification), object: nil, userInfo: ["card": card])
                    }
                }
            }
        }
    }
    
    func toggleCardFavorite(_ key: String, favorite: Bool, completion: @escaping () -> Void) {
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
                    userRef.setValue(["favorites": [key: true]])
                    return TransactionResult.success(withValue: currentData)
                }

            }) { (error, committed, snapshot) in
                if let snapshot = snapshot {
                    if let value = snapshot.value as? [String : Any] {
                        if let dict = value["favorites"] as? [String : Any] {
                            let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                            request.predicate = NSPredicate(format: "id IN %@", Array(dict.keys))
                            
                            if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
                                self.favorites = result
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Data monitors
    func monitorTopRated(completion: @escaping ([CMCard]) -> Void) {
        let ref = Database.database().reference().child("cards")
        let query = ref.queryOrdered(byChild: FCCard.Keys.Rating).queryStarting(atValue: 1).queryLimited(toLast: kMaxFetchTopRated)
        
        query.observe(.value, with: { snapshot in
            var cards = [CMCard]()
            
            for child in snapshot.children {
                if let c = child as? DataSnapshot {
                    let fcard = FCCard(snapshot: c)
                    let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                    request.predicate = NSPredicate(format: "id == %@", c.key)
                    
                    if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
                        if let card = result.first {
                            card.rating = fcard.rating == nil ? 0 : fcard.rating!
                            cards.append(card)
                        }
                    }
                }
            }
            
            try! ManaKit.sharedInstance.dataStack!.mainContext.save()
            
            completion(cards.sorted(by: { $0.rating > $1.rating }))
        })
        
        queries["topRated"] = query
    }

    func monitorTopViewed(completion: @escaping ([CMCard]) -> Void) {
        let ref = Database.database().reference().child("cards")
        let query = ref.queryOrdered(byChild: FCCard.Keys.Views).queryStarting(atValue: 1).queryLimited(toLast: kMaxFetchTopViewed)
        
        query.observe(.value, with: { snapshot in
            var cards = [CMCard]()
            
            for child in snapshot.children {
                if let c = child as? DataSnapshot {
                    let fcard = FCCard(snapshot: c)
                    let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                    request.predicate = NSPredicate(format: "id == %@", c.key)
                    
                    if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
                        if let card = result.first {
                            card.views = Int64(fcard.views == nil ? 0 : fcard.views!)
                            cards.append(card)
                        }
                    }
                }
            }
            
            try! ManaKit.sharedInstance.dataStack!.mainContext.save()
            completion(cards.sorted(by: { $0.views > $1.views }))
        })
        
        queries["topViewed"] = query
    }
    
    func monitorUser() {
        if let user = Auth.auth().currentUser {
            userRef = Database.database().reference().child("users").child(user.uid)
            
            userRef!.observe(.value, with: { snapshot in
                if let value = snapshot.value as? [String : Any] {
                    if let dict = value["favorites"] as? [String : Any] {
                        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                        request.predicate = NSPredicate(format: "id IN %@", Array(dict.keys))
                        
                        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
                            self.favorites = result
                        }
                    }
                }
            })
        }
    }
    
    func demonitorTopCharts() {
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
        favorites = [CMCard]()
    }
    
    // MARK: - Shared Instance
    static let sharedInstance = FirebaseManager()
}
