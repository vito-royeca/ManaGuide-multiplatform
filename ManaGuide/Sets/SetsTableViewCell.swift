//
//  SetsTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 24.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class SetsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SetsCell"
    
    // MARK: Outlets
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!

    // MARK: Variables
    var set: CMSet! {
        didSet {
            logoLabel.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            nameLabel.text = set.name
            codeLabel.text = set.code
            releaseDateLabel.text = set.releaseDate
            numberLabel.text = "\(set.cards!.allObjects.count) cards"
        }
    }
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
