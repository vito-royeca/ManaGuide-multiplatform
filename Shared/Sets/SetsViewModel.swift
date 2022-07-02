//
//  SetsViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//  Copyright © 2022 Jovito Royeca. All rights reserved.
//

import CoreData
import SwiftUI
import ManaKit

// MARK: - Settings

enum SetsViewSort: String {
    case name,
         releaseDate,
         type
}

// MARK: - SetsViewModel

class SetsViewModel: ViewModel {
    
    // MARK: - Variables
    
    var dataAPI: API
    var sort: SetsViewSort = .releaseDate
    var query = ""
    private var frc: NSFetchedResultsController<MGSet>
    
    // MARK: - Initializers
    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController()
        
        super.init()
    }
    
    // MARK: - Variables
    
    override var sortDescriptors: [NSSortDescriptor] {
        get {
            var sortDescriptors = [NSSortDescriptor]()
            
            switch sort {
            case .name:
                sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "releaseDate", ascending: false))
            case .releaseDate:
                sortDescriptors.append(NSSortDescriptor(key: "releaseDate", ascending: false))
                sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
            case .type:
                sortDescriptors.append(NSSortDescriptor(key: "setType.name", ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "releaseDate", ascending: false))
                sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
            }
            
            return sortDescriptors
        }
    }
    
    override var sectionNameKeyPath: String? {
        get {
            var keyPath: String?
            
            switch sort {
            case .name:
                keyPath = "nameSection"
            case .releaseDate:
                keyPath = "yearSection"
            case .type:
                keyPath = "setType.name"
            }
            
            return keyPath
        }
    }
    
    override var sectionIndexTitles: [String] {
        get {
            switch sort {
            case .name:
                return frc.sectionIndexTitles
            case .releaseDate:
                return []
            case .type:
                return frc.sectionIndexTitles
            }
        }
    }
    
    // MARK: - Methods
    
    override func fetchData() {
        guard !isBusy && data.isEmpty else {
            return
        }
        
        isBusy.toggle()
        isFailed = false
        
        dataAPI.fetchSets(completion: { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .success:
                    self.fetchLocalData()
                case .failure(let error):
                    print(error)
                    self.isFailed = true
                    self.data.removeAll()
                }
                
                self.isBusy.toggle()
            }
        })
    }
    
    override func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(query: query),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: sectionNameKeyPath,
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            if query.isEmpty {
                data = (frc.fetchedObjects ?? []).map({ $0.objectID })
            } else {
                filteredData = (frc.fetchedObjects ?? []).map({ $0.objectID })
            }
            sections = frc.sections ?? []
        } catch {
            print(error)
            isFailed = true
            data.removeAll()
        }
    }
    
    
}

// MARK: - NSFetchedResultsControllerDelegate

extension SetsViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let sets = controller.fetchedObjects as? [MGSet] else {
            return
        }

        data = sets.map({ $0.objectID })
    }
}

// MARK: - NSFetchRequest

extension SetsViewModel {
    func defaultFetchRequest(query: String) -> NSFetchRequest<MGSet> {
        var predicate = NSPredicate(format: "parent = nil")
        
        if !query.isEmpty {
            if query.count <= 2 {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                                NSPredicate(format: "name BEGINSWITH[cd] %@ OR code BEGINSWITH[cd] %@", query, query)])
            } else {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                                NSPredicate(format: "name CONTAINS[cd] %@ OR code CONTAINS[cd] %@", query, query)])
            }
        }
        
        let request: NSFetchRequest<MGSet> = MGSet.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate

        return request
    }
}
