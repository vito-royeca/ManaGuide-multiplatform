//
//  View+Extras.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/31/22.
//

import SwiftUI

extension View {
    func addColor(to attributedString: NSAttributedString, colorScheme: ColorScheme) -> NSAttributedString {
        let newAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        let range = NSRange(location: 0, length: newAttributedString.string.count)
        let color = colorScheme == .dark ? UIColor.white : UIColor.black
        newAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        
        return newAttributedString
    }
}
