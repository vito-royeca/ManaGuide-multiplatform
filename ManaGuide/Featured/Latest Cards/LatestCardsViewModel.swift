//
//  LatestCardsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit
import PromiseKit

let kMaxLatestCards = 10

class LatestCardsViewModel: BaseSearchViewModel {
    override init() {
        super.init()
        
        sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: false)]
    }
    
    // MARK: Custom methods
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            let sets = fetchLatestSets()
            var mids = [NSManagedObjectID]()
            
            // get random ManagedObjectIDs first
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CMCard")
            request.predicate = NSPredicate(format: "language.code = %@ AND imageURIs != nil AND set.code IN %@ AND id != nil", "en",
                                            sets.map( { $0.code} ))
            request.resultType = NSFetchRequestResultType.managedObjectIDResultType
            request.sortDescriptors = sortDescriptors
            let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
            repeat {
                if let mid = result[Int(arc4random_uniform(UInt32(result.count)))] as? NSManagedObjectID {
                    if !mids.contains(mid) {
                        mids.append(mid)
                    }
                }
            } while mids.count < kMaxLatestCards
            
            // then fetch with the random CMCards
            let newRequest: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            newRequest.predicate = NSPredicate(format: "self IN %@", mids)
            newRequest.sortDescriptors = sortDescriptors
            fetchedResultsController = getFetchedResultsController(with: newRequest as? NSFetchRequest<NSManagedObject>)
            seal.fulfill(())
        }
    }
    
    override func getFetchedResultsController(with fetchRequest: NSFetchRequest<NSManagedObject>?) -> NSFetchedResultsController<NSManagedObject> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMCard>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest as? NSFetchRequest<CMCard>
        } else {
            // Create a default fetchRequest
            request = CMCard.fetchRequest()
            request!.sortDescriptors = sortDescriptors
        }
        
        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: request!,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        
        // Configure Fetched Results Controller
        frc.delegate = self
        
        // perform fetch
        do {
            try frc.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        return frc as! NSFetchedResultsController<NSManagedObject>
    }
    
    private func fetchLatestSets() -> [CMSet] {
        let request: NSFetchRequest<CMSet> = CMSet.fetchRequest()
        request.predicate = NSPredicate(format: "parent = nil")
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = kMaxLatestSets
        
        return try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
    }
}

