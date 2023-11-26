//
//  CardsSearch.swift
//  ManaGuide
//
//  Created by Miguel Ponce de Monio III on 11/24/23.
//

import Foundation

enum CardsSearchField {
    case name, type, set, rarity
    
    var description: String {
        get {
            switch self {
            case .name:
                "Name"
            case .type:
                "Type"
            case .set:
                "Set"
            case .rarity:
                "Rarity"
            }
        }
    }
}

struct CardSearchValue<T> {
    let value: T
    let description: String
}

enum CardsSearchOperator {
    case and, or, not
    
    var description: String {
        get {
            switch self {
            case .and:
                "And"
            case .or:
                "Or"
            case .not:
                "Not"
            }
        }
    }
}

struct CardsSearchQuery: Identifiable {
    let id = UUID().uuidString
    let field: CardsSearchField
    let value: String
    let searchOperator: CardsSearchOperator?
}
