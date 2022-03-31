//
//  Constants.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 10/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import Foundation
import UIKit

enum Constants {
    static let cacheAge = 10 // 10 mins
}

// MARK: - Legacy Code

// Look and feel
enum LookAndFeel {
    // #F92D51
    static let GlobalTintColor = UIColor(red:0.98, green:0.18, blue:0.32, alpha:1.0)
}

// ---------------------------------------------------------------------- //
// ---------------- DO NOT MODIFY ANYTHING BELOW ------------------------ //
// ---------------------------------------------------------------------- //
enum NotificationKeys {
    static let FavoriteToggled        = "FavoriteToggled"
    static let CardPricingUpdated     = "CardPricingUpdated"
    static let CardRatingUpdated      = "CardRatingUpdated"
    static let CardViewsUpdated       = "CardViewsUpdated"
    static let CardRelatedDataUpdated = "CardRelatedDataUpdated"
    static let DeckUpdated            = "DeckUpdated"
    static let ListUpdated            = "ListUpdated"
    static let UserLoggedIn           = "UserLoggedIn"
}

