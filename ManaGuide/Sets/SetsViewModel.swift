//
//  SetsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 23.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import ManaKit
import PromiseKit
import RealmSwift

class SetsViewModel: BaseSearchViewModel {
    override init() {
        super.init()
    }
    
    // MARK: Variables
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    
    // MARK: UITableView methods
    override func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        if mode == .resultsFound {
            let defaults = defaultsValue()
            var sectionIndex = 0
            
            guard let sectionTitles = _sectionTitles,
                let setsOrderBy = defaults["setsOrderBy"] as? Bool else {
                return sectionIndex
            }

            for i in 0...sectionTitles.count - 1 {
                if sectionTitles[i].hasPrefix(title) {
                    if setsOrderBy {
                        sectionIndex = i
                    } else {
                        sectionIndex = (sectionTitles.count - 1) - i
                    }
                    break
                }
            }

            return sectionIndex
        } else {
            return 0
        }
    }
    
    override func sectionIndexTitles() -> [String]? {
        if mode == .resultsFound {
            return _sectionIndexTitles
        } else {
            return nil
        }
    }

    // MARK: Custom methods
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            var predicate: NSPredicate?
            let count = queryString.count
            
            if count > 0 {
                if count == 1 {
                    predicate = NSPredicate(format: "name BEGINSWITH[cd] %@ OR code BEGINSWITH[cd] %@",
                                            queryString, queryString)
                } else {
                    predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR code CONTAINS[cd] %@",
                                            queryString, queryString)
                }
            }
            updateSorting(with: nil)
            
            if let predicate = predicate {
                results = ManaKit.sharedInstance.realm.objects(CMSet.self).filter(predicate).sorted(by: sortDescriptors!) as? Results<Object>
            } else {
                results = ManaKit.sharedInstance.realm.objects(CMSet.self).sorted(by: sortDescriptors!) as? Results<Object>
            }
            
            updateSections()
            seal.fulfill(())
        }
    }
    
    func updateSorting(with values: [String: Any]?) {
        let defaults = defaultsValue()
        var setsSortBy = defaults["setsSortBy"] as! String
        var setsOrderBy = defaults["setsOrderBy"] as! Bool
        sectionName = defaults["setsSectionName"] as! String
        
        // fix old setting
        if sectionName == "yearSection" {
           sectionName = "myYearSection"
        }
        if sectionName == "nameSection" {
            sectionName = "myNameSection"
        }
        
        if let values = values {
            if let value = values["setsOrderBy"] as? Bool {
                setsOrderBy = value
            }
            
            if let value = values["setsSortBy"] as? String {
                setsSortBy = value
                
                switch setsSortBy {
                case "releaseDate":
                    sectionName = "myYearSection"
                case "name":
                    sectionName = "myNameSection"
                case "setType.name":
                    sectionName = "setType.name"
                default:
                    ()
                }
            }
        }
        
        UserDefaults.standard.set(sectionName, forKey: "setsSectionName")
        UserDefaults.standard.set(setsSortBy, forKey: "setsSortBy")
        UserDefaults.standard.set(setsOrderBy, forKey: "setsOrderBy")
        UserDefaults.standard.synchronize()
        
        sortDescriptors = [SortDescriptor(keyPath: setsSortBy, ascending: setsOrderBy)]
    }
    
    // MARK: Overrides
    override func updateSections() {
        guard let results = results else {
            return
        }

        switch sectionName {
        case "myNameSection",
             "setType.name":
            _sectionIndexTitles = [String]()
            _sectionTitles = [String]()
        default:
            _sectionIndexTitles = nil
            _sectionTitles = nil
            return
        }
        
        for set in results {
            var prefix: String?
            
            switch sectionName {
            case "myNameSection":
                prefix = set.myNameSection
            case "setType.name":
                prefix = set.setType!.nameSection
            default:
                ()
            }
            
            if let prefix = prefix {
                if !_sectionIndexTitles!.contains(prefix) {
                    _sectionIndexTitles!.append(prefix)
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
//
//        _sectionIndexTitles!.sort()
//        _sectionTitles!.sort()
    }
    
    private func defaultsValue() -> [String: Any] {
        var values = [String: Any]()
        
        if let value = UserDefaults.standard.value(forKey: "setsSectionName") as? String {
            values["setsSectionName"] = value
        } else {
            values["setsSectionName"] = "myYearSection"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setsSortBy") as? String {
            values["setsSortBy"] = value
        } else {
            values["setsSortBy"] = "releaseDate"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setsOrderBy") as? Bool {
            values["setsOrderBy"] = value
        } else {
            values["setsOrderBy"] = false
        }
        
        return values
    }
}
