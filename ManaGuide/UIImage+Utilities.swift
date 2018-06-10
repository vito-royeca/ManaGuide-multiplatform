//
//  UIImage+Utilities.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 10/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func roundCornered(radius: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: 0), size: self.size), cornerRadius: radius).addClip()
        self.draw(in:  CGRect(origin: CGPoint(x: 0, y: 0), size: self.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!
    }
}
