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

let kMaxFetchTopViewed = UInt(15)
let kMaxFetchTopRated  = UInt(15)
let kCardViewUpdatedNotification = "kCardViewUpdatedNotification"

class FirebaseManager: NSObject {
    var queries = [String: DatabaseQuery]()
    var online = false
    
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
                ref.setValue([FCCard.Keys.Rating: Double(0),
                              FCCard.Keys.Views: 1])
            }
            
            return TransactionResult.success(withValue: currentData)
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
            
            completion(cards)
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
            completion(cards)
        })
        
        queries["topViewed"] = query
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
    
    // MARK: - Shared Instance
    static let sharedInstance = FirebaseManager()
}
