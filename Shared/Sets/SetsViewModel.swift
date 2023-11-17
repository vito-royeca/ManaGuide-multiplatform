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

enum SetsViewSort: String, CaseIterable {
    case name,
         releaseDate,
         type
    
    var description: String {
        get {
            switch self {
            case .name:
                "Name"
            case .releaseDate:
                "Release Date"
            case .type:
                "Type"
            }
        }
    }
    
    static let defaultValue: SetsViewSort = .releaseDate
}

// MARK: - SetsViewModel

class SetsViewModel: ViewModel {
    
    // MARK: - Variables
    
    var dataAPI: API
    var sort: SetsViewSort = .releaseDate
    var query = ""
    var typeFilter: String?
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
                sortDescriptors.append(NSSortDescriptor(key: "name",
                                                        ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "releaseDate",
                                                        ascending: false))
            case .releaseDate:
                sortDescriptors.append(NSSortDescriptor(key: "releaseDate",
                                                        ascending: false))
                sortDescriptors.append(NSSortDescriptor(key: "name",
                                                        ascending: true))
            case .type:
                sortDescriptors.append(NSSortDescriptor(key: "setType.name",
                                                        ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "releaseDate",
                                                        ascending: false))
                sortDescriptors.append(NSSortDescriptor(key: "name",
                                                        ascending: true))
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
    
    override func fetchRemoteData() async throws {
        guard !isBusy else {
            return
        }
        
        do {
            if try dataAPI.willFetchSets() {
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                    self.isFailed = false
                }
                
                _ = try await dataAPI.fetchSets(sortDescriptors: sortDescriptors)
                
                DispatchQueue.main.async {
                    self.fetchLocalData()
                    self.isBusy.toggle()
                }
                
            } else {
                DispatchQueue.main.async {
                    self.fetchLocalData()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isBusy.toggle()
                self.isFailed = true
            }
        }
    }
    
    override func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(query: query),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: sectionNameKeyPath,
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            sections = frc.sections ?? []
        } catch {
            print(error)
            isFailed = true
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension SetsViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = controller.sections ?? []
    }
}

// MARK: - NSFetchRequest

extension SetsViewModel {
    func defaultFetchRequest(query: String) -> NSFetchRequest<MGSet> {
        var predicate = NSPredicate(format: "parent = nil")

        if let typeFilter = typeFilter {
            predicate = NSPredicate(format: "setType.name = %@",
                                    typeFilter)
        }

        if !query.isEmpty {
            if query.count <= 2 {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                                NSPredicate(format: "name BEGINSWITH[cd] %@ OR code BEGINSWITH[cd] %@",
                                                                                            query,
                                                                                            query)])
            } else {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                                NSPredicate(format: "name CONTAINS[cd] %@ OR code CONTAINS[cd] %@",
                                                                                            query,
                                                                                            query)])
            }
        }
        
        let request: NSFetchRequest<MGSet> = MGSet.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate

        return request
    }
}

extension SetsViewModel {
    func setTypes() -> [MGSetType] {
        let types = ManaKit.shared.find(MGSetType.self,
                                        properties: nil,
                                        predicate: nil,
                                        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
                                        createIfNotFound: true,
                                        context: ManaKit.shared.viewContext)  ?? []
        return types
    }
}

