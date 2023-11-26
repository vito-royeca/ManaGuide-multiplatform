//
//  CardsSearchViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import CoreData
import SwiftUI
import ManaKit

class CardsSearchViewModel: CardsViewModel {
    
    // MARK: - Variables

    private var dataAPI: API
    private var frc: NSFetchedResultsController<MGCard>
    
    @Published var name = "" {
        didSet {
            updateWillFetch()
        }
    }
    
    @Published var colorsFilter = [MGColor]()
    @Published var raritiesFilter = [MGRarity]()
    @Published var typesFilter = [MGCardType]()
    
    @Published var willFetch = false
    @Published var colors = [MGColor]()

    // MARK: - Initializers

    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController()
        
        super.init()
    }
    
    // MARK: - Methods

    override func fetchRemoteData() async throws {
        guard !isBusy else {
            return
        }

        do {
            if try dataAPI.willFetchCards(name: name,
                                          colors: colorsFilter.compactMap { $0.symbol },
                                          rarities: raritiesFilter.compactMap { $0.name },
                                          types: typesFilter.compactMap { $0.name }) {
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                    self.isFailed = false
                }
                
                _ = try await dataAPI.fetchCards(name: name,
                                                 colors: colorsFilter.compactMap { $0.symbol },
                                                 rarities: raritiesFilter.compactMap { $0.name },
                                                 types: typesFilter.compactMap { $0.name },
                                                 sortDescriptors: sortDescriptors)
                
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
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(name: name),
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
    
    override var sectionIndexTitles: [String] {
        get {
            switch sort {
            case .name:
                return frc.sectionIndexTitles
            case .collectorNumber:
                return frc.sectionIndexTitles
            case .rarity:
                return frc.sectionIndexTitles
            case .type:
                return frc.sectionIndexTitles
            }
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension CardsSearchViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = controller.sections ?? []
    }
}

// MARK: - NSFetchRequest

extension CardsSearchViewModel {
    func defaultFetchRequest(name: String) -> NSFetchRequest<MGCard> {
        let format = "newID != nil AND newID != '' AND collectorNumber != nil AND language.code = %@"
        var predicate = NSPredicate(format: format,
                                    "en")
        
        if !name.isEmpty {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                            NSPredicate(format: "name CONTAINS[cd] %@",
                                                                                        name)
            ])
        }
        if !colorsFilter.isEmpty {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                            NSPredicate(format: "ANY colors.symbol IN %@",
                                                                                        colorsFilter.compactMap { $0.symbol })
            ])
        }
        if !raritiesFilter.isEmpty {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                            NSPredicate(format: "rarity.name IN %@",
                                                                                        raritiesFilter.compactMap { $0.name })
            ])
        }
        if !typesFilter.isEmpty {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                            NSPredicate(format: "ANY supertypes.name IN %@",
                                                                                        typesFilter.compactMap { $0.name })
            ])
        }
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate

        return request
    }
}

extension CardsSearchViewModel {
    var cards: [NSManagedObjectID] {
        guard let array = frc.fetchedObjects else {
            return []
        }
        
        return array.map { $0.objectID }
    }
    
    override func fetchOtherData() async throws {
        try await super.fetchOtherData()
        
        let sortDescriptors = [NSSortDescriptor(key: "name",
                                                ascending: true)]
        
        if try ManaKit.shared.willFetchColors() {
            _ = try await ManaKit.shared.fetchColors(sortDescriptors: sortDescriptors)
        }
        
        DispatchQueue.main.async {
            let newSortDescriptors = [NSSortDescriptor(key: "name",
                                                       ascending: true)]
            self.colors = ManaKit.shared.find(MGColor.self,
                                         properties: nil,
                                         predicate: nil,
                                         sortDescriptors: newSortDescriptors,
                                         createIfNotFound: false,
                                         context: ManaKit.shared.viewContext)  ?? []
        }
    }
    
    func updateWillFetch() {
        willFetch = (!name.isEmpty && name.count >= 4) ||
            (colorsFilter.count +
            raritiesFilter.count +
            typesFilter.count) >= 2
        
    }
    
    func resetFilters() {
        name = ""
        colorsFilter = [MGColor]()
        raritiesFilter = [MGRarity]()
        typesFilter = [MGCardType]()
    }
}
