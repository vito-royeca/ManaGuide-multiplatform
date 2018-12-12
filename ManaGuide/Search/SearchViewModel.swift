//
//  SearchViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit
import PromiseKit

class SearchViewModel: BaseSearchViewModel {
    // MARK: Variables
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    
    // MARK: Init
    init(withTitle title: String?, andMode mode: ViewModelMode) {
        super.init()
        
        self.title = title
        self.mode = mode
    }

    init(withRequest request: NSFetchRequest<CMCard>?, andTitle title: String?, andMode mode: ViewModelMode) {
        super.init()
        
        self.request = request as? NSFetchRequest<NSManagedObject>
        self.title = title
        self.mode = mode
    }
    
    // MARK: UITableView methods
    override func numberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            var rows = 0

            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
                return rows
            }
            
            switch displayBy {
            case "list":
                guard let fetchedResultsController = fetchedResultsController,
                    let sections = fetchedResultsController.sections else {
                    return rows
                }
                rows = sections[section].numberOfObjects
                
            case "grid":
                rows = 1
            default:
                ()
            }
            
            return rows
        } else {
            return 1
        }
    }
    
    override func numberOfSections() -> Int {
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            var number = 0
            
            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
                return number
            }
            
            switch displayBy {
            case "list":
                guard let fetchedResultsController = fetchedResultsController,
                    let sections = fetchedResultsController.sections else {
                    return number
                }
                number = sections.count
                
            case "grid":
                number = 1
                
            default:
                ()
            }
            
            return number
        } else {
            return 1
        }
    }
    
    override func sectionIndexTitles() -> [String]? {
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            var titles: [String]?
            
            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
                return titles
            }
            
            switch displayBy {
            case "list":
                titles = _sectionIndexTitles
            case "grid":
                ()
            default:
                ()
            }
            
            return titles
        } else {
            return nil
        }
    }
    
    override func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            var sectionIndex = 0
            
            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String,
                let orderBy = searchGenerator.displayValue(for: .orderBy) as? Bool,
                let sectionTitles = _sectionTitles else {
                    return sectionIndex
            }
            
            switch displayBy {
            case "list":
                for i in 0...sectionTitles.count - 1 {
                    if sectionTitles[i].hasPrefix(title) {
                        if orderBy {
                            sectionIndex = i
                        } else {
                            sectionIndex = (sectionTitles.count - 1) - i
                        }
                        break
                    }
                }
            case "grid":
                ()
            default:
                ()
            }
            return sectionIndex

        } else {
            return 0
        }
    }
    
    override func titleForHeaderInSection(section: Int) -> String? {
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            var titleHeader: String?
            
            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
                return titleHeader
            }
            
            switch displayBy {
            case "list":
                guard let fetchedResultsController = fetchedResultsController,
                    let sections = fetchedResultsController.sections else {
                    return titleHeader
                }
                titleHeader = sections[section].name
            case "grid":
                ()
            default:
                ()
            }
            
            return titleHeader
        } else {
            return nil
        }
    }
    
    // MARK: Custom methods
    override func fetchData() -> Promise<Void> {
        return Promise { seal  in
            let newRequest = SearchRequestGenerator().createSearchRequest(query: queryString, oldRequest: request as? NSFetchRequest<CMCard>)
            fetchedResultsController = getFetchedResultsController(with: newRequest as? NSFetchRequest<NSManagedObject>)
            updateSections()
            seal.fulfill(())
        }
    }
    
    // MARK: Private methods
    override func getFetchedResultsController(with fetchRequest: NSFetchRequest<NSManagedObject>?) -> NSFetchedResultsController<NSManagedObject> {
        let searchGenerator = SearchRequestGenerator()
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMCard>?

        if let fetchRequest = fetchRequest {
            request = fetchRequest as? NSFetchRequest<CMCard>
        } else {
            // create a default fetchRequest
            request = CMCard.fetchRequest()
            request!.fetchBatchSize = 20
            request!.predicate = NSPredicate(format: "language.code = %@", "en")
            request!.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                        NSSortDescriptor(key: "name", ascending: true),
                                        NSSortDescriptor(key: "myNumberOrder", ascending: true)]
        }

        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: request!,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: searchGenerator.getSectionName(),
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
    
    override func updateSections() {
        guard let fetchedResultsController = fetchedResultsController,
            let cards = fetchedResultsController.fetchedObjects as? [CMCard],
            let sections = fetchedResultsController.sections else {
            return
        }
        
        let searchGenerator = SearchRequestGenerator()
        let sortBy = searchGenerator.displayValue(for: .sortBy) as? String
        
        _sectionIndexTitles = [String]()
        _sectionTitles = [String]()
        
        for card in cards {
            var prefix: String?
            
            switch sortBy {
            case "name":
                prefix = card.myNameSection
            case "number":
                _sectionIndexTitles = nil
                _sectionTitles = nil
                return
            case "type":
                if let type = card.myType {
                    prefix = type.nameSection
                }
            case "rarity":
                if let rarity = card.rarity {
                    prefix = rarity.nameSection
                }
            case "artist":
                if let artist = card.artist {
                    prefix = artist.nameSection
                }
            default:
                ()
            }
            
            if let prefix = prefix {
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

