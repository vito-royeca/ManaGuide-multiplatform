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

    init(setCode: String,
         languageCode: String,
         dataAPI: API = ManaKit.shared) {
        self.setCode = setCode
        self.languageCode = languageCode
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController()
        
        super.init()
    }
    
    // MARK: - Variables

    override var sortDescriptors: [NSSortDescriptor] {
        get {
            var sortDescriptors = [NSSortDescriptor]()

            switch sort {
            case .name:
                if languageCode == "en" {
                    sortDescriptors.append(NSSortDescriptor(key: "name",
                                                            ascending: true))
                } else {
                    sortDescriptors.append(NSSortDescriptor(key: "printedName",
                                                            ascending: true))
                }
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder",
                                                        ascending: true))

            case .collectorNumber:
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder",
                                                        ascending: true))
                if languageCode == "en" {
                    sortDescriptors.append(NSSortDescriptor(key: "name",
                                                            ascending: true))
                } else {
                    sortDescriptors.append(NSSortDescriptor(key: "printedName",
                                                            ascending: true))
                }

            case .rarity:
                sortDescriptors.append(NSSortDescriptor(key: "rarity.name",
                                                        ascending: true))
                if languageCode == "en" {
                    sortDescriptors.append(NSSortDescriptor(key: "name",
                                                            ascending: true))
                } else {
                    sortDescriptors.append(NSSortDescriptor(key: "printedName",
                                                            ascending: true))
                }
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder",
                                                        ascending: true))

            case .type:
                sortDescriptors.append(NSSortDescriptor(key: "type.name",
                                                        ascending: true))
                if languageCode == "en" {
                    sortDescriptors.append(NSSortDescriptor(key: "name",
                                                            ascending: true))
                } else {
                    sortDescriptors.append(NSSortDescriptor(key: "printedName",
                                                            ascending: true))
                }
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder",
                                                        ascending: true))
            }
            
            return sortDescriptors
        }
    }

    override var sectionNameKeyPath: String? {
        get {
            var keyPath: String?
            
            switch sort {
            case .name:
                keyPath = "nameSection"
            case .collectorNumber:
                keyPath = nil
            case .rarity:
                keyPath = "rarity.name"
            case .type:
                keyPath = "type.name"
            }
            
            return keyPath
        }
    }

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
            case .collectorNumber, .rarity, .type:
                return frc.sectionIndexTitles
            }
        }
    }

    // MARK: - Methods
    
    override func fetchRemoteData() async throws {
        guard !isBusy else {
            return
        }
        
        do {
            if try dataAPI.willFetchSet(code: setCode,
                                    languageCode: languageCode) {
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                    self.isFailed = false
                }
                
                let objectID = try await dataAPI.fetchSet(code: setCode,
                                                          languageCode: languageCode)
                DispatchQueue.main.async {
                    self.set = objectID
                    self.fetchLocalData()
                    self.isBusy.toggle()
                }
            } else {
                DispatchQueue.main.async {
                    self.findSet()
                    self.fetchLocalData()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.set = nil
                self.isBusy.toggle()
                self.isFailed = true
            }
        }
    }
    
    override func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(setCode: setCode,
                                                                           languageCode: languageCode),
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
    
    override func dataArray<T: MGEntity>(_ type: T.Type) -> [T] {
        return frc.fetchedObjects as? [T] ?? []
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension SetViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = controller.sections ?? []
    }
}

// MARK: - NSFetchRequest

extension SetViewModel {
    func defaultFetchRequest(setCode: String, languageCode: String) -> NSFetchRequest<MGCard> {
        var predicate = NSPredicate(format: "set.code == %@ AND language.code == %@ AND collectorNumber != null ",
                                    setCode,
                                    languageCode)
        
        if let rarityFilter = rarityFilter {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                            NSPredicate(format: "rarity.name == %@",
                                                                                        rarityFilter)])
        }

        if let typeFilter = typeFilter {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                            NSPredicate(format: "ANY supertypes.name IN %@",
                                                                                        [typeFilter])])
        }

        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        return request
    }
}

extension SetViewModel {
    func commonLanguages() -> [MGLanguage] {
        let codes = ["en", "es", "fr", "de", "it", "pt", "ja", "ko", "ru", "zhs", "zht"]
        let predicate = NSPredicate(format: "code IN %@", codes)
        let languages = ManaKit.shared.find(MGLanguage.self,
                                            properties: nil,
                                            predicate: predicate,
                                            sortDescriptors: [NSSortDescriptor(key: "code", ascending: true)],
                                            createIfNotFound: true,
                                            context: ManaKit.shared.viewContext)  ?? []
        return languages
    }
    
    func findSet() {
        let predicate = NSPredicate(format: "code == %@", setCode)
        set = ManaKit.shared.find(MGSet.self,
                                  properties: nil,
                                  predicate: predicate,
                                  sortDescriptors: nil,
                                  createIfNotFound: false)?.first?.objectID
    }

    var setObject: MGSet? {
        get {
            if let set = set {
                find(MGSet.self, id: set)
            } else {
                nil
            }
        }
    }
    
    var cards: [NSManagedObjectID] {
        guard let array = frc.fetchedObjects else {
            return []
        }
        
        return array.map { $0.objectID }
    }
}

