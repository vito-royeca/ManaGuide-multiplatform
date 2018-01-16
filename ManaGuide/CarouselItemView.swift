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
    @IBOutlet var cardImage: UIImageView!
    @IBOutlet var ratingView: CosmosView!
    @IBOutlet var viewsLabel: UILabel!
    
    // Custom methods
    func showCard() {
        if let bgImage = ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.grayPatterned) {
            backgroundColor = UIColor(patternImage: bgImage)
        }
        
        if let card = card {
            cardImage.image = ManaKit.sharedInstance.cardImage(card)
            ratingView.rating = Double(arc4random_uniform(5) + 1); //card.rating
            viewsLabel.text = "\u{f06e} \(card.views)"
            
            if cardImage.image == ManaKit.sharedInstance.imageFromFramework(imageName: .cardBack) ||
                cardImage.image == ManaKit.sharedInstance.imageFromFramework(imageName: .collectorsCardBack) ||
                cardImage.image == ManaKit.sharedInstance.imageFromFramework(imageName: .intlCollectorsCardBack) {
                ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                    
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
        }
    }
    
    func showPricing() {
//        if let cards = cards {
//            let card = cards[indexPath.row]
//
//            if let label = cell!.viewWithTag(100) as? UILabel {
//                label.text = "Low\n100"
//                label.textColor = UIColor.red
//            }
//            if let label = cell!.viewWithTag(200) as? UILabel {
//                label.text = "Mid\n100"
//                label.textColor = UIColor.blue
//            }
//            if let label = cell!.viewWithTag(300) as? UILabel {
//                label.text = "High\n100"
//                label.textColor = ManaKit.sharedInstance.hexStringToUIColor(hex: "008000")
//            }
//            if let label = cell!.viewWithTag(400) as? UILabel {
//                label.text = "Foil\n100"
//                label.textColor = ManaKit.sharedInstance.hexStringToUIColor(hex: "998100")
//            }
//            if let imageView = cell!.viewWithTag(500) as? UIImageView {
//                imageView.image = ManaKit.sharedInstance.cardImage(card)
//            }
//            if let ratingView = cell!.viewWithTag(600) as? CosmosView {
//                ratingView.settings.fillMode = .precise
//                ratingView.rating = card.rating
//                ratingView.isHidden = cardIndex != indexPath.row
//            }
//            if let viewedImage = cell!.viewWithTag(700) as? UIImageView {
//                let image = UIImage.init(icon: .FAEye, size: CGSize(width: 20, height: 20), textColor: .white, backgroundColor: .clear)
//                viewedImage.image = image
//                viewedImage.isHidden = cardIndex != indexPath.row
//            }
//            if let viewsLabel = cell!.viewWithTag(800) as? UILabel {
//                viewsLabel.text = "\(card.views)"
//                viewsLabel.isHidden = cardIndex != indexPath.row
//            }
//        }
    }
}
