//
//  CardSetTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30/10/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class CardSetTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CardSetCell"
    
    // MARK: Variables
    var card: CMCard? {
        didSet {
            guard let card = card else {
                imageLabel.text = nil
                nameLabel.text = nil
                detailsLabel.text = nil
                return
            }
            
            var detailsText = ""
            
            if let set = card.set {
                imageLabel.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
                imageLabel.textColor = ManaKit.sharedInstance.keyruneColor(forCard: card)
                nameLabel.text = "\(set.name!) (\(set.code!))"
            }
            
            
            if let colllectorNumber = card.collectorNumber {
                detailsText.append("#\(colllectorNumber)")
            }
            if let rarity = card.rarity,
                let name = rarity.name {
                detailsText.append(" \u{2022} \(name)")
            }
            if let language = card.language,
                let name = language.name {
                detailsText.append(" \u{2022} \(name)")
            }
            
            detailsLabel.text = detailsText
        }
    }

    // MARK: Outlets
    @IBOutlet weak var imageLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
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
