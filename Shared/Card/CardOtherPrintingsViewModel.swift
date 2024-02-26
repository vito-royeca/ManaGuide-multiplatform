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
    private var otherPrintingIDs = [NSManagedObjectID]()

    // MARK: - Initializers

    init(newID: String,
         languageCode: String,
         dataAPI: API = ManaKit.sharedCoreData) {
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

        do {
            if try dataAPI.willFetchCardOtherPrintings(newID: newID,
                                                       languageCode: languageCode) {
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                    self.isFailed = false
                }
                
                otherPrintingIDs = try await dataAPI.fetchCardOtherPrintings(newID: newID,
                                                                             languageCode: languageCode)
                DispatchQueue.main.async {
                    self.fetchLocalData()
                    self.isBusy.toggle()
                }
            } else {
                DispatchQueue.main.async {
                    self.findOtherPrintingIDs()
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
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(newID: newID),
                                         managedObjectContext: ManaKit.sharedCoreData.viewContext,
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
        var predicate: NSPredicate?
        
        if !otherPrintingIDs.isEmpty {
            var newIDs = [String]()
            for otherPrintingID in otherPrintingIDs {
                let card = ManaKit.sharedCoreData.object(MGCard.self,
                                                        with: otherPrintingID)
                newIDs.append(card.newIDCopy)
            }
            predicate = NSPredicate(format: "newID IN %@", newIDs)
        }
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        return request
    }
}

extension CardOtherPrintingsViewModel {
    func findOtherPrintingIDs() {
        let predicate = NSPredicate(format: "newID == %@", newID)
        if let card = ManaKit.sharedCoreData.find(MGCard.self,
                                                  properties: nil,
                                                  predicate: predicate,
                                                  sortDescriptors: nil,
                                                  createIfNotFound: false)?.first,
           let sortedOtherPrintings = card.sortedOtherPrintings {
            otherPrintingIDs = sortedOtherPrintings.map { $0.objectID }
        }
    }
}
