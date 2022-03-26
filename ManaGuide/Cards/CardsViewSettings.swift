//
//  CardsViewSettings.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/25/22.
//

import Foundation

enum CardsViewDisplay: String {
    case image,
         list,
         summary
}

enum CardsViewSort: String {
    case collectorNumber,
         name,
         rarity,
         setName,
         setReleaseDate,
         type
}
