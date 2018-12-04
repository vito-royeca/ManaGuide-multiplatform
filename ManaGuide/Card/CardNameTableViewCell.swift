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
    let preEightEdition      = UIFont(name: "Magic:the Gathering", size: 20.0)
    let eightEdition         = UIFont(name: "Matrix-Bold", size: 20.0)
    let magic2015            = UIFont(name: "Beleren", size: 20.0)
    
    // MARK: Variables
    var card: CMCard? {
        didSet {
            guard let card = card else {
                nameLabel.text = nil
                manaCostLabel.text = nil
                return
            }
            
            nameLabel.text = card.displayName
            if let releaseDate = card.set!.releaseDate {
                let isModern = ManaKit.sharedInstance.isModern(card)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                if let m15Date = formatter.date(from: "2014-07-18"),
                    let setReleaseDate = formatter.date(from: releaseDate) {
                    
                    if setReleaseDate.compare(m15Date) == .orderedSame ||
                        setReleaseDate.compare(m15Date) == .orderedDescending {
                        nameLabel.font = magic2015
                    } else {
                        nameLabel.font = isModern ? eightEdition : preEightEdition
                    }
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
