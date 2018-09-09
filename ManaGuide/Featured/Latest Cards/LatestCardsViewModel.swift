//
//  LatestCardsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

let kMaxLatestCards = 10

class LatestCardsViewModel: NSObject {
    // MARK: Variables
    private var _cardMIDs = [NSManagedObjectID]()
    
    // MARK: Custom methods
    func numberOfItems() -> Int {
        return _cardMIDs.count
    }
    
    func objectAt(_ index: Int) -> CMCard {
        guard let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: _cardMIDs[index]) as? CMCard else {
            fatalError("card not found")
        }
        
        return card
    }
    
    func fetchData() {
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        let sets = fetchLatestSets()
        
        request.predicate = NSPredicate(format: "multiverseid != 0 AND set.code IN %@", sets.map( { $0.code} ))
        _cardMIDs = [NSManagedObjectID]()
        let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
        
        repeat {
            let card = result[Int(arc4random_uniform(UInt32(result.count)))]
            let cardMID = card.objectID
            if !_cardMIDs.contains(cardMID) {
                _cardMIDs.append(cardMID)
            }
        } while _cardMIDs.count <= kMaxLatestCards
    }
    
    private func fetchLatestSets() -> [CMSet] {
        let request: NSFetchRequest<CMSet> = CMSet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = kMaxLatestSets
        
        return try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
    }
}

