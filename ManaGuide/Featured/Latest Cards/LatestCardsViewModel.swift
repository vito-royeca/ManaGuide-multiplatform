//
//  LatestCardsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import ManaKit
import PromiseKit
import RealmSwift

let kMaxLatestCards = 10

class LatestCardsViewModel: BaseSearchViewModel {
    private var _results: Results<CMCard>? = nil
    
    override init() {
        super.init()
        
        sortDescriptors = [SortDescriptor(keyPath: "set.releaseDate", ascending: false)]
    }
    
    // MARK: Overrides
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            var mids = [String]()
            
            // Get random IDs first
            var predicate = NSPredicate(format: "language.code = %@ AND imageURIs != nil AND set.code IN %@ AND id != nil",
                                        "en",
                                        fetchLatestSets().map( { $0.code} ))
            _results = ManaKit.sharedInstance.realm.objects(CMCard.self).filter(predicate).sorted(by: sortDescriptors!)
            
            repeat {
                let card = _results![Int(arc4random_uniform(UInt32(_results!.count)))]
                if !mids.contains(card.id!) {
                    mids.append(card.id!)
                }
            } while mids.count < kMaxLatestCards
            
            // then fetch with the random CMCards
            predicate = NSPredicate(format: "id IN %@",
                                    mids)
            _results = ManaKit.sharedInstance.realm.objects(CMCard.self).filter(predicate).sorted(by: sortDescriptors!)
            seal.fulfill(())
        }
    }
    
    override func numberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            return kMaxLatestCards
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
    private func fetchLatestSets() -> [CMSet] {
        var sets = [CMSet]()
        var count = 0
        
        let sortDescriptors = [SortDescriptor(keyPath: "releaseDate", ascending: false)]
        for set in ManaKit.sharedInstance.realm.objects(CMSet.self).filter("parent = nil").sorted(by: sortDescriptors) {
            if count >= kMaxLatestSets {
                break
            }
            sets.append(set)
            count += 1
        }
        return sets
    }
}

