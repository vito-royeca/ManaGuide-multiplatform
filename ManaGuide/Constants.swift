//
//  Constants.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 10/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import Foundation
import UIKit

// Look and feel
enum LookAndFeel {
    // #F92D51
    static let GlobalTintColor = UIColor(red:0.98, green:0.18, blue:0.32, alpha:1.0)
}

// TCGPlayer
enum TCGPlayerSettings {
    static let PartnerKey     = "ManaGuide"
    static let PublicKey      = "A49D81FB-5A76-4634-9152-E1FB5A657720"
    static let PrivateKey     = "C018EF82-2A4D-4F7A-A785-04ADEBF2A8E5"
}

enum GitHubSettings {
    static let ConsumerKey    = "02c51a1f8d2f22f089d7"
    static let ConsumerSecret = "36d40c833a2fb134d90ee5351b3a9684e29bb50a"
    static let AuthorizeUrl   = "https://github.com/login/oauth/authorize"
    static let AccessTokenUrl = "https://github.com/login/oauth/access_token"
    static let CallbackURL    = "oauth-managuide://oauth-callback/managuide"
}

// ---------------------------------------------------------------------- //
// ---------------- DO NOT MODIFY ANYTHING BELOW ------------------------ //
// ---------------------------------------------------------------------- //
enum NotificationKeys {
    static let FavoriteToggled    = "FavoriteToggled"
    static let CardRatingUpdated  = "CardRatingUpdated"
    static let CardViewsUpdated   = "CardViewsUpdated"
    static let DeckUpdated        = "DeckUpdated"
    static let ListUpdated        = "ListUpdated"
    static let UserLoggedIn       = "UserLoggedIn"
}

