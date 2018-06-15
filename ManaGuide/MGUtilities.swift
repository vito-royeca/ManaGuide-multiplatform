//
//  MGUtilities.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 15/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class MGUtilities {
    class func addSymbols(toText text: String?, pointSize: CGFloat) -> NSMutableAttributedString {
        let newAttributedString = NSMutableAttributedString()
        
        if let text = text {
            var fragmentText = NSMutableString()
            var offset = 0
            
            repeat {
                for i in offset...text.count - 1 {
                    let c = text[text.index(text.startIndex, offsetBy: i)]
                    
                    if c == "{" {
                        let symbol = NSMutableString()
                        
                        for j in i...text.count - 1 {
                            let cc = text[text.index(text.startIndex, offsetBy: j)]
                            
                            if cc == "}" {
                                offset = j + 1
                                break
                            } else {
                                symbol.append(String(cc))
                            }
                        }
                        
                        var cleanSymbol = symbol.replacingOccurrences(of: "{", with: "")
                            .replacingOccurrences(of: "}", with: "")
                            .replacingOccurrences(of: "/", with: "")
                        
                        if cleanSymbol == "CHAOS" {
                            cleanSymbol = "Chaos"
                        }
                        
                        if let image = ManaKit.sharedInstance.symbolImage(name: cleanSymbol as String) {
                            let imageAttachment =  NSTextAttachment()
                            imageAttachment.image = image
                            
                            var width = CGFloat(16)
                            let height = CGFloat(16)
                            var imageOffsetY = CGFloat(0)
                            
                            if cleanSymbol == "100" {
                                width = 35
                            } else if cleanSymbol == "1000000" {
                                width = 60
                            }
                            
                            if height > pointSize {
                                imageOffsetY = -(height - pointSize) / 2.0
                            } else {
                                imageOffsetY = -(pointSize - height) / 2.0
                            }
                            
                            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: width, height: height)
                            
                            let attachmentString = NSAttributedString(attachment: imageAttachment)
                            let attributedString = NSMutableAttributedString(string: fragmentText as String)
                            attributedString.append(attachmentString)
                            
                            newAttributedString.append(attributedString)
                            fragmentText = NSMutableString()
                            break
                        }
                        
                    } else {
                        fragmentText.append(String(c))
                        offset = i
                    }
                    
                }
            } while offset != text.count - 1
            
            let attributedString = NSMutableAttributedString(string: fragmentText as String)
            newAttributedString.append(attributedString)
        }
        
        return newAttributedString
    }
}
