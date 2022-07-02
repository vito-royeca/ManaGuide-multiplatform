//
//  SetViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 25.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import SwiftUI
import ManaKit

class SetViewModel: CardsViewModel {

    // MARK: - Published Variables
    
    @Published private(set) var set: NSManagedObjectID?
    
    // MARK: - Variables
    var setCode: String
    var languageCode: String
    var dataAPI: API
    private var frc: NSFetchedResultsController<MGCard>
    
    // MARK: - Initializers
    init(setCode: String, languageCode: String, dataAPI: API = ManaKit.shared) {
        self.setCode = setCode
        self.languageCode = languageCode
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController()
        
        super.init()
    }
    
    // MARK: - Variables
    
    override var sectionIndexTitles: [String] {
        get {
            switch sort {
            case .name:
                if languageCode == "ja" ||
                    languageCode == "ko" ||
                    languageCode == "ru" ||
                    languageCode == "zhs" ||
                    languageCode == "zht" {
                    return []
                } else {
                    return frc.sectionIndexTitles
                }
            case .rarity:
                return frc.sectionIndexTitles
            case .type:
                return frc.sectionIndexTitles
            }
        }
    }

    // MARK: - Methods
    
    override func fetchRemoteData() {
        guard !isBusy && data.isEmpty else {
            return
        }
        
        isBusy.toggle()
        isFailed = false

        dataAPI.fetchSet(code: setCode,
                         languageCode: languageCode,
                         completion: { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .success(let set):
                    self.set = set?.objectID
                    self.fetchLocalData()
                case .failure(let error):
                    print(error)
                    self.isFailed = true
                    self.set = nil
                    self.data.removeAll()
                }
                
                self.isBusy.toggle()
            }
        })
    }
    
    override func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(setCode: setCode, languageCode: languageCode),
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

            switch sort {
            case .name:
                if languageCode == "en" {
                    sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
                } else {
                    sortDescriptors.append(NSSortDescriptor(key: "printedName", ascending: true))
                }
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
            case .rarity:
                sortDescriptors.append(NSSortDescriptor(key: "rarity.name", ascending: true))
                if languageCode == "en" {
                    sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
                } else {
                    sortDescriptors.append(NSSortDescriptor(key: "printedName", ascending: true))
                }
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
            case .type:
                sortDescriptors.append(NSSortDescriptor(key: "type.name", ascending: true))
                if languageCode == "en" {
                    sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
                } else {
                    sortDescriptors.append(NSSortDescriptor(key: "printedName", ascending: true))
                }
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
            }
            
            return sortDescriptors
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension SetViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let cards = controller.fetchedObjects as? [MGCard] else {
            return
        }
        
        data = cards.map({ $0.objectID })
    }
}

// MARK: - NSFetchRequest

extension SetViewModel {
    func defaultFetchRequest(setCode: String, languageCode: String) -> NSFetchRequest<MGCard> {
        let predicate = NSPredicate(format: "set.code == %@ AND language.code == %@ AND collectorNumber != null ", setCode, languageCode)
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        return request
    }
}

