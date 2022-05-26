//
//  SearchViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import ManaKit
import PromiseKit
import RealmSwift

class SearchViewModel: BaseSearchViewModel {
    private var _results: Results<CMCard>? = nil
    
    // MARK: UITableViewDataSource methods
    override func numberOfRows(inSection section: Int) -> Int {
        var rows = 1
        
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()

            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String,
                let sortBy = searchGenerator.displayValue(for: .sortBy) as? String else {
                return rows
            }
            
            switch displayBy {
            case "list":
                guard let results = _results,
                    let sectionTitles = _sectionTitles else {
                    return rows
                }
                
                switch sortBy {
                case "name":
                    rows = results.filter("myNameSection == %@", sectionTitles[section]).count
                case "number",
                     "collectorNumber":
                    rows = results.count
                case "type":
                    rows = results.filter("myType.name == %@", sectionTitles[section]).count
                case "rarity":
                    rows = results.filter("rarity.name == %@", sectionTitles[section]).count
                case "artist":
                    rows = results.filter("artist.name == %@", sectionTitles[section]).count
                default:
                    ()
                }
                
            case "grid":
                rows = 1
            default:
                ()
            }
        }
        
        return rows
    }
    
    override func numberOfSections() -> Int {
        var sections = 1
        
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String,
                let sortBy = searchGenerator.displayValue(for: .sortBy) as? String else {
                return sections
            }
            
            switch displayBy {
            case "list":
                guard let _ = _results,
                    let sectionTitles = _sectionTitles else {
                    return sections
                }
                
                if sortBy == "number" ||
                    sortBy == "collectorNumber" {
                    sections = 1
                } else {
                    sections = sectionTitles.count
                }
                
            case "grid":
                sections = 1
                
            default:
                ()
            }
        }
        
        return sections
    }
    
    override func sectionIndexTitles() -> [String]? {
        var titles: [String]?
        
        if mode == .resultsFound {
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
        }
        
        return titles
    }
    
    override func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        var sectionIndex = 0
        
        if mode == .resultsFound {
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
        }
        
        return sectionIndex
    }
    
    override func titleForHeaderInSection(section: Int) -> String? {
        var titleHeader: String?
        
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            
            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String,
                let sortBy = searchGenerator.displayValue(for: .sortBy) as? String else {
                return titleHeader
            }
            
            switch displayBy {
            case "list":
                guard let sectionTitles = _sectionTitles else {
                    return titleHeader
                }
                if sortBy == "number" ||
                    sortBy == "collectorNumber" {
                    titleHeader = nil
                } else {
                    titleHeader = sectionTitles[section]
                }
            case "grid":
                ()
            default:
                ()
            }
        }
        
        return titleHeader
    }
    
    // MARK: UICollectionViewDataSource methods
    override func collectionViewNumberOfItems(inSection section: Int) -> Int {
        var items = 0
        
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            
            guard let sortBy = searchGenerator.displayValue(for: .sortBy) as? String,
                let results = _results,
                let sectionTitles = _sectionTitles else {
                return items
            }
            
            switch sortBy {
            case "name":
                items = results.filter("myNameSection == %@", sectionTitles[section]).count
            case "number",
                 "collectorNumber":
                items = results.count
            case "type":
                items = results.filter("myType.name == %@", sectionTitles[section]).count
            case "rarity":
                items = results.filter("rarity.name == %@", sectionTitles[section]).count
            case "artist":
                items = results.filter("artist.name == %@", sectionTitles[section]).count
            default:
                ()
            }
        }
        
        return items
    }
    
    override func collectionViewNumberOfSections() -> Int {
        var sections = 1
        
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            guard let sortBy = searchGenerator.displayValue(for: .sortBy) as? String,
                let _ = _results,
                let sectionTitles = _sectionTitles else {
                return sections
            }
            
            if sortBy == "number" ||
                sortBy == "collectorNumber" {
                sections = 1
            } else {
                sections = sectionTitles.count
            }
        }
        
        return sections
    }
    
    override func collectionTitleForHeaderInSection(section: Int) -> String? {
        var titleHeader: String?
        
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            
            guard let sortBy = searchGenerator.displayValue(for: .sortBy) as? String,
                let sectionTitles = _sectionTitles else {
                return titleHeader
            }
            
            if sortBy == "number" ||
                sortBy == "collectorNumber" {
                titleHeader = nil
            } else {
                titleHeader = sectionTitles[section]
            }
        }
        
        return titleHeader
    }
    
    // MARK: Overrides
    override func object(forRowAt indexPath: IndexPath) -> Object? {
        let searchGenerator = SearchRequestGenerator()
        
        guard let sortBy = searchGenerator.displayValue(for: .sortBy) as? String,
            let results = _results,
            let sectionTitles = _sectionTitles else {
            return nil
        }
        
        switch sortBy {
        case "name":
            return results.filter("myNameSection == %@", sectionTitles[indexPath.section])[indexPath.row]
        case "number",
             "collectorNumber":
            return results[indexPath.row]
        case "type":
            return results.filter("myType.name == %@", sectionTitles[indexPath.section])[indexPath.row]
        case "rarity":
            return results.filter("rarity.name == %@" ,sectionTitles[indexPath.section])[indexPath.row]
        case "artist":
            return results.filter("artist.name == %@", sectionTitles[indexPath.section])[indexPath.row]
        default:
            return nil
        }
    }
    
    override func count() -> Int {
        guard let results = _results else {
            return 0
        }
        return results.count
    }
    
    override func fetchData() -> Promise<Void> {
        return Promise { seal  in
            if let newPredicate = SearchRequestGenerator().createSearchPredicate(query: queryString, oldPredicate: predicate) {
                _results = ManaKit.sharedInstance.realm.objects(CMCard.self).filter(newPredicate)
            } else {
                _results = ManaKit.sharedInstance.realm.objects(CMCard.self)
            }
            
            if let sortDescriptors = sortDescriptors {
                _results = _results!.sorted(by: sortDescriptors)
            }
            
            updateSections()
            seal.fulfill(())
        }
    }
    
    
    override func updateSections() {
        guard let results = _results else {
            return
        }
        
        let searchGenerator = SearchRequestGenerator()
        let sortBy = searchGenerator.displayValue(for: .sortBy) as? String
        
        _sectionIndexTitles = [String]()
        _sectionTitles = [String]()
        
        for card in results {
            var sectionIndexTitle: String?
            var sectionTitle: String?
            
            switch sortBy {
            case "name":
                sectionIndexTitle = card.myNameSection
                sectionTitle = card.myNameSection
            case "number",
                 "collectorNumber":
                ()
            case "type":
                if let type = card.myType {
                    sectionIndexTitle = type.nameSection
                    sectionTitle = type.name
                }
            case "rarity":
                if let rarity = card.rarity {
                    sectionIndexTitle = rarity.nameSection
                    sectionTitle = rarity.name
                }
            case "artist":
                if let artist = card.artist {
                    sectionIndexTitle = artist.nameSection
                    sectionTitle = artist.name
                }
            default:
                ()
            }
            
            if let sectionIndexTitle = sectionIndexTitle {
                if !_sectionIndexTitles!.contains(sectionIndexTitle) {
                    _sectionIndexTitles!.append(sectionIndexTitle)
                }
            }
            
            if let sectionTitle = sectionTitle {
                if !_sectionTitles!.contains(sectionTitle) {
                    _sectionTitles!.append(sectionTitle)
                }
            }
        }
        
        _sectionIndexTitles!.sort()
        _sectionTitles!.sort()
    }
}

