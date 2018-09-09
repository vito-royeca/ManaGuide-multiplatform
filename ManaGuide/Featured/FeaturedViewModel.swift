//
//  FeaturedViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

enum FeaturedSection: Int {
    case latestCards
    case latestSets
    case topRated
    case topViewed
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .latestCards: return "Latest Cards"
        case .latestSets: return "Latest Sets"
        case .topRated: return "Top Rated"
        case .topViewed: return "Top Viewed"
        }
    }
    
    static var count: Int {
        return 4
    }
}

class FeaturedViewModel: NSObject {

}
