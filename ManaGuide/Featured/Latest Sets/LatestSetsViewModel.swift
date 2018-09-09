//
//  LatestSetsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

let kMaxLatestSets = 10

class LatestSetsViewModel: NSObject {
    // MARK: Variables
    private var _sets = [CMSet]()
    
    // MARK: Custom methods
    func numberOfItems() -> Int {
        return _sets.count
    }
    
    func objectAt(_ index: Int) -> CMSet {
        return _sets[index]
    }
    
    func fetchData() {
        let request: NSFetchRequest<CMSet> = CMSet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = kMaxLatestSets
        
        _sets = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
    }
}
