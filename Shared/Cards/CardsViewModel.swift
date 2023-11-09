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
         collectorNumber,
         rarity,
         type
    
    static let defaultValue: CardsViewSort = .name
}

enum CardsViewDisplay: String {
    case image,
         list
    
    static let defaultValue: CardsViewDisplay = .image
}

// MARK: - CardsViewModel

class CardsViewModel: ViewModel {

    // MARK: - Variables

    @Published var sort: CardsViewSort = .name
    @Published var display: CardsViewDisplay = .list
    
    override var sortDescriptors: [NSSortDescriptor] {
        get {
            var sortDescriptors = [NSSortDescriptor]()
            
            switch sort {
            case .name:
                sortDescriptors.append(NSSortDescriptor(key: "name",
                                                        ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder",
                                                        ascending: true))
            case .collectorNumber:
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder",
                                                        ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "name",
                                                        ascending: true))
            case .rarity:
                sortDescriptors.append(NSSortDescriptor(key: "rarity.name",
                                                        ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "name",
                                                        ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "numberOrder",
                                                        ascending: true))
            case .type:
                sortDescriptors.append(NSSortDescriptor(key: "type.name",
                                                        ascending: true))
                sortDescriptors.append(NSSortDescriptor(key: "name",
                                                        ascending: true))
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
                keyPath = "numberOrder"
            case .rarity:
                keyPath = "rarity.name"
            case .type:
                keyPath = "type.name"
            }
            
            return keyPath
        }
    }
}
