//
//  CardsViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import CoreData
import SwiftUI
import ManaKit

class CardsViewModel: NSObject, ObservableObject {

    // MARK: - Published Variables

    @Published var cards = [MGCard]()
    @Published var sections = [NSFetchedResultsSectionInfo]()
    @Published var isBusy = false
    
    // MARK: - Variables

    var sort: CardsViewSort = .name
    var display: CardsViewDisplay = .summary
    
    // MARK: - Methods
    
    func fetchData() { }
    func fetchLocalData() { }
    
    func sortDescriptors() -> [NSSortDescriptor] {
        var sortDescriptors = [NSSortDescriptor]()
        
        switch sort {
        case .collectorNumber:
            sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
        case .name:
            sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
        case .rarity:
            sortDescriptors.append(NSSortDescriptor(key: "rarity.name", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
        case .setName:
            sortDescriptors.append(NSSortDescriptor(key: "set.name", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
        case .setReleaseDate:
            sortDescriptors.append(NSSortDescriptor(key: "set.releaseDate", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
        case .type:
            sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
            sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
        }
        
        return sortDescriptors
    }
    
    func sectionNameKeyPath() -> String? {
        var keyPath: String?
        
        switch sort {
        case .collectorNumber:
            ()
        case .name:
            keyPath = "nameSection"
        case .rarity:
            keyPath = "rarity.name"
        case .setName:
            keyPath = "set.name"
        case .setReleaseDate:
            keyPath = "set.releaseDate"
        case .type:
            keyPath = "typeSection"
        }
        
        return keyPath
    }
}
