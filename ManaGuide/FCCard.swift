//
//  FCCard.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 15/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import Foundation
import Firebase

struct FCCard {
    struct Keys {
        static let Rating       = "Rating"
        static let Views        = "Views"
        static let Ratings      = "ratings"
    }
    
    // MARK: Properties
    let key: String?
    let ref: DatabaseReference?
    
    let rating: Double?
    let views: Int?
    let ratings: [String: Double]?
    
    // MARK: Initialization
    init(key: String, dict: [String: Any]) {
        self.key = key
        self.ref = nil
        
        self.rating = dict[Keys.Rating] as? Double
        self.views = dict[Keys.Views] as? Int
        self.ratings = dict[Keys.Ratings] as? [String: Double]
    }
    
    init(snapshot: DataSnapshot) {
        if let value = snapshot.value as? [String: Any] {
            self.key = snapshot.key
            self.ref = snapshot.ref
            self.rating = value[Keys.Rating] as? Double
            self.views = value[Keys.Views] as? Int
            self.ratings = value[Keys.Ratings] as? [String: Double]
        } else {
            self.key = nil
            self.ref = nil
            self.rating = nil
            self.views = nil
            self.ratings = nil
        }
    }
}
