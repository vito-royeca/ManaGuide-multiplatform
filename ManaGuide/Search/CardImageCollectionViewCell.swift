//
//  CardImageCollectionViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 04.10.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PromiseKit

class CardImageCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "CardImageCell"
    
    // MARK: Variables
    var card: CMCard? {
        didSet {
            guard let card = card else {
                return
            }
            
            if let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) {
                cardImage.image = image
            } else {
                cardImage.image = ManaKit.sharedInstance.cardBack(card)
                
                firstly {
                    ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
                }.done {
                    guard let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) else {
                        return
                    }
                    
                    let animations = {
                        self.cardImage.image = image
                    }
                    UIView.transition(with: self.cardImage,
                                      duration: 1.0,
                                      options: .transitionFlipFromRight,
                                      animations: animations,
                                      completion: nil)
                }.catch { error in
                    print("\(error)")
                }
            }
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var cardImage: UIImageView!
    
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
