//
//  SetViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 25.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

enum SetContent: Int {
    case cards
    case wiki
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .cards: return "Cards"
        case .wiki: return "Wiki"
        }
    }
    
    static var count: Int {
        return 2
    }
}

class SetViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    var setContent: SetContent = .cards

    private var _set: CMSet?
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    private var _fetchedResultsController: NSFetchedResultsController<CMCard>?
    
    // MARK: Settings
    private var _sortDescriptors: [NSSortDescriptor]?
    
    // MARK: Init
    init(withSet set: CMSet) {
        super.init()
        _set = set
    }
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        var rows = 0
        
        switch setContent {
        case .cards:
            let searchGenerator = SearchRequestGenerator()
            
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
            
        case .wiki:
            rows = 2
        }
        
        return rows
    }
    
    func numberOfSections() -> Int {
        var number = 0
        
        switch setContent {
        case .cards:
            let searchGenerator = SearchRequestGenerator()

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

        case .wiki:
            number = 1
        }
        
        return number
    }
    
    func sectionIndexTitles() -> [String]? {
        var titles: [String]?
        
        switch setContent {
        case .cards:
            let searchGenerator = SearchRequestGenerator()
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
            
        case .wiki:
            ()
        }
        
        return titles
    }
    
    func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        var sectionIndex = 0
        
        switch setContent {
        case .cards:
            let searchGenerator = SearchRequestGenerator()
            
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
            
        case .wiki:
            ()
        }
        
        return sectionIndex
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        var titleHeader: String?
        
        switch setContent {
        case .cards:
            let searchGenerator = SearchRequestGenerator()
            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
                return titleHeader
            }
            
            switch displayBy {
            case "list":
                guard let fetchedResultsController = _fetchedResultsController,
                    let sections = fetchedResultsController.sections else {
                        return nil
                }
                titleHeader = sections[section].name
            case "grid":
                ()
            default:
                ()
            }
            
        case .wiki:
            ()
        }
        
        return titleHeader
    }
    
    // MARK: UICollectionView methods
    func collectionNumberOfRows(inSection section: Int) -> Int {
        var rows = 0
        
        switch setContent {
        case .cards:
            guard let fetchedResultsController = _fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                return rows
            }
            
            rows = sections[section].numberOfObjects
            
        case .wiki:
            rows = 2
        }
        
        return rows
    }
    
    func collectionNumberOfSections() -> Int {
        var number = 0
        
        switch setContent {
        case .cards:
            guard let fetchedResultsController = _fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                return number
            }
            
            number = sections.count
            
        case .wiki:
            number = 1
        }
        
        return number
    }
    
    func collectionSectionIndexTitles() -> [String]? {
        return _sectionIndexTitles
    }
    
    func collectionSectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        var sectionIndex = 0
        
        switch setContent {
        case .cards:
            let searchGenerator = SearchRequestGenerator()
            
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
        case .wiki:
            ()
        }
        
        return sectionIndex
    }
    
    func collectionTitleForHeaderInSection(section: Int) -> String? {
        var titleHeader: String?
        
        switch setContent {
        case .cards:
            guard let fetchedResultsController = _fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                    return nil
            }
            titleHeader = sections[section].name
            
        case .wiki:
            ()
        }
        
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
    
    func fetchData() {
        guard let set = _set else {
            fatalError("_set is nil")
        }
        
        let oldRequest: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        oldRequest.predicate = NSPredicate(format: "set.code = %@", set.code!)
        let request = SearchRequestGenerator().createSearchRequest(query: queryString, oldRequest: oldRequest)
        
        _fetchedResultsController = getFetchedResultsController(with: request)
        updateSections()
    }
    
    // MARK: Presentation methods
    func setTitle() -> String? {
        guard let set = _set else {
            return nil
        }
        return set.name
    }
    
    func wikiURL() -> URL? {
        guard let set = _set else {
            return nil
        }
        
        var path = ""
        
        if let name = set.name,
            let code = set.code {
            
            if code == "LEA" {
                path = "Alpha"
            } else if code == "LEB" {
                path = "Beta"
            } else {
                path = name.replacingOccurrences(of: " and ", with: " & ")
                    .replacingOccurrences(of: " ", with: "_")
            }
        }
        
        return URL(string: "https://mtg.gamepedia.com/\(path)")
    }

    private func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMCard>?) -> NSFetchedResultsController<CMCard> {
        guard let set = _set,
            let code = set.code else {
                fatalError("Set is nil")
        }
        
        let searchGenerator = SearchRequestGenerator()
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMCard>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // create a default fetchRequest
            request = CMCard.fetchRequest()
            request!.predicate = NSPredicate(format: "set.code = %@", code)
            request!.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),
                                        NSSortDescriptor(key: "number", ascending: true),
                                        NSSortDescriptor(key: "mciNumber", ascending: true)]
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
    
    func updateSections() {
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
                prefix = card.nameSection
            case "number":
                _sectionIndexTitles = nil
                _sectionTitles = nil
                return
            case "type":
                prefix = String(card.typeSection!.prefix(1))
            case "rarity":
                if let rarity = card.rarity_ {
                    prefix = String(rarity.name!.prefix(1))
                }
            case "artist":
                if let artist = card.artist_ {
                    prefix = String(artist.name!.prefix(1))
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
extension SetViewModel : NSFetchedResultsControllerDelegate {
    
}
