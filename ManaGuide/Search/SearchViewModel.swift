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

enum SearchViewModelMode: Int {
    case standBy
    case loading
    case noResultsFound
    case resultsFound
    case error
    
    var cardArt: [String: String]? {
        switch self {
        case .standBy:
            return ["setCode": "leb",
                    "name": "Library of Leng"]
        case .loading:
            return ["setCode": "vma",
                    "name": "Frantic Search"]
        case .noResultsFound:
            return ["setCode": "leg",
                    "name": "Lost Soul"]
        case .resultsFound:
            return nil
        case .error:
            return ["setCode": "plc",
                    "name": "Dismal Failure"]
        }
    }
    
    var description : String? {
        switch self {
        // Use Internationalization, as appropriate.
        case .standBy: return "Ready"
        case .loading: return "Loading..."
        case .noResultsFound: return "No data found"
        case .resultsFound: return nil
        case .error: return "nil"
        }
    }
}

class SearchViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    var searchCancelled = false
    var mode: SearchViewModelMode = .loading

    private var _request: NSFetchRequest<CMCard>?
    private var _title: String?
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    private var _fetchedResultsController: NSFetchedResultsController<CMCard>?
    
    // MARK: Settings
    private var _sortDescriptors: [NSSortDescriptor]?
    
    // MARK: Init
    init(withRequest request: NSFetchRequest<CMCard>?, andTitle title: String?, andMode mode: SearchViewModelMode) {
        super.init()
        _request = request
        _title = title
        self.mode = mode
    }
    
    // MARK: Presentation methods
    func getSearchTitle() -> String? {
        return _title
    }

    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        let searchGenerator = SearchRequestGenerator()
        var rows = 0

        guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
            return rows
        }
        
        switch displayBy {
        case "list":
            guard let fetchedResultsController = _fetchedResultsController,
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
    }
    
    func numberOfSections() -> Int {
        let searchGenerator = SearchRequestGenerator()
        var number = 0
        
        guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
            return number
        }
        
        switch displayBy {
        case "list":
            guard let fetchedResultsController = _fetchedResultsController,
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
    }
    
    func sectionIndexTitles() -> [String]? {
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
    }
    
    func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
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
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        let searchGenerator = SearchRequestGenerator()
        var titleHeader: String?
        
        guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
            return titleHeader
        }
        
        switch displayBy {
        case "list":
            guard let fetchedResultsController = _fetchedResultsController,
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
    }
    
    // MARK: UICollectionView methods
    func collectionNumberOfRows(inSection section: Int) -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
            return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    func collectionNumberOfSections() -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
            return 0
        }
        
        return sections.count
    }
    
    func collectionSectionIndexTitles() -> [String]? {
        return _sectionIndexTitles
    }
    
    func collectionSectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        let searchGenerator = SearchRequestGenerator()
        var sectionIndex = 0
        
        guard let orderBy = searchGenerator.displayValue(for: .orderBy) as? Bool,
            let sectionTitles = _sectionTitles else {
                return sectionIndex
        }
        
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
        
        return sectionIndex
    }
    
    func collectionTitleForHeaderInSection(section: Int) -> String? {
        var titleHeader: String?
        
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return nil
        }
        titleHeader = sections[section].name
        
        return titleHeader
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

    func fetchData() -> Promise<Void> {
        return Promise { seal  in
            let newRequest = SearchRequestGenerator().createSearchRequest(query: queryString, oldRequest: _request)
            _fetchedResultsController = getFetchedResultsController(with: newRequest)
            updateSections()
            
            seal.fulfill(())
        }
    }
    
    // MARK: Private methods
    private func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMCard>?) -> NSFetchedResultsController<CMCard> {
        let searchGenerator = SearchRequestGenerator()
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMCard>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // create a default fetchRequest
            request = CMCard.fetchRequest()
            request?.fetchBatchSize = 20
            request!.predicate = NSPredicate(format: "language.code = %@", "en")
            request!.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),
                                        NSSortDescriptor(key: "collectorNumber", ascending: true)]
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
        
        return frc
    }
    
    private func updateSections() {
        guard let fetchedResultsController = _fetchedResultsController,
            let cards = fetchedResultsController.fetchedObjects,
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
                if let type = card.typeLine {
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

// MARK: NSFetchedResultsControllerDelegate
extension SearchViewModel : NSFetchedResultsControllerDelegate {
    
}
