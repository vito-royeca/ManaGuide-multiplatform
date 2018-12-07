//
//  BaseSearchViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 19/11/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit

import CoreData
import ManaKit
import PromiseKit

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
                    "name": "Scroll Rack"]
        case .loading:
            return ["setCode": "chk",
                    "name": "Azami, Lady of Scrolls"]
        case .noResultsFound:
            return ["setCode": "chk",
                    "name": "Azusa, Lost but Seeking"]
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

class BaseSearchViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    var searchCancelled = false
    var mode: ViewModelMode = .loading
    var isStandBy = false
    var sortDescriptors: [NSSortDescriptor]?
    var request: NSFetchRequest<NSManagedObject>?
    var sectionName = "name"
    var title: String?
    var fetchedResultsController: NSFetchedResultsController<NSManagedObject>?
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            var rows = 0
            
            guard let fetchedResultsController = fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                    return rows
            }
            rows = sections[section].numberOfObjects
            return rows
            
        } else {
            return 1
        }
    }
    
    func numberOfSections() -> Int {
        if mode == .resultsFound {
            var number = 0
            
            guard let fetchedResultsController = fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                    return number
            }
            
            number = sections.count
            return number
            
        } else {
            return 1
        }
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
            var titleHeader: String?
            
            guard let fetchedResultsController = fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                    return titleHeader
            }
            titleHeader = sections[section].name
            return titleHeader
            
        } else {
            return nil
        }
    }
    
    // MARK: UICollectionView methods
    func collectionNumberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            guard let fetchedResultsController = fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                    return 0
            }
            
            return sections[section].numberOfObjects
        } else {
            return 1
        }
    }
    
    func collectionNumberOfSections() -> Int {
        if mode == .resultsFound {
            guard let fetchedResultsController = fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                    return 0
            }
            
            return sections.count
        } else {
            return 1
        }
    }
    
    func collectionSectionIndexTitles() -> [String]? {
        if mode == .resultsFound {
            return _sectionIndexTitles
        } else {
            return nil
        }
    }
    
    func collectionSectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        if mode == .resultsFound {
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
        } else {
            return 0
        }
    }
    
    func collectionTitleForHeaderInSection(section: Int) -> String? {
        if mode == .resultsFound {
            var titleHeader: String?
            
            guard let fetchedResultsController = fetchedResultsController,
                let sections = fetchedResultsController.sections else {
                    return nil
            }
            titleHeader = sections[section].name
            
            return titleHeader
        } else {
            return nil
        }
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> NSManagedObject {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("fetchedResultsController is nil")
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    func allObjects() -> [NSManagedObject]? {
        guard let fetchedResultsController = fetchedResultsController else {
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
            updateSections()
            seal.fulfill(())
        }
    }
    
    func updateSections() {
        
    }
    
    func getFetchedResultsController(with fetchRequest: NSFetchRequest<NSManagedObject>?) -> NSFetchedResultsController<NSManagedObject> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var newRequest: NSFetchRequest<NSManagedObject>?
        
        if let fetchRequest = fetchRequest {
            newRequest = fetchRequest
        } else {
            // create a default fetchRequest
            newRequest = request
            newRequest!.sortDescriptors = sortDescriptors
        }
        
        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: newRequest!,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: sectionName,
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
}

// MARK: NSFetchedResultsControllerDelegate
extension BaseSearchViewModel : NSFetchedResultsControllerDelegate {
    
}
