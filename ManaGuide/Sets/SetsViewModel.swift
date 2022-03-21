//
//  SetsViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//  Copyright © 2022 Jovito Royeca. All rights reserved.
//

import Foundation
import CoreData
import Combine
import ManaKit

class SetsViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Variables
    @Published var sets = [MGSet]()
    @Published var isBusy = false

    // MARK: - Variables
    var dataAPI: API
    private var cancellables = Set<AnyCancellable>()
    private var frc: NSFetchedResultsController<MGSet>
    
    // MARK: - Initializers
    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController(fetchRequest: MGSet.fetchRequest(),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        super.init()
    }
    
    deinit {
        cancellables.forEach {
            $0.cancel()
        }
        sets.removeAll()
    }
    
    // MARK: - Methods
    func fetchData() {
        guard !isBusy && sets.isEmpty else {
            return
        }
        
        isBusy.toggle()
        
        dataAPI.fetchSets(cancellables: &cancellables,
                          completion: { result in
//            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.fetchLocalData()
                case .failure(let error):
                    print(error)
                    self.sets.removeAll()
                }
                
                self.isBusy.toggle()
//            }
        })
    }
    
    func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            sets = frc.fetchedObjects ?? []
        } catch {
            print(error)
            self.sets.removeAll()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension SetsViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let sets = controller.fetchedObjects as? [MGSet] else {
            return
        }

        self.sets = sets
    }
}

// MARK: - NSFetchRequest
extension SetsViewModel {
    func defaultFetchRequest() -> NSFetchRequest<MGSet> {
        let sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false),
                               NSSortDescriptor(key: "name", ascending: true)]

        let request: NSFetchRequest<MGSet> = MGSet.fetchRequest()
        request.sortDescriptors = sortDescriptors

        return request
    }
}
