//
//  MGUtilities.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 15/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ChameleonFramework
import Kanna
import ManaKit

class MGUtilities {
    class func composeType(of card: CMCard, pointSize: CGFloat) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString()
        var cardType: CMCardType?
        var image: UIImage?
        var text:String?
        
        if let types = card.types_ {
            if types.count > 1 {
                image = ManaKit.sharedInstance.symbolImage(name: "Multiple")
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
                image = ManaKit.sharedInstance.symbolImage(name: name)
            }
        }
        
        // type
        if let type = card.type_,
            let cardType = cardType {
            
            text = " "
            if let name = type.name {
                text!.append(name)
            }
            if let name = cardType.name {
                if name == "Creature" {
                    if let power = card.power,
                        let toughness = card.toughness {
                        text!.append(" (\(power)/\(toughness))")
                    }
                }
            }
        }
        
        
        if let image = image {
            let imageAttachment =  NSTextAttachment()
            imageAttachment.image = image
            
            let ratio = image.size.width / image.size.height
            let height = CGFloat(17)
            let width = ratio * height
            var imageOffsetY = CGFloat(0)
            
            if height > pointSize {
                imageOffsetY = -(height - pointSize) / 2.0
            } else {
                imageOffsetY = -(pointSize - height) / 2.0
            }
            
            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: width, height: height)
            
            let attachmentString = NSAttributedString(attachment: imageAttachment)
            attributedString.append(attachmentString)
        }
        
        if let text = text {
            attributedString.append(NSAttributedString(string: text))
        }
        
        return attributedString
    }
    
    class func composeOtherDetails(forCard card: CMCard) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .left
        
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                          NSParagraphStyleAttributeName: titleParagraphStyle]
        
        var text = "Layout: "
        if let layout = card.layout_ {
            if let name = layout.name {
                text.append(name)
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nConverted Mana Cost: "
        text.append("\(String(format: card.cmc == floor(card.cmc) ? "%.0f" : "%.1f", card.cmc))")
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nColors: "
        if let colors_ = card.colors_ {
            if let s = colors_.allObjects as? [CMColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nColors Identity: "
        if let colorIdentities_ = card.colorIdentities_ {
            if let s = colorIdentities_.allObjects as? [CMColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nOriginal Type: "
        if let originalType = card.originalType {
            text.append(originalType)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nSubtypes: "
        if let subtypes_ = card.subtypes_ {
            if let s = subtypes_.allObjects as? [CMCardType] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nSupertypes: "
        if let supertypes_ = card.supertypes_ {
            if let s = supertypes_.allObjects as? [CMCardType] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nRarity: "
        if let rarity = card.rarity_ {
            text.append(rarity.name!)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nSet Online Only: "
        if let set = card.set {
            text.append(set.onlineOnly ? "Yes" : "No")
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nReserved List: "
        text.append(card.reserved ? "Yes" : "No")
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nRelease Date: "
        if let releaseDate = card.releaseDate ?? card.set!.releaseDate {
            text.append(releaseDate)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nSource: "
        if let source = card.source {
            text.append(source)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nNumber: "
        if let number = card.number ?? card.mciNumber {
            text.append(number)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        return attributedString
    }
    
    class func updateColor(ofLabel label: UILabel, from image: UIImage) {
        let shadowColor = AverageColorFromImage(image)
        let shadowOffset = CGSize(width: 2, height: 2)
        
        label.textColor = UIColor.white
        label.shadowColor = shadowColor
        label.shadowOffset = shadowOffset
    }
}
