//
//  CardsViewSettings.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/25/22.
//

import Foundation

enum CardsViewDisplay {
    case image,
         list,
         summary
}

enum CardsViewSort {
    case castingCost,
         collectorNumber,
         name,
         rarity,
         setName,
         setReleaseDate,
         type
}

class CardsViewSettings: ObservableObject {
    @Published var display: CardsViewDisplay = .summary
    @Published var sort: CardsViewSort = .name
}
