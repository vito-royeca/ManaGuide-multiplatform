//
//  SetsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 23.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

class SetsViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    private var _fetchedResultsController: NSFetchedResultsController<CMSet>?
    
    // MARK: Settings
    private var _sortDescriptors: [NSSortDescriptor]?
    private var _sectionName: String?
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
            return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    func numberOfSections() -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
            return 0
        }
        
        return sections.count
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
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
            return nil
        }
        return sections[section].name
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> CMSet {
        guard let fetchedResultsController = _fetchedResultsController else {
            fatalError("fetchedResultsController is nil")
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    func fetchData() {
        let request: NSFetchRequest<CMSet> = CMSet.fetchRequest()
        let count = queryString.count
        
        if count > 0 {
            if count == 1 {
                request.predicate = NSPredicate(format: "name BEGINSWITH[cd] %@ OR code BEGINSWITH[cd] %@", queryString, queryString)
            } else {
                request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR code CONTAINS[cd] %@", queryString, queryString)
            }
        }
        updateSorting(with: nil)
        request.sortDescriptors = _sortDescriptors
        
        _fetchedResultsController = getFetchedResultsController(with: request)
        updateSections()
    }
    
    func updateSorting(with values: [String: Any]?) {
        let defaults = defaultsValue()
        var setsSortBy = defaults["setsSortBy"] as! String
        var setsOrderBy = defaults["setsOrderBy"] as! Bool
        _sectionName = defaults["setsSectionName"] as? String
        
        
        if let values = values {
            if let value = values["setsSortBy"] as? String {
                setsSortBy = value
                
                switch setsSortBy {
                case "releaseDate":
                    _sectionName = "yearSection"
                case "name":
                    _sectionName = "nameSection"
                case "type_.name":
                    _sectionName = "typeSection"
                default:
                    ()
                }
            }
            
            if let value = values["setsOrderBy"] as? Bool {
                setsOrderBy = value
            }
        }
        
        UserDefaults.standard.set(_sectionName, forKey: "setsSectionName")
        UserDefaults.standard.set(setsSortBy, forKey: "setsSortBy")
        UserDefaults.standard.set(setsOrderBy, forKey: "setsOrderBy")
        UserDefaults.standard.synchronize()
        
        _sortDescriptors = [NSSortDescriptor(key: setsSortBy, ascending: setsOrderBy)]
    }

    private func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMSet>?) -> NSFetchedResultsController<CMSet> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMSet>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // Create a default fetchRequest
            request = CMSet.fetchRequest()
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
            let sets = fetchedResultsController.fetchedObjects,
            let sections = fetchedResultsController.sections,
            let sectionName = _sectionName else {
                return
        }

        switch sectionName {
        case "nameSection",
             "typeSection":
            _sectionIndexTitles = [String]()
            _sectionTitles = [String]()
        default:
            _sectionIndexTitles = nil
            _sectionTitles = nil
            return
        }
        
        for set in sets {
            var index: String?
            
            switch sectionName {
            case "nameSection":
                index = set.nameSection
            case "typeSection":
                index = String(set.typeSection!.prefix(1))
            default:
                ()
            }
            
            if let index = index {
                if !_sectionIndexTitles!.contains(index) {
                    _sectionIndexTitles!.append(index)
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
    
    private func defaultsValue() -> [String: Any] {
        var values = [String: Any]()
        
        if let value = UserDefaults.standard.value(forKey: "setsSectionName") as? String {
            values["setsSectionName"] = value
        } else {
            values["setsSectionName"] = "yearSection"
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

// MARK: NSFetchedResultsControllerDelegate
extension SetsViewModel : NSFetchedResultsControllerDelegate {
    
}