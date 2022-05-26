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
    var imageType: CardImageType = .normal
    var animationOptions: UIView.AnimationOptions = []

    var card: CMCard? {
        didSet {
            guard let card = card else {
                return
            }
            
            switch imageType {
            case .artCrop:
                setLogoLabel.backgroundColor = UIColor.white
                setLogoLabel.text = card.set!.keyruneUnicode()
                setLogoLabel.textColor = card.keyruneColor()
                cardImage.contentMode = .scaleToFill
            default:
                setLogoLabel.backgroundColor = UIColor.clear
                setLogoLabel.text = nil
                cardImage.contentMode = .scaleAspectFit
            }
            
            if let image = card.image(type: imageType,
                                      faceOrder: 0,
                                      roundCornered: imageType == .artCrop ? false : true) {
                cardImage.image = image
            } else {
                switch imageType {
                case .artCrop:
                    cardImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                default:
                    cardImage.image = card.backImage()
                }
                
                firstly {
                    ManaKit.sharedInstance.downloadImage(ofCard: card,
                                                         type: imageType,
                                                         faceOrder: 0)
                }.done {
                    guard let image = card.image(type: self.imageType,
                                                 faceOrder: 0,
                                                 roundCornered: self.imageType == .artCrop ? false : true) else {
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
