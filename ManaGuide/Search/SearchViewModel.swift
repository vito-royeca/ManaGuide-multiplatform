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
//    // MARK: - Published Variables
//    @Published var cards = [MGCard]()
//    @Published var isBusy = false
    var query: String?
    var scopeSelection: Int
    
    // MARK: - Variables
    var dataAPI: API
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
        guard let query = query,
            !query.isEmpty,
            !isBusy else {
            return
        }
        
        isBusy.toggle()
        
        dataAPI.fetchCards(query: query,
                           completion: { result in
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .success:
                    self.fetchLocalData()
                case .failure(let error):
                    print(error)
                    self.cards.removeAll()
                }
                
                self.isBusy.toggle()
//            }
        })
    }
    
    override func fetchLocalData() {
        guard let query = query,
            !query.isEmpty else {
            return
        }
        
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(query: query),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: sectionNameKeyPath(),
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            cards = frc.fetchedObjects ?? []
        } catch {
            print(error)
            cards.removeAll()
        }
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
        let predicate = NSPredicate(format: "newID != nil AND newID != '' AND collectorNumber != nil AND name CONTAINS[cd] %@", query)
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.sortDescriptors = sortDescriptors()
        request.predicate = predicate

        return request
    }
}
