//
//  KeywordsViewModel.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 12/14/23.
//

import CoreData
import SwiftUI
import ManaKit

// MARK: - RaritiesViewModel

class KeywordsViewModel: ViewModel {
    // MARK: - Variables
    
    var dataAPI: API
    private var frc: NSFetchedResultsController<MGKeyword>
    
    // MARK: - Initializers
    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController()
        
        super.init()
    }
    
    // MARK: - Variables
    
    override var sortDescriptors: [NSSortDescriptor] {
        get {
            var sortDescriptors = [NSSortDescriptor]()
            
            sortDescriptors.append(NSSortDescriptor(key: "name",
                                                    ascending: true))
            
            return sortDescriptors
        }
    }
    
    override var sectionNameKeyPath: String? {
        get {
            return "nameSection"
        }
    }
    
    override var sectionIndexTitles: [String] {
        get {
            return frc.sectionIndexTitles
        }
    }
    
    // MARK: - Methods
    
    override func fetchRemoteData() async throws {
        guard !isBusy else {
            return
        }
        
        do {
            if try dataAPI.willFetchKeywords() {
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                    self.isFailed = false
                }
                
                _ = try await dataAPI.fetchKeywords()
                
                DispatchQueue.main.async {
                    self.fetchLocalData()
                    self.isBusy.toggle()
                }
                
            } else {
                DispatchQueue.main.async {
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
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(),
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

extension KeywordsViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = controller.sections ?? []
    }
}

// MARK: - NSFetchRequest

extension KeywordsViewModel {
    func defaultFetchRequest() -> NSFetchRequest<MGKeyword> {
        let request: NSFetchRequest<MGKeyword> = MGKeyword.fetchRequest()
        var predicate: NSPredicate?

        if !query.isEmpty {
            if query.count <= 2 {
                predicate = NSPredicate(format: "name BEGINSWITH[cd] %@",
                                        query)
            } else {
                predicate = NSPredicate(format: "name CONTAINS[cd] %@",
                                        query)
            }
        }

        request.sortDescriptors = sortDescriptors
        request.predicate = predicate

        return request
    }
}
