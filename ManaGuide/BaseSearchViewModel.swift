//
//  BaseSearchViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 19/11/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PromiseKit
import RealmSwift

enum ViewModelMode: Int {
    case standBy
    case loading
    case noResultsFound
    case resultsFound
    case error
    
    var cardArt: [String: String]? {
        switch self {
        case .standBy:
            return ["setCode": "tmp",
                    "name": "Scroll Rack",
                    "artCropURL": "https://img.scryfall.com/cards/art_crop/en/tmp/308.jpg?1517813031"]
        case .loading:
            return ["setCode": "chk",
                    "name": "Azami, Lady of Scrolls",
                    "artCropURL": "https://img.scryfall.com/cards/art_crop/en/chk/52.jpg?1517813031"]
        case .noResultsFound:
            return ["setCode": "chk",
                    "name": "Azusa, Lost but Seeking",
                    "artCropURL": "https://img.scryfall.com/cards/art_crop/en/chk/201.jpg?1517813031"]
        case .resultsFound:
            return nil
        case .error:
            return ["setCode": "plc",
                    "name": "Dismal Failure",
                    "artCropURL": "https://img.scryfall.com/cards/art_crop/en/plc/39.jpg?1517813031"]
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

class BaseSearchViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    var searchCancelled = false
    var mode: ViewModelMode = .loading
    var isStandBy = false
    var sortDescriptors: [SortDescriptor]?
    var sectionName = "name"
    var title: String?
    var predicate: NSPredicate?
    
    var _sectionIndexTitles: [String]?
    var _sectionTitles: [String]?
    
    // MARK: Initializers
    override init() {
        super.init()
    }
    
    init(withPredicate predicate: NSPredicate?,
         andSortDescriptors sortDescriptors: [SortDescriptor]?,
         andTitle title: String?,
         andMode mode: ViewModelMode) {
        
        super.init()
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.title = title
        self.mode = mode
    }
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        return 0
    }
    
    func numberOfSections() -> Int {
        return 0
    }
    
    func sectionIndexTitles() -> [String]? {
        if mode == .resultsFound {
            return _sectionIndexTitles
        } else {
            return nil
        }
    }
    
    func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        if mode == .resultsFound {
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
            
        } else {
            return 0
        }
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        if mode == .resultsFound {
            guard let sectionTitles = _sectionTitles else {
                return nil
            }
            return sectionTitles[section]
        } else {
            return nil
        }
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> Object? {
        return nil
    }
    
    func count() -> Int {
        return 0
    }
    
    func isEmpty() -> Bool {
        return count() <= 0
    }

    func fetchData() -> Promise<Void> {
        return Promise { seal  in
            updateSections()
            seal.fulfill(())
        }
    }
    
    func updateSections() {
        
    }
}
