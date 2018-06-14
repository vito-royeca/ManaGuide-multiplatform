//
//  RandomCardView.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 14/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PromiseKit

class RandomCardView: UIView {

    // MARK: Constants
    let preEightEditionFont      = UIFont(name: "Magic:the Gathering", size: 20.0)
    let eightEditionFont         = UIFont(name: "Matrix-Bold", size: 20.0)
    let magic2015Font            = UIFont(name: "Beleren", size: 20.0)

    // MARK: Variables
    var card: CMCard?
    
    // MARK: Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var setIcon: UILabel!
    @IBOutlet weak var cropImageView: UIImageView!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        setIcon.layer.cornerRadius = setIcon.frame.height / 2
    }
    
    // MARK: Custom methods
    func showImage() {
        if let card = card {
        
            if let image = ManaKit.sharedInstance.cardImage(card, imageType: .artCrop) {
                cropImageView.image = image
            } else {
                cropImageView.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                
                firstly {
                    ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .artCrop)
                }.done { (image: UIImage?) in
                    if let image = image {
                        UIView.transition(with: self.cropImageView,
                                          duration: 1.0,
                                          options: .transitionCrossDissolve,
                                          animations: {
                                              self.cropImageView.image = image
                                          },
                                          completion: nil)
                        
                    }
                }.catch { error in
                    print("\(error)")
                }
            }
        }
    }
    
    func showNameandSet() {
        if let card = card {
            nameLabel.text = card.name
            if let releaseDate = card.set!.releaseDate {
                let isModern = ManaKit.sharedInstance.isModern(card)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                if let m15Date = formatter.date(from: "2014-07-18"),
                    let setReleaseDate = formatter.date(from: releaseDate) {
                    
                    var shadowColor:UIColor?
                    var shadowOffset = CGSize(width: 0, height: -1)
                    
                    if setReleaseDate.compare(m15Date) == .orderedSame ||
                        setReleaseDate.compare(m15Date) == .orderedDescending {
                        nameLabel.font = magic2015Font
                        
                    } else {
                        nameLabel.font = isModern ? eightEditionFont : preEightEditionFont
                        
                        if !isModern {
                            shadowColor = UIColor.black
                            shadowOffset = CGSize(width: 1, height: 1)
                        }
                    }
                    
                    nameLabel.shadowColor = shadowColor
                    nameLabel.shadowOffset = shadowOffset
                }
            }
            
            if let set = card.set,
                let rarity = card.rarity_ {
                setIcon.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
                setIcon.textColor = ManaKit.sharedInstance.keyruneColor(forRarity: rarity)
                setIcon.backgroundColor = UIColor.white
            } else {
                setIcon.text = ""
            }
        }
    }
    
    func hideNameandSet() {
        nameLabel.text = ""
        setIcon.text = ""
        setIcon.backgroundColor = UIColor.clear
    }
}
