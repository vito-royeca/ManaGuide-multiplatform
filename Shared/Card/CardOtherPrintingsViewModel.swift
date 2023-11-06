//
//  CardOtherPrintingsViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/5/23.
//

import CoreData
import SwiftUI
import ManaKit

class CardOtherPrintingsViewModel: CardsViewModel {

    // MARK: - Published Variables
    
    @Published private(set) var card: NSManagedObjectID?
    
    // MARK: - Variables
    var newID: String
    var languageCode: String
    var dataAPI: API
    private var frc: NSFetchedResultsController<MGCard>
    
    // MARK: - Initializers
    init(newID: String,
         languageCode: String,
         dataAPI: API = ManaKit.shared) {
        self.newID = newID
        self.languageCode = languageCode
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController()
        super.init()
    }
    
    // MARK: - Methods
    
    @MainActor
    override func fetchRemoteData() {
        guard !isBusy && data.isEmpty else {
            return
        }
        
        if dataAPI.willFetchCardOtherPrintings(newID: newID,
                                               languageCode: languageCode) {
            isBusy.toggle()
            isFailed = false

            Task {
                do {
                    let count = try await dataAPI.fetchCardOtherPrintings(newID: newID,
                                                                          languageCode: languageCode).count
                    print("count=\(count)")
                    fetchLocalData()
                } catch {
                    self.isFailed = true
                    self.card = nil
                    self.data.removeAll()
                }
                isBusy.toggle()
            }
        } else {
            card = ManaKit.shared.find(MGCard.self,
                                      properties: nil,
                                      predicate: NSPredicate(format: "newID == %@", newID),
                                      sortDescriptors: nil,
                                      createIfNotFound: true,
                                      context: ManaKit.shared.viewContext)?.first?.objectID
            fetchLocalData()
        }
    }
    
    override func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(newID: newID),
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
    
    override var sortDescriptors: [NSSortDescriptor] {
        get {
            var sortDescriptors = [NSSortDescriptor]()

            sortDescriptors.append(NSSortDescriptor(key: "set.releaseDate",
                                                    ascending: false))
            
            return sortDescriptors
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension CardOtherPrintingsViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let cards = controller.fetchedObjects as? [MGCard] else {
            return
        }
        
        data = cards.map({ $0.objectID })
    }
}

// MARK: - NSFetchRequest

extension CardOtherPrintingsViewModel {
    func defaultFetchRequest(newID: String) -> NSFetchRequest<MGCard> {
        let predicate = NSPredicate(format: "newID IN %@", (cardObject?.sortedOtherPrintings ?? []).map { $0.newIDCopy })
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        return request
    }
}

extension CardOtherPrintingsViewModel {
    var cardObject: MGCard? {
        get {
            if let card = card {
                find(MGCard.self, id: card)
            } else {
                nil
            }
        }
    }
}
