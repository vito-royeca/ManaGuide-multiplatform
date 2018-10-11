//
//  ArtistsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

class ArtistsViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    var searchCancelled = false
    
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?
    private var _fetchedResultsController: NSFetchedResultsController<CMArtist>?
    private let _sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                    NSSortDescriptor(key: "lastName", ascending: true),
                                    NSSortDescriptor(key: "firstName", ascending: true)]
    private let _sectionName = "nameSection"
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        var rows = 0
        
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return rows
        }
        rows = sections[section].numberOfObjects
        
        return rows
    }
    
    func numberOfSections() -> Int {
        var number = 0
        
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return number
        }
        
        number = sections.count
        
        return number
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
        var titleHeader: String?
        
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
            return titleHeader
        }
        titleHeader = sections[section].name
        
        return titleHeader
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> CMArtist {
        guard let fetchedResultsController = _fetchedResultsController else {
            fatalError("fetchedResultsController is nil")
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    func allObjects() -> [CMArtist]? {
        guard let fetchedResultsController = _fetchedResultsController else {
            return nil
        }
        return fetchedResultsController.fetchedObjects
    }
    
    func isEmpty() -> Bool {
        guard let objects = allObjects() else {
            return false
        }
        return objects.count == 0
    }

    func fetchData() {
        let request: NSFetchRequest<CMArtist> = CMArtist.fetchRequest()
        let count = queryString.count
        
        if count > 0 {
            if count == 1 {
                request.predicate = NSPredicate(format: "lastName BEGINSWITH[cd] %@ OR firstName BEGINSWITH[cd] %@", queryString, queryString)
            } else {
                request.predicate = NSPredicate(format: "lastName CONTAINS[cd] %@ OR firstName CONTAINS[cd] %@", queryString, queryString)
            }
        }
        request.sortDescriptors = _sortDescriptors
        
        _fetchedResultsController = getFetchedResultsController(with: request)
        updateSections()
    }
    
    // MARK: Private methods
    private func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMArtist>?) -> NSFetchedResultsController<CMArtist> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMArtist>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // create a default fetchRequest
            request = CMArtist.fetchRequest()
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
            let artists = fetchedResultsController.fetchedObjects,
            let sections = fetchedResultsController.sections else {
                return
        }
        let letters = CharacterSet.letters
        
        _sectionIndexTitles = [String]()
        _sectionTitles = [String]()
        
        for artist in artists {
            let names = artist.name!.components(separatedBy: " ")
            
            if let lastName = names.last {
                var prefix = String(lastName.prefix(1))
                if prefix.rangeOfCharacter(from: letters) == nil {
                    prefix = "#"
                }
                prefix = prefix.uppercased().folding(options: .diacriticInsensitive, locale: .current)
                
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
extension ArtistsViewModel : NSFetchedResultsControllerDelegate {
    
}
