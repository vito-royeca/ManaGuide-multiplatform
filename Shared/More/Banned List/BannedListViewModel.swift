//
//  BannedListViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import ManaKit
import PromiseKit

class BannedListViewModel: BaseSearchViewModel {
    // MARK: Variables
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    
    override init() {
        super.init()
        
        sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        sectionName = "nameSection"
    }
    
    // MARK: Custom methods
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            let request: NSFetchRequest<CMCardFormat> = CMCardFormat.fetchRequest()
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
            request.sortDescriptors = sortDescriptors

            fetchedResultsController = getFetchedResultsController(with: request as? NSFetchRequest<NSManagedObject>)
            updateSections()
            seal.fulfill(())
        }
    }
    
    override func updateSections() {
        guard let fetchedResultsController = fetchedResultsController,
            let formats = fetchedResultsController.fetchedObjects as? [CMCardFormat],
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
