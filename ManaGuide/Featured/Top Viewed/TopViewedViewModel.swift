//
//  TopViewedViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import Firebase
import ManaKit
import PromiseKit
import RealmSwift

let kMaxFetchTopViewed  = 10

class TopViewedViewModel: BaseSearchViewModel {
    // MARK: Variables
    private var _results: Results<CMCard>? = nil
    private var _firebaseQuery: DatabaseQuery?
    
    override init() {
        super.init()

        sortDescriptors = [SortDescriptor(keyPath: "firebaseViews", ascending: false),
                           SortDescriptor(keyPath: "set.releaseDate", ascending: true),
                           SortDescriptor(keyPath: "name", ascending: true),
                           SortDescriptor(keyPath: "myNumberOrder", ascending: true)]
    }
    
    // MARK: Overrides
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            let predicate = NSPredicate(format: "firebaseViews > 0")
            _results = ManaKit.sharedInstance.realm.objects(CMCard.self).filter(predicate).sorted(by: sortDescriptors!)
            seal.fulfill(())
        }
    }
    
    override func numberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            guard let _ = _results else {
                return 0
            }
            
            return Int(kMaxFetchTopViewed)
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
        return kMaxFetchTopViewed
    }

    // MARK: Custom methods
    func startMonitoring() {
        let ref = Database.database().reference().child("cards")
        _firebaseQuery = ref.queryOrdered(byChild: FCCard.Keys.Views)
            .queryStarting(atValue: 1)
            .queryLimited(toLast: UInt(kMaxFetchTopViewed))
        mode = .loading
        
        // observe changes in Firebase
        _firebaseQuery!.observe(.value, with: { snapshot in
            for child in snapshot.children {
                if let c = child as? DataSnapshot {
                    let fccard = FCCard(snapshot: c)
                    let oldFBKey = c.key
                    let newFBKey = ManaKit.sharedInstance.newFirebaseKey(from: oldFBKey)
                    
                    if let card = ManaKit.sharedInstance.realm.objects(CMCard.self).filter("firebaseID = %@", newFBKey).first {
                        try! ManaKit.sharedInstance.realm.write {
                            card.firebaseViews = Int64(fccard.views == nil ? 0 : fccard.views!)
                            card.firebaseLastUpdate = Date()
                            ManaKit.sharedInstance.realm.add(card, update: true)
                            
                            if newFBKey != oldFBKey {
                                let model = CardViewModel()
                                
                                firstly {
                                    model.deleteOldFirebaseData(with: oldFBKey)
                                }.then {
                                    model.saveFirebaseData(with: newFBKey)
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
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                            object: nil,
                                            userInfo: nil)
        })
    }
    
    func stopMonitoring() {
        if _firebaseQuery != nil {
            _firebaseQuery!.removeAllObservers()
            _firebaseQuery = nil
        }
    }
}
