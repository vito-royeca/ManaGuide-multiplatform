//
//  TopRatedItemCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import Cosmos
import ManaKit
import PromiseKit

class TopRatedItemCell: UICollectionViewCell {
    static let reuseIdentifier = "TopRatedItemCell"

    // MARK: Outlets
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    
    // MARK: Variables
    var card: CMCard! {
        didSet {
            
            if let croppedImage = card.image(type: .artCrop,
                                             faceOrder: 0,
                                             roundCornered: false) {
                cardImage.image = croppedImage
            } else {
                cardImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                
                firstly {
                    ManaKit.sharedInstance.downloadImage(ofCard: card,
                                                         type: .artCrop,
                                                         faceOrder: 0)
                }.done {
                    guard let image = self.card.image(type: .artCrop,
                                                      faceOrder: 0,
                                                      roundCornered: false) else {
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

            logoLabel.text = card.set!.keyruneUnicode()
            logoLabel.textColor = card.keyruneColor()
            nameLabel.text = card.displayName
            ratingView.rating = card.firebaseRating
        }
    }
    
    // MARK: Custom methods
    private func setupUI() {
        cardImage.layer.cornerRadius = 10
        logoLabel.layer.cornerRadius = logoLabel.frame.height / 2
        ratingView.settings.emptyBorderColor = LookAndFeel.GlobalTintColor
        ratingView.settings.filledBorderColor = LookAndFeel.GlobalTintColor
        ratingView.settings.filledColor = LookAndFeel.GlobalTintColor
        ratingView.settings.fillMode = .precise
    }
}

