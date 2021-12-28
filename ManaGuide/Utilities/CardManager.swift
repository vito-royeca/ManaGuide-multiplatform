//
//  CardManager.swift
//  ManaGuide
//
//  Created by Vito Royeca on 12/23/19.
//  Copyright © 2019 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class CardManager: NSObject {
    var card: MGCard?

    init(with card: MGCard) {
        super.init()
        
        self.card = card
    }
    
    
}
