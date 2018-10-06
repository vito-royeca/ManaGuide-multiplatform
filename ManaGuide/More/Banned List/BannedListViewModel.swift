//
//  BannedListViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

class BannedListViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    private var _fetchedResultsController: NSFetchedResultsController<CMFormat>?
    
    private let _sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    private let _sectionName = "nameSection"
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        var rows = 0
        
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
            return rows
        }
        rows = sections[section].numberOfObjects
        
        return rows
    }
    
    func numberOfSections() -> Int {
        var number = 0
        
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return number
        }
        
        number = sections.count
        
        return number
    }
    
    func sectionIndexTitles() -> [String]? {
        return _sectionIndexTitles
    }
    
    func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        var sectionIndex = 0
        
        guard let sectionTitles = _sectionTitles else {
            return sectionIndex
        }
        
        for i in 0...sectionTitles.count - 1 {
            if sectionTitles[i].hasPrefix(title) {
                sectionIndex = i
                break
            }
        }
        
        return sectionIndex
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        var titleHeader: String?
        
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return titleHeader
        }
        titleHeader = sections[section].name
        
        return titleHeader
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> CMFormat {
        guard let fetchedResultsController = _fetchedResultsController else {
            fatalError("fetchedResultsController is nil")
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    func allObjects() -> [CMFormat]? {
        guard let fetchedResultsController = _fetchedResultsController else {
            return nil
        }
        return fetchedResultsController.fetchedObjects
    }
    
    func isEmpty() -> Bool {
        guard let objects = allObjects() else {
            return false
        }
        return objects.count == 0
    }

    func fetchData() {
        let request: NSFetchRequest<CMFormat> = CMFormat.fetchRequest()
        let count = queryString.count
        var predicate = NSPredicate(format: "ANY cardLegalities.legality.name IN %@", ["Banned", "Restricted"])
        
        if count > 0 {
            if count == 1 {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, NSPredicate(format: "name BEGINSWITH[cd] %@", queryString)])
            } else {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, NSPredicate(format: "name CONTAINS[cd] %@", queryString)])
            }
        }
        request.predicate = predicate
        request.sortDescriptors = _sortDescriptors
        
        _fetchedResultsController = getFetchedResultsController(with: request)
        updateSections()
    }
    
    // MARK: Private methods
    private func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMFormat>?) -> NSFetchedResultsController<CMFormat> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMFormat>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // create a default fetchRequest
            request = CMFormat.fetchRequest()
            request!.predicate = NSPredicate(format: "ANY cardLegalities.legality.name IN %@", ["Banned", "Restricted"])
            request!.sortDescriptors = _sortDescriptors
        }
        
        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: request!,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: _sectionName,
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
    
    private func updateSections() {
        guard let fetchedResultsController = _fetchedResultsController,
            let formats = fetchedResultsController.fetchedObjects,
            let sections = fetchedResultsController.sections else {
                return
        }
        _sectionIndexTitles = [String]()
        _sectionTitles = [String]()
        
        for format in formats {
            if let name = format.name {
                let prefix = String(name.prefix(1))
                
                if !_sectionIndexTitles!.contains(prefix) {
                    _sectionIndexTitles!.append(prefix)
                }
            }
        }
        
        let count = sections.count
        if count > 0 {
            for i in 0...count - 1 {
                if let sectionTitle = sections[i].indexTitle {
                    _sectionTitles!.append(sectionTitle)
                }
            }
        }
        
        _sectionIndexTitles!.sort()
        _sectionTitles!.sort()
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension BannedListViewModel : NSFetchedResultsControllerDelegate {
    
}
