//
//  CardTableViewCell.swift
//  CardMagusKit
//
//  Created by Jovito Royeca on 15/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

public let kCardTableViewCellHeight = CGFloat(88)

open class CardTableViewCell: UITableViewCell {

    // Variables
    open var card:CMCard?
    let preEightEditionFont      = UIFont(name: "Magic:the Gathering", size: 17.0)
    let preEightEditionFontSmall = UIFont(name: "Magic:the Gathering", size: 15.0)
    let eightEditionFont         = UIFont(name: "Matrix-Bold", size: 17.0)
    let eightEditionFontSmall    = UIFont(name: "Matrix-Bold", size: 15.0)
    let magic2015Font            = UIFont(name: "Beleren", size: 17.0)
    let magic2015FontSmall       = UIFont(name: "Beleren", size: 15.0)
    
    // MARK: Outlets
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var nameAndCCView: UIView!
    @IBOutlet weak var symbolImage: UIImageView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var setImage: UILabel!
    @IBOutlet weak var lowPriceLabel: UILabel!
    @IBOutlet weak var midPriceLabel: UILabel!
    @IBOutlet weak var highProceLabel: UILabel!
    @IBOutlet weak var foilPriceLabel: UILabel!
    
    // MARK: Overrides
    override open func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // add round corners
        thumbnailImage.layer.cornerRadius = thumbnailImage.frame.height / 6
        setImage.layer.cornerRadius = setImage.frame.height / 2
    }

    override open func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override open func prepareForReuse() {
        for c in nameAndCCView.subviews {
            c.removeFromSuperview()
        }
        thumbnailImage.image = UIImage(named: ImageName.cardBackCropped.rawValue)
        symbolImage.image = nil
        typeLabel.text = nil
        setImage.text = nil
        lowPriceLabel.text  = "NA"
        midPriceLabel.text  = "NA"
        highProceLabel.text = "NA"
        foilPriceLabel.text = "NA"
    }
    
    // MARK: Custom methods
    open func updateDataDisplay() {
        if let card = card {
            // thumbnail image
            if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                thumbnailImage.image = croppedImage
            } else {
                thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                
                ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                    
                    if error == nil {
                        if c.id == self.card?.id  {
                            UIView.transition(with: self.thumbnailImage,
                                              duration: 1.0,
                                              options: .transitionCrossDissolve,
                                              animations: {
                                                  self.thumbnailImage.image = croppedImage
                                              },
                                              completion: nil)
                        }
                    }
                })
            }
            
            
            // casting cost
            var width = CGFloat(17)
            let height = CGFloat(17)
            var x = nameAndCCView.frame.size.width - width
            let y = CGFloat(0)
            if let manaCost = card.manaCost {
                let array = ManaKit.sharedInstance.manaImages(manaCost: manaCost)
                for dict in array.reversed() {
                    for (key,value) in dict {
                        if key == "1000000" {
                            width = CGFloat(17) * 3
                            x = nameAndCCView.frame.size.width - width
                        } else {
                            width = CGFloat(17)
                        }
                        
                        let imageView = UIImageView(frame: CGRect(x: x, y: y, width: width, height: height))
                        imageView.image = value
                        imageView.contentMode = .scaleAspectFit
                        
                        nameAndCCView.addSubview(imageView)
                        x -= width
                    }
                }
            }
            
            // card name
            let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: x + CGFloat(17), height: nameAndCCView.frame.size.height))
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
                            shadowColor = UIColor.darkGray
                            shadowOffset = CGSize(width: 1, height: 1)
                        }
                    }

                    nameLabel.shadowColor = shadowColor
                    nameLabel.shadowOffset = shadowOffset
                }
            }
            nameAndCCView.addSubview(nameLabel)
            
            // set symbol
            if let rarity = card.rarity_,
                let set = card.set {
                setImage.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
                setImage.textColor = ManaKit.sharedInstance.keyruneColor(forRarity: rarity)
            }

            // type symbol
            var cardType: CMCardType?
            if let types = card.types_ {
                if types.count > 1 {
                    symbolImage.image = ManaKit.sharedInstance.symbolImage(name: "Multiple")
                    cardType = types.allObjects.first as? CMCardType
                    
                    for t in types.allObjects {
                        if let t = t as? CMCardType {
                            if t.name == "Creature" {
                                cardType = t
                            }
                        }
                    }
                } else {
                    if let type = types.allObjects.first as? CMCardType {
                        cardType = type
                    }
                }
            }

            if let cardType = cardType {
                if let name = cardType.name {
                    symbolImage.image = ManaKit.sharedInstance.symbolImage(name: name)
                }
            }
            // type
            if let type = card.type_,
                let cardType = cardType {
                var typeText = ""
                
                if let name = type.name {
                    typeText.append(name)
                }
                if let name = cardType.name {
                    if name == "Creature" {
                        if let power = card.power,
                            let toughness = card.toughness {
                            typeText.append(" (\(power)/\(toughness))")
                        }
                    }
                }
                typeLabel.text = typeText
            }

            // pricing
            ManaKit.sharedInstance.fetchTCGPlayerPricing(card: card, completion: {(cardPricing: CMCardPricing?, error: Error?) in
                if let cardPricing = cardPricing {
                    if card.id == cardPricing.card?.id {
                        self.lowPriceLabel.text = cardPricing.low > 0 ? "\(cardPricing.low)" : "NA"
                        self.midPriceLabel.text = cardPricing.average > 0 ? "\(cardPricing.average)" : "NA"
                        self.highProceLabel.text = cardPricing.high > 0 ? "\(cardPricing.high)" : "NA"
                        self.foilPriceLabel.text = cardPricing.foil > 0 ? "\(cardPricing.foil)" : "NA"
                    }
                }
            })
        }
    }
}
