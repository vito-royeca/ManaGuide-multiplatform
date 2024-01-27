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
    
    @Published var nameFilter = ""
    @Published var colorsFilter = [MGColor]()
    @Published var raritiesFilter = [MGRarity]()
    @Published var typesFilter = [MGCardType]()
    @Published var keywordsFilter = [MGKeyword]()
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
            if try dataAPI.willFetchCards(name: nameFilter,
                                          colors: colorsFilter.compactMap { $0.symbol },
                                          rarities: raritiesFilter.compactMap { $0.name },
                                          types: typesFilter.compactMap { $0.name },
                                          keywords: keywordsFilter.compactMap { $0.name }) {
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                    self.isFailed = false
                }
                
                _ = try await dataAPI.fetchCards(name: nameFilter,
                                                 colors: colorsFilter.compactMap { $0.symbol },
                                                 rarities: raritiesFilter.compactMap { $0.name },
                                                 types: typesFilter.compactMap { $0.name },
                                                 keywords: keywordsFilter.compactMap { $0.name },
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
                print(error)
                self.isBusy.toggle()
                self.isFailed = true
            }
        }
    }
    
    override func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(name: nameFilter),
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
        var predicates = [NSPredicate]()
        
        predicates.append(NSPredicate(format: "newID != nil AND newID != '' AND collectorNumber != nil AND language.code = %@",
                                      "en"))
        
        if !name.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@",
                                          name))
        }
        if !colorsFilter.isEmpty {
            predicates.append(NSPredicate(format: "ANY colors.symbol IN %@",
                                          colorsFilter.compactMap { $0.symbol }))
        }
        if !raritiesFilter.isEmpty {
            predicates.append(NSPredicate(format: "rarity.name IN %@",
                                          raritiesFilter.compactMap { $0.name }))
        }
        if !typesFilter.isEmpty {
            predicates.append(NSPredicate(format: "ANY supertypes.name IN %@",
                                          typesFilter.compactMap { $0.name }))
        }
        if !keywordsFilter.isEmpty {
            predicates.append(NSPredicate(format: "ANY keywords.name IN %@",
                                          keywordsFilter.compactMap { $0.name }))
        }
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

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
    
    func willFetch() -> Bool {
        !nameFilter.isEmpty && nameFilter.count >= 4
    }
    
    func resetFilters() {
        nameFilter = ""
        colorsFilter.removeAll()
        raritiesFilter.removeAll()
        typesFilter.removeAll()
        keywordsFilter.removeAll()
    }
}
