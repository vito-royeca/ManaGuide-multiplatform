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
    var query: String?
    var scopeSelection: Int
    private var frc: NSFetchedResultsController<MGCard>
    
    // MARK: - Initializers

    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        query = ""
        scopeSelection = 0
        frc = NSFetchedResultsController()
        
        super.init()
    }
    
    // MARK: - Methods

    @MainActor
    override func fetchRemoteData() {
        if !willFetch() {
            return
        }
        
        guard !isBusy && data.isEmpty else {
            return
        }
        
        if dataAPI.willFetchCards(query: query!) {
            isBusy.toggle()
            isFailed = false

            Task {
                do {
                    try await dataAPI.fetchCards(query: query!)
                    fetchLocalData()
                } catch {
                    isFailed = true
                    data.removeAll()
                }
                isBusy.toggle()
            }
        } else {
            fetchLocalData()
        }
    }
    
    override func fetchLocalData() {
        if !willFetch() {
            return
        }
        
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(query: query!),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: sectionNameKeyPath,
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            data = (frc.fetchedObjects ?? []).map({ $0.objectID })
            sections = frc.sections ?? []
        } catch {
            print(error)
            isFailed = true
            data.removeAll()
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
        let hasQuery = query != nil && !query!.isEmpty
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
        guard let cards = controller.fetchedObjects as? [MGCard] else {
            return
        }

        data = cards.map({ $0.objectID })
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
