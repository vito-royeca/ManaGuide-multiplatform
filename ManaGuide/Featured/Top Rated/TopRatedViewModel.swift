//
//  TopRatedViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import CoreData
import Firebase
import ManaKit
import PromiseKit

let kMaxFetchTopRated  = UInt(10)

class TopRatedViewModel: NSObject {
    // MARK: Variables
    let sortDescriptors = [NSSortDescriptor(key: "firebaseRating", ascending: false),
                           NSSortDescriptor(key: "name", ascending: true),
                           NSSortDescriptor(key: "set.releaseDate", ascending: true),
                           NSSortDescriptor(key: "collectorNumber", ascending: true)]
    
    private var _fetchedResultsController: NSFetchedResultsController<CMCard>?
    private var _firebaseQuery: DatabaseQuery?
    
    // MARK: Overrides
    override init() {
        super.init()
    }
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    func numberOfSections() -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return 0
        }
        
        return sections.count
    }
    
    func sectionIndexTitles() -> [String]? {
        return nil
    }
    
    func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        return 0
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        return nil
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> CMCard {
        guard let fetchedResultsController = _fetchedResultsController else {
            fatalError("fetchedResultsController is nil")
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    func allObjects() -> [CMCard]? {
        guard let fetchedResultsController = _fetchedResultsController else {
            return nil
        }
        return fetchedResultsController.fetchedObjects
    }
    
    func isEmpty() -> Bool {
        guard let objects = allObjects() else {
            return true
        }
        return objects.count == 0
    }
    
    func fetchRemoteData() -> Promise<Void> {
        return Promise { seal in
            let ref = Database.database().reference().child("cards")
            _firebaseQuery = ref.queryOrdered(byChild: FCCard.Keys.Rating).queryStarting(atValue: 1).queryLimited(toLast: kMaxFetchTopRated)
            
            ref.keepSynced(true)
            
            // observe changes in Firebase
            _firebaseQuery!.observe(.value, with: { snapshot in
                for child in snapshot.children {
                    if let c = child as? DataSnapshot {
                        let fcard = FCCard(snapshot: c)
                
                        
                        if let card = ManaKit.sharedInstance.findObject("CMCard",
                                                                        objectFinder: ["firebaseID": c.key as AnyObject],
                                                                        createIfNotFound: false) as? CMCard {
                            card.firebaseRating = fcard.rating == nil ? 0 : fcard.rating!
                            card.firebaseRatings = fcard.ratings == nil ? Int32(0) : Int32(fcard.ratings!.count)
                        }
                    }
                }
                
                ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                    // save to Core Data
                    try! backgroundContext.save()
                    
                    seal.fulfill(())
                }
            })
        }
    }
    
    func fetchData() {
        // refresh data
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "firebaseRating > 0")
        request.fetchLimit = 10
        request.sortDescriptors = self.sortDescriptors
        self._fetchedResultsController = self.getFetchedResultsController(with: request)
    }
    
    func stopMonitoring() {
        let ref = Database.database().reference().child("cards")
        ref.keepSynced(false)
        
        if _firebaseQuery != nil {
            _firebaseQuery!.removeAllObservers()
            _firebaseQuery = nil
        }
    }
    
    private func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMCard>?) -> NSFetchedResultsController<CMCard> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMCard>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
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
        
        return frc
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension TopRatedViewModel : NSFetchedResultsControllerDelegate {
    
}
