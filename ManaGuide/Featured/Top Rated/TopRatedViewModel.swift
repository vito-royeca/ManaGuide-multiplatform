//
//  TopRatedViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import Firebase
import ManaKit
import PromiseKit
import RealmSwift

let kMaxFetchTopRated  = UInt(10)

class TopRatedViewModel: BaseSearchViewModel {
    // MARK: Variables
    private var _results: Results<CMCard>? = nil
    private var _firebaseQuery: DatabaseQuery?
    
    override init() {
        super.init()
        
        sortDescriptors = [SortDescriptor(keyPath: "firebaseRating", ascending: false),
                           SortDescriptor(keyPath: "set.releaseDate", ascending: true),
                           SortDescriptor(keyPath: "name", ascending: true),
                           SortDescriptor(keyPath: "myNumberOrder", ascending: true)]
    }
    
    // MARK: Overrides
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            let predicate = NSPredicate(format: "firebaseRating > 0")
            _results = ManaKit.sharedInstance.realm.objects(CMCard.self).filter(predicate).sorted(by: sortDescriptors!)
            seal.fulfill(())
        }
    }

    override func numberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            guard let _ = _results else {
                return 0
            }
            
            return Int(kMaxFetchTopRated)
        } else {
            return 1
        }
    }
    
    override func numberOfSections() -> Int {
        return 1
    }
    
    override func object(forRowAt indexPath: IndexPath) -> Object? {
        guard let results = _results else {
            return nil
        }
        return results[indexPath.row]
    }
    
    override func count() -> Int {
        guard let results = _results else {
            return 0
        }
        return results.count
    }

    // MARK: Custom methods
    func startMonitoring() {
        let ref = Database.database().reference().child("cards")
        _firebaseQuery = ref.queryOrdered(byChild: FCCard.Keys.Rating).queryStarting(atValue: 1).queryLimited(toLast: kMaxFetchTopRated)
        mode = .loading
        
        // observe changes in Firebase
        _firebaseQuery!.observe(.value, with: { snapshot in
            /*var fcards = [FCCard]()
            
            for child in snapshot.children {
                if let c = child as? DataSnapshot {
                    fcards.append(FCCard(snapshot: c))
                }
            }
            
            // save to Realm
            let predicate = NSPredicate(format: "firebaseID IN %@", fcards.map { $0.key })
            try! ManaKit.sharedInstance.realm.write {
                for card in ManaKit.sharedInstance.realm.objects(CMCard.self).filter(predicate) {
                    for fcard in fcards {
                        if card.firebaseID == fcard.key {
                            card.firebaseRating = fcard.rating == nil ? 0 : fcard.rating!
                            
                            card.firebaseLastUpdate = Date()
                            ManaKit.sharedInstance.realm.add(card, update: true)
                        }
                    }
                }

                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                object: nil,
                                                userInfo: nil)
            }*/
            for child in snapshot.children {
                if let c = child as? DataSnapshot {
                    let fccard = FCCard(snapshot: c)
                    let oldFBKey = c.key
                    let newFBKey = self.newFirebaseKey(from: oldFBKey)
                    
                    if let card = ManaKit.sharedInstance.realm.objects(CMCard.self).filter("firebaseID = %@", newFBKey).first {
                        try! ManaKit.sharedInstance.realm.write {
                            card.firebaseRating = fccard.rating == nil ? 0 : fccard.rating!
                            card.firebaseRating = fccard.rating == nil ? 0 : fccard.rating!
                            if let ratings = fccard.ratings {
                                for (k,v) in ratings {
                                    var user: CMUser?
                                    var cardRating: CMCardRating?
                                    
                                    if let u = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", k).first {
                                        user = u
                                    } else {
                                        user = CMUser()
                                        user!.id = k
                                    }
                                    ManaKit.sharedInstance.realm.add(user!)
                                    
                                    if let u = ManaKit.sharedInstance.realm.objects(CMCardRating.self).filter("user.id = %@ AND card.id = %@", k, card.id!).first {
                                        cardRating = u
                                    } else {
                                        cardRating = CMCardRating()
                                    }
                                    cardRating!.card = card
                                    cardRating!.user = user
                                    cardRating!.rating = v
                                    ManaKit.sharedInstance.realm.add(cardRating!)
                                    card.firebaseUserRatings.append(cardRating!)
                                }
                            }
                            card.firebaseLastUpdate = Date()
                            ManaKit.sharedInstance.realm.add(card, update: true)
                            
                            if newFBKey != oldFBKey {
                                let model = CardViewModel()
                                let deletePromise = model.deleteOldFirebaseData(with: oldFBKey)
                                let data = model.firebaseData(with: newFBKey)
                                
                                firstly {
                                    model.saveFirebaseData(with: newFBKey,
                                                           data: data,
                                                           firstAttempt: true,
                                                           completion: deletePromise)
                                    }.done {
                                        print("Done deleteing oldFBKey: \(oldFBKey)")
                                    }.catch { error in
                                        print(error)
                                }
                            }
                        }
                    } else {
                        let model = CardViewModel()
                        
                        print("Deleteing oldFBKey: \(oldFBKey)")
                        firstly {
                            model.deleteOldFirebaseData(with: oldFBKey)
                            }.done {
                                print("Done deleteing oldFBKey: \(oldFBKey)")
                            }.catch { error in
                                print(error)
                        }
                    }
                }
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                            object: nil,
                                            userInfo: nil)
        })
    }
    
    func stopMonitoring() {
//        let ref = Database.database().reference().child("cards")
//        ref.keepSynced(false)
        
        if _firebaseQuery != nil {
            _firebaseQuery!.removeAllObservers()
            _firebaseQuery = nil
        }
    }
}
