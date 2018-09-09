//
//  TopViewedItemCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import Font_Awesome_Swift
import ManaKit
import PromiseKit

class TopViewedItemCell: UICollectionViewCell {
    static let reuseIdentifier = "TopViewedItemCell"
    
    // MARK: Outlets
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
 
    // MARK: Variables
    var card: CMCard! {
        didSet {
            if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                cardImage.image = croppedImage
            } else {
                cardImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                
                firstly {
                    ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .artCrop)
                }.done {
                    guard let image = ManaKit.sharedInstance.croppedImage(self.card) else {
                        return
                    }
                    
                    let animations = {
                        self.cardImage.image = image
                    }
                    UIView.transition(with: self.cardImage,
                                      duration: 1.0,
                                      options: .transitionCrossDissolve,
                                      animations: animations,
                                      completion: nil)
                }.catch { error in
                        
                }
            }
            
            setupUI()
            
            logoLabel.text = ManaKit.sharedInstance.keyruneUnicode(forSet: card.set!)
            logoLabel.textColor = ManaKit.sharedInstance.keyruneColor(forCard: card)
            nameLabel.text = card.name
            viewsLabel.setFAText(prefixText: "", icon: .FAEye, postfixText: " \(card.views)", size: CGFloat(13))
        }
    }
    
    // MARK: Custom methods
    private func setupUI() {
        cardImage.layer.cornerRadius = 10
        logoLabel.layer.cornerRadius = logoLabel.frame.height / 2
    }
}
