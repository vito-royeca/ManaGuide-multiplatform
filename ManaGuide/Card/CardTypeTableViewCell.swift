//
//  CardTypeTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30/10/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class CardTypeTableViewCell: UITableViewCell {

    static let reuseIdentifier = "CardTypeCell"
    
    // MARK: Variables
    var card: CMCard? {
        didSet {
            guard let card = card else {
                typeImage.image = nil
                typeLabel.text = nil
                return
            }
            
            typeImage.image = ManaKit.sharedInstance.typeImage(ofCard: card)
            typeLabel.text = ManaKit.sharedInstance.typeText(ofCard: card, includePower: false)
        }
    }

    // MARK: Outlets
    @IBOutlet weak var typeImage: UIImageView!
    @IBOutlet weak var typeLabel: UILabel!
    
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
