//
//  CarouselItemView.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 10/01/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import Cosmos
import ManaKit

class CarouselItemView: UIView {

    // Variables
    var card: CMCard?
    
    // Outlets
    @IBOutlet var lowPriceLabel: UILabel!
    @IBOutlet var midPriceLabel: UILabel!
    @IBOutlet var highPriceLabel: UILabel!
    @IBOutlet var foilPriceLabel: UILabel!
    @IBOutlet var cardImage: UIImageView!
    @IBOutlet var ratingView: CosmosView!
    @IBOutlet var viewsLabel: UILabel!
    @IBOutlet weak var labelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var priceWidthConstraint: NSLayoutConstraint!

    // Custom methods
    func showCard() {
        if let card = card {
            ManaKit.sharedInstance.fetchTCGPlayerPricing(card: card, completion: {(cardPricing: CMCardPricing?, error: Error?) in
                if let cardPricing = cardPricing,
                    let c = self.card {
                    
                    if c.id == cardPricing.card?.id {
                        self.lowPriceLabel.text = cardPricing.low > 0 ? String(format: "$%.2f", cardPricing.low) : "NA"
                        self.midPriceLabel.text = cardPricing.average > 0 ? String(format: "$%.2f", cardPricing.average) : "NA"
                        self.highPriceLabel.text = cardPricing.high > 0 ? String(format: "$%.2f", cardPricing.high) : "NA"
                        self.foilPriceLabel.text = cardPricing.foil > 0 ? String(format: "$%.2f", cardPricing.foil) : "NA"
                    }
                }
            })
            
            if let image = ManaKit.sharedInstance.cardImage(card) {
                cardImage.image = image
            } else {
                cardImage.image = ManaKit.sharedInstance.cardBack(card)
                
                ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: Error?) in
                    
                    if error == nil {
                        if c.id == card.id {
                            UIView.transition(with: self.cardImage,
                                              duration: 1.0,
                                              options: .transitionCrossDissolve,
                                              animations: {
                                                self.cardImage.image = image
                            },
                                              completion: nil)
                        }
                    }
                })
            }
            
            // TODO: fetch card.rating from Firebase
            ratingView.rating = Double(arc4random_uniform(5) + 1); //card.rating
            showCardViews()
        }
    }
    
    func showCardViews() {
        if let card = card {
            viewsLabel.text = "\u{f06e} \(card.views)"
        }
    }
}
