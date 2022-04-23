//
//  SearchViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import CoreData
import SwiftUI
import ManaKit

class SearchViewModel: CardsViewModel {
    
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

    override func fetchData() {
        if !willFetch() {
            return
        }
        
        guard !isBusy && cards.isEmpty else {
            return
        }
        
        isBusy.toggle()
        isFailed = false

        dataAPI.fetchCards(query: query!,
                           completion: { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .success:
                    self.fetchLocalData()
                case .failure(let error):
                    print(error)
                    self.isFailed = true
                    self.cards.removeAll()
                }
                
                self.isBusy.toggle()
            }
        })
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
            cards = frc.fetchedObjects ?? []
            sections = frc.sections ?? []
        } catch {
            print(error)
            isFailed = true
            cards.removeAll()
        }
    }
    
    override var sectionIndexTitles: [String] {
        get {
            switch display {
            case .imageCarousel:
                return []
            case .imageGrid,
                 .list,
                 .summary:
                switch sort {
                case .collectorNumber:
                    return []
                case .name:
                    return frc.sectionIndexTitles
                case .rarity:
                    return frc.sectionIndexTitles
                case .setName:
                    return frc.sectionIndexTitles
                case .setReleaseDate:
                    return []
                case .type:
                    return frc.sectionIndexTitles
                }
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

extension SearchViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let cards = controller.fetchedObjects as? [MGCard] else {
            return
        }

        self.cards = cards
    }
}

// MARK: - NSFetchRequest

extension SearchViewModel {
    func defaultFetchRequest(query: String) -> NSFetchRequest<MGCard> {
        let predicate = NSPredicate(format: "newID != nil AND newID != '' AND collectorNumber != nil AND language.code = %@ AND name CONTAINS[cd] %@", "en", query)
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate

        return request
    }
}
