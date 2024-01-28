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

enum CardsViewSort: String, CaseIterable {
    case name,
         collectorNumber,
         rarity,
         type
    
    var description: String {
        get {
            switch self {
            case .name:
                "Name"
            case .collectorNumber:
                "Collector Number"
            case .rarity:
                "Rarity"
            case .type:
                "Type"
            }
        }
    }

    static let defaultValue: CardsViewSort = .name
}

enum CardsViewDisplay: String, CaseIterable {
    case image,
         list
    
    var description: String {
        get {
            switch self {
            case .image:
                "Image"
            case .list:
                "List"
            }
        }
    }

    static let defaultValue: CardsViewDisplay = .list
}

// MARK: - CardsViewModel

class CardsViewModel: ViewModel {

    // MARK: - Variables

    @Published var sort: CardsViewSort = .name
    @Published var display: CardsViewDisplay = .list
    @Published var cardTypes = [MGCardType]()
    @Published var rarities = [MGRarity]()
    var rarityFilter: String?
    var typeFilter: String?

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
                keyPath = nil
            case .rarity:
                keyPath = "rarity.name"
            case .type:
                keyPath = "type.name"
            }
            
            return keyPath
        }
    }
}

