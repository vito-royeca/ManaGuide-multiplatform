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

class SetsViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Variables
    @Published var sets = [MGSet]()
    @Published var sections = [NSFetchedResultsSectionInfo]()
    @Published var isBusy = false

    // MARK: - Variables
    var dataAPI: API
    var sort: SetsViewSort = .releaseDate
    var query: String?
    var scopeSelection: Int
    private var frc: NSFetchedResultsController<MGSet>
    
    // MARK: - Initializers
    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        query = ""
        scopeSelection = 0
        frc = NSFetchedResultsController()

        super.init()
    }
    
    // MARK: - Methods
    func fetchData() {
        guard !isBusy /*&& sets.isEmpty*/ else {
            return
        }
        
        isBusy.toggle()
        
        dataAPI.fetchSets(completion: { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .success:
                    self.fetchLocalData()
                case .failure(let error):
                    print(error)
                    self.sets.removeAll()
                }
                
                self.isBusy.toggle()
            }
        })
    }
    
    func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(query: query),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: sectionNameKeyPath(),
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            sets = frc.fetchedObjects ?? []
            sections = frc.sections ?? []
        } catch {
            print(error)
            self.sets.removeAll()
        }
    }
    
    func sortDescriptors() -> [NSSortDescriptor] {
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
    
    func sectionNameKeyPath() -> String? {
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

// MARK: - NSFetchedResultsControllerDelegate
extension SetsViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let sets = controller.fetchedObjects as? [MGSet] else {
            return
        }

        self.sets = sets
    }
}

// MARK: - NSFetchRequest
extension SetsViewModel {
    func defaultFetchRequest(query: String?) -> NSFetchRequest<MGSet> {
        var predicate: NSPredicate?
        
        if let query = query,
           !query.isEmpty {
            predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR code CONTAINS[cd] %@", query, query)
        }
        
        let request: NSFetchRequest<MGSet> = MGSet.fetchRequest()
        request.sortDescriptors = sortDescriptors()
        request.predicate = predicate

        return request
    }
}
