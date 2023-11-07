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
    
    override func fetchRemoteData() async throws {
        guard !isBusy else {
            return
        }

        DispatchQueue.main.async {
            self.isBusy.toggle()
            self.isFailed = false
        }

        do {
            _ = try await dataAPI.fetchCardOtherPrintings(newID: newID,
                                                          languageCode: languageCode,
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
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(newID: newID),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: sectionNameKeyPath,
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            sections = frc.sections ?? []
        } catch {
            isFailed = true
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
        sections = controller.sections ?? []
    }
}

// MARK: - NSFetchRequest

extension CardOtherPrintingsViewModel {
    func defaultFetchRequest(newID: String) -> NSFetchRequest<MGCard> {
        let predicate = NSPredicate(format: "newID IN %@"/*, (cardObject?.sortedOtherPrintings ?? []).map { $0.newIDCopy }*/)
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        return request
    }
}
