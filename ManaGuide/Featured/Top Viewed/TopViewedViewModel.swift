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

class TopViewedViewModel: BaseSearchViewModel {
    // MARK: Variables
    private var _firebaseQuery: DatabaseQuery?
    
    override init() {
        super.init()

        sortDescriptors = [NSSortDescriptor(key: "firebaseViews", ascending: false),
                           NSSortDescriptor(key: "set.releaseDate", ascending: true),
                           NSSortDescriptor(key: "name", ascending: true),
                           NSSortDescriptor(key: "myNumberOrder", ascending: true)]
    }
    
    // MARK: Overrides
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            request.predicate = NSPredicate(format: "firebaseViews > 0")
            request.fetchLimit = 10
            request.sortDescriptors = sortDescriptors
            fetchedResultsController = getFetchedResultsController(with: request as? NSFetchRequest<NSManagedObject>)
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

    // MARK: Custom methods
    func startMonitoring() {
        let ref = Database.database().reference().child("cards")
        _firebaseQuery = ref.queryOrdered(byChild: FCCard.Keys.Views).queryStarting(atValue: 1).queryLimited(toLast: kMaxFetchTopViewed)
        mode = .loading
        
        // observe changes in Firebase
        _firebaseQuery!.observe(.value, with: { snapshot in
            var fcards = [FCCard]()
            
            for child in snapshot.children {
                if let c = child as? DataSnapshot {
                    fcards.append(FCCard(snapshot: c))
                }
            }

            // save to Core Data
            let context = ManaKit.sharedInstance.dataStack!.viewContext
            let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            request.predicate = NSPredicate(format: "firebaseID IN %@", fcards.map { $0.key })
            let cards = try! context.fetch(request)
            
            ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                for card in cards {
                    for fcard in fcards {
                        if card.firebaseID == fcard.key {
                            card.firebaseViews = Int64(fcard.views == nil ? 0 : fcard.views!)
                        }
                    }
                }
                try! backgroundContext.save()

                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                                object: nil,
                                                userInfo: nil)
            }
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
