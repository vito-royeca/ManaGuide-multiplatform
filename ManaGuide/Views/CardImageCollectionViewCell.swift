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
    var imageType: ManaKit.ImageType = .normal
    var animationOptions: UIView.AnimationOptions = []

    var card: CMCard? {
        didSet {
            guard let card = card else {
                return
            }
            
            switch imageType {
            case .artCrop:
                setLogoLabel.backgroundColor = UIColor.white
                setLogoLabel.text = ManaKit.sharedInstance.keyruneUnicode(forSet: card.set!)
                setLogoLabel.textColor = ManaKit.sharedInstance.keyruneColor(forCard: card)
                cardImage.contentMode = .scaleToFill
            default:
                setLogoLabel.backgroundColor = UIColor.clear
                setLogoLabel.text = nil
                cardImage.contentMode = .scaleAspectFit
            }
            
            if let image = ManaKit.sharedInstance.cardImage(card, imageType: imageType) {
                cardImage.image = image
            } else {
                switch imageType {
                case .artCrop:
                    cardImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                default:
                    cardImage.image = ManaKit.sharedInstance.cardBack(card)
                }
                
                firstly {
                    ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: imageType)
                }.done {
                    guard let image = ManaKit.sharedInstance.cardImage(card, imageType: self.imageType) else {
                        return
                    }
                    
                    let animations = {
                        self.cardImage.image = image
                    }
                    UIView.transition(with: self.cardImage,
                                      duration: 1.0,
                                      options: self.animationOptions,
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
    @IBOutlet weak var setLogoLabel: UILabel!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setLogoLabel.layer.cornerRadius = setLogoLabel.frame.height / 2
    }

}
