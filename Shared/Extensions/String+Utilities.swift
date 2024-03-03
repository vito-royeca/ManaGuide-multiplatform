//
//  String+Utilities.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/14/23.
//

import Foundation

extension String {
    static let emdash = "\u{2014}"
    
    func keyrune2Unicode() -> String {
        guard let charAsInt = Int(self, radix: 16),
           let uScalar = UnicodeScalar(charAsInt) else {
            return ""
        }
        let unicode = "\(uScalar)"
        
        return unicode
    }
}
