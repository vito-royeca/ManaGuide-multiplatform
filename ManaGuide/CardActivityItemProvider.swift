//
//  CardActivityItemProvider.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 16/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class CardActivityItemProvider: UIActivityItemProvider {
    let card: CMCard
//    private var semaphore: DispatchSemaphore?
    
    init(_ card: CMCard) {
        self.card = card
        
        super.init(placeholderItem: ManaKit.sharedInstance.cardImage(card, imageType: .normal)!)
    }
    
    override var item: Any {
        get {
            return ManaKit.sharedInstance.cardImage(card, imageType: .normal)!
        }
    }
}
