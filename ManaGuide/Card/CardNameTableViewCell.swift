//
//  CardNameTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30/10/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class CardNameTableViewCell: UITableViewCell {

    static let reuseIdentifier = "CardNameCell"
    
    // MARK: Variables
    var card: CMCard? {
        didSet {
            guard let card = card else {
                nameLabel.text = nil
                manaCostLabel.text = nil
                return
            }
            
            nameLabel.text = ManaKit.sharedInstance.name(ofCard: card)
            if let releaseDate = card.set!.releaseDate {
                let isModern = ManaKit.sharedInstance.isModern(card)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                if let m15Date = formatter.date(from: "2014-07-18"),
                    let setReleaseDate = formatter.date(from: releaseDate) {
                    
                    var shadowColor:UIColor?
                    var shadowOffset = CGSize(width: 0, height: -1)
                    
                    if setReleaseDate.compare(m15Date) == .orderedSame ||
                        setReleaseDate.compare(m15Date) == .orderedDescending {
                        nameLabel.font = ManaKit.Fonts.magic2015
                        
                    } else {
                        nameLabel.font = isModern ? ManaKit.Fonts.eightEdition : ManaKit.Fonts.preEightEdition
                        
                        if !isModern {
                            shadowColor = UIColor.darkGray
                            shadowOffset = CGSize(width: 1, height: 1)
                        }
                    }
                    
                    nameLabel.shadowColor = shadowColor
                    nameLabel.shadowOffset = shadowOffset
                }
            }
            
            if let manaCost = card.manaCost {
                let pointSize = manaCostLabel.font.pointSize
                manaCostLabel.attributedText = NSAttributedString(symbol: manaCost, pointSize: pointSize)
            } else {
                manaCostLabel.text = nil
            }
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var manaCostLabel: UILabel!
    
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
