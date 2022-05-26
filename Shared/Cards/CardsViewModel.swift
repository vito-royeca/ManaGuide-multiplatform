//
//  CardsViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import CoreData
import SwiftUI
import ManaKit

// MARK: - Settings

enum CardsViewSort: String {
    case name,
         rarity,
         type
}

// MARK: - CardsViewModel

class CardsViewModel: NSObject, ObservableObject {

    // MARK: - Published Variables

    @Published var cards = [MGCard]()
    @Published var sections = [NSFetchedResultsSectionInfo]()
    @Published var isBusy = false
    @Published var isFailed = false

    // MARK: - Variables

    var sort: CardsViewSort = .name
    
    var sortDescriptors: [NSSortDescriptor] {
        get {
            var sortDescriptors = [NSSortDescriptor]()
            
            switch sort {
            case .name:
                sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
            case .rarity:
                sortDescriptors.append(NSSortDescriptor(key: "rarity.name", ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
            case .type:
                sortDescriptors.append(NSSortDescriptor(key: "type.name", ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "name", ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder", ascending: true))
            }
            
            return sortDescriptors
        }
    }
    
    var sectionNameKeyPath: String? {
        get {
            var keyPath: String?
            
            switch sort {
            case .name:
                keyPath = "nameSection"
            case .rarity:
                keyPath = "rarity.name"
            case .type:
                keyPath = "type.name"
            }
            
            return keyPath
        }
    }
    
    var sectionIndexTitles: [String] {
        get {
            return []
        }
    }
    
    // MARK: - Methods
    
    func fetchData() { }
    func fetchLocalData() { }
}
