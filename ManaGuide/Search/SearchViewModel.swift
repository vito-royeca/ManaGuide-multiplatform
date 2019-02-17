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
    
    // MARK: UITableView methods
    override func numberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            let searchGenerator = SearchRequestGenerator()
            var rows = 0

            guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String,
                let sortBy = searchGenerator.displayValue(for: .sortBy) as? String else {
                return rows
            }
            
            switch displayBy {
            case "list":
                guard let results = _results,
                    let sectionTitles = _sectionTitles else {
                    return 0
                }
                
                switch sortBy {
                case "name":
                    return results.filter("myNameSection == %@", sectionTitles[section]).count
                case "number":
                    return results.count
                case "type":
                    return results.filter("type.nameSection == %@", sectionTitles[section]).count
                case "rarity":
                    return results.filter("rarity.nameSection == %@", sectionTitles[section]).count
                case "artist":
                    return results.filter("artist.nameSection == %@", sectionTitles[section]).count
                default:
                    rows = 1
                }
                
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
                guard let _ = _results,
                    let sectionTitles = _sectionTitles else {
                    return 0
                }
                number = sectionTitles.count
                
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
                guard let sectionTitles = _sectionTitles else {
                    return nil
                }
                titleHeader = sectionTitles[section]
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
    
    // MARK: Overrides
    override func object(forRowAt indexPath: IndexPath) -> Object? {
        let searchGenerator = SearchRequestGenerator()
        
        guard let sortBy = searchGenerator.displayValue(for: .sortBy) as? String,
            let results = _results,
            let sectionTitles = _sectionTitles else {
            return nil
        }
        
//        return results[indexPath.row]
//        return results.filter("\(sectionName) == %@", _sectionTitles![indexPath.section])[indexPath.row]
        
        switch sortBy {
        case "name":
            return results.filter("myNameSection == %@", sectionTitles[indexPath.section])[indexPath.row]
        case "number":
            return results[indexPath.row]
        case "type":
            return results.filter("type.nameSection == %@", sectionTitles[indexPath.section])[indexPath.row]
        case "rarity":
            return results.filter("rarity.nameSection == %@" ,sectionTitles[indexPath.section])[indexPath.row]
        case "artist":
            return results.filter("artist.nameSection == %@", sectionTitles[indexPath.section])[indexPath.row]
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
                
                if !_sectionTitles!.contains(prefix) {
                    _sectionTitles!.append(prefix)
                }
            }
        }
        
//        let count = sections.count
//        if count > 0 {
//            for i in 0...count - 1 {
//                if let sectionTitle = sections[i].indexTitle {
//                    _sectionTitles!.append(sectionTitle)
//                }
//            }
//        }
        
        _sectionIndexTitles!.sort()
        _sectionTitles!.sort()
    }
}

