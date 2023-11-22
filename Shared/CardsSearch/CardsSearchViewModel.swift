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

    var dataAPI: API
    var query = ""
    private var frc: NSFetchedResultsController<MGCard>
    
    // MARK: - Initializers

    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController()
        
        super.init()
    }
    
    // MARK: - Methods

    override func fetchRemoteData() async throws {
        if !willFetch() {
            return
        }
        
        guard !isBusy else {
            return
        }

        DispatchQueue.main.async {
            self.isBusy.toggle()
            self.isFailed = false
        }
        
        do {
            _ = try await dataAPI.fetchCards(query: query,
                                             sortDescriptors: sortDescriptors)
            DispatchQueue.main.async {
                self.fetchLocalData()
                self.isBusy.toggle()
            }
        } catch {
            DispatchQueue.main.async {
                self.isBusy.toggle()
                self.isFailed = true
            }
        }
    }
    
    override func fetchLocalData() {
        if !willFetch() {
            return
        }
        
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

    func willFetch() -> Bool {
        let hasPredicate = frc.fetchRequest.predicate != nil
        let hasQuery = !query.isEmpty
        var result = false
        
        if hasPredicate {
            result = true
        } else {
            result = hasQuery
        }
        
        return result
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
    func defaultFetchRequest(query: String) -> NSFetchRequest<MGCard> {
        let predicate = NSPredicate(format: "newID != nil AND newID != '' AND collectorNumber != nil AND language.code = %@ AND name CONTAINS[cd] %@",
                                    "en",
                                    query)
        
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
}
