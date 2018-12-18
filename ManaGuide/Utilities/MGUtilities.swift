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
    class func composeOtherDetails(forCard card: CMCard) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .left
        
        let attributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                          convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): titleParagraphStyle]
        
        var text = "Layout: "
        if let layout = card.layout {
            if let name = layout.name {
                text.append(name)
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
        text = "\nConverted Mana Cost: "
        text.append("\(String(format: card.convertedManaCost == floor(card.convertedManaCost) ? "%.0f" : "%.1f", card.convertedManaCost))")
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
        text = "\nColors: "
        if let colors_ = card.colors {
            if let s = colors_.allObjects as? [CMCardColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
        text = "\nColors Identity: "
        if let colorIdentities_ = card.colorIdentities {
            if let s = colorIdentities_.allObjects as? [CMCardColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
        text = "\nRarity: "
        if let rarity = card.rarity {
            text.append(rarity.name!)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
        text = "\nSet Online Only: "
        if let set = card.set {
            text.append(set.isOnlineOnly ? "Yes" : "No")
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
        text = "\nReserved List: "
        text.append(card.isReserved ? "Yes" : "No")
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
        text = "\nRelease Date: "
        if let releaseDate = card.releaseDate ?? card.set!.releaseDate {
            text.append(releaseDate)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
        text = "\nNumber: "
        if let number = card.collectorNumber {
            text.append(number)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text,
                                                          attributes: convertToOptionalNSAttributedStringKeyDictionary(attributes)))
        
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
