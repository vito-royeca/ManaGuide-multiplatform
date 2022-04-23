//
//  LatestSetsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import ManaKit
import PromiseKit
import RealmSwift

let kMaxLatestSets = 10

class LatestSetsViewModel: BaseSearchViewModel {
    private var _results: Results<CMSet>? = nil

    override init() {
        super.init()
        
        sortDescriptors = [SortDescriptor(keyPath: "releaseDate", ascending: false)]
    }
    
    // MARK: Overrides
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            _results = ManaKit.sharedInstance.realm.objects(CMSet.self).filter("parent = nil AND cardCount > 0").sorted(by: sortDescriptors!)
            seal.fulfill(())
        }
    }
    
    override func numberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            return kMaxLatestSets
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
}
