//
//  LatestSetItemCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class LatestSetItemCell: UICollectionViewCell {
    static let reuseIdentifier = "LatestSetItemCell"
    
    // MARK: Outlets
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    // MARK: Variables
    var set: CMSet! {
        didSet {
            logoLabel.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            nameLabel.text = set.name
        }
    }
}
