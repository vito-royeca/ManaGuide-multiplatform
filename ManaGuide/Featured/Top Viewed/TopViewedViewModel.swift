//
//  TopViewedViewModel.swift
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

let kMaxFetchTopViewed  = UInt(10)

class TopViewedViewModel: NSObject {
    // MARK: Variables
    private var _fetchedResultsController: NSFetchedResultsController<CMCard>?
    private var firebaseQuery: DatabaseQuery?
    
    // MARK: Settings
    private let _sortDescriptors = [NSSortDescriptor(key: "views", ascending: false),
                                    NSSortDescriptor(key: "name", ascending: true),
                                    NSSortDescriptor(key: "set.releaseDate", ascending: true),
                                    NSSortDescriptor(key: "number", ascending: true)]
    
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
    
    func fetchData() {
        let ref = Database.database().reference().child("cards")
        firebaseQuery = ref.queryOrdered(byChild: FCCard.Keys.Rating).queryStarting(atValue: 1).queryLimited(toLast: kMaxFetchTopRated)
        
        ref.keepSynced(true)
        
        // observe changes in Firebase
        firebaseQuery!.observe(.value, with: { snapshot in
            for child in snapshot.children {
                if let c = child as? DataSnapshot {
                    let fcard = FCCard(snapshot: c)
                    
                    
                    if let card = ManaKit.sharedInstance.findObject("CMCard",
                                                                    objectFinder: ["id": c.key as AnyObject],
                                                                    createIfNotFound: false) as? CMCard {
                        card.views = Int64(fcard.views == nil ? 0 : fcard.views!)
                    }
                }
            }
            
            ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                // save to Core Data
                try! backgroundContext.save()
            
                // refresh data
                let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                request.predicate = NSPredicate(format: "views > 0")
                request.fetchLimit = 10
                request.sortDescriptors = self._sortDescriptors
                self._fetchedResultsController = self.getFetchedResultsController(with: request)
                
                // notify changes
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                object: nil,
                                                userInfo: nil)
            }
        })
    }
    
    func stopMonitoring() {
        let ref = Database.database().reference().child("cards")
        ref.keepSynced(false)
        
        if firebaseQuery != nil {
            firebaseQuery!.removeAllObservers()
            firebaseQuery = nil
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
            request!.sortDescriptors = _sortDescriptors
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
extension TopViewedViewModel : NSFetchedResultsControllerDelegate {
    
}
