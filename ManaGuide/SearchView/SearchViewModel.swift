//
//  SearchViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import CoreData
import SwiftUI
import ManaKit

class SearchViewModel: NSObject, ObservableObject {
    // MARK: - Published Variables
    @Published var cards = [MGCard]()
    @Published var isBusy = false
    
    // MARK: - Variables
    var dataAPI: API
    private var frc: NSFetchedResultsController<MGCard>
    
    // MARK: - Initializers
    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController(fetchRequest: MGCard.fetchRequest(),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
    }
    
    // MARK: - Methods
    func fetchData(query: String) {
        guard !isBusy else {
            return
        }
        
        isBusy.toggle()
        
        dataAPI.fetchCards(query: query,
                           completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.fetchLocalData(query: query)
                case .failure(let error):
                    print(error)
                    self.cards.removeAll()
                }
                
                self.isBusy.toggle()
            }
        })
    }
    
    func fetchLocalData(query: String) {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(query: query),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: nil,
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
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let predicate = NSPredicate(format: "newID != nil AND newID != '' AND name CONTAINS[cd] %@ AND collectorNumber != nil ", query)
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate

        return request
    }
}
