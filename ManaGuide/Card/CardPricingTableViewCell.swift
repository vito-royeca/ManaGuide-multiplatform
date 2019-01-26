//
//  CardPricingTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 10.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PromiseKit

class CardPricingTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CardPricingCell"
    static let cellHeight = CGFloat(66)
    
    // MARK: Variables
    var card: CMCard? {
        didSet {
            updateDataDisplay()
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var lowNormalLabel: UILabel!
    @IBOutlet weak var medianNormalLabel: UILabel!
    @IBOutlet weak var highNormalLabel: UILabel!
    @IBOutlet weak var marketNormalLabel: UILabel!
    @IBOutlet weak var lowFoilLabel: UILabel!
    @IBOutlet weak var medianFoilLabel: UILabel!
    @IBOutlet weak var highFoilLabel: UILabel!
    @IBOutlet weak var marketFoilLabel: UILabel!
    
    
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        selectionStyle = .none
        accessoryType = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Custom methods
    func clearDataDisplay() {
        lowNormalLabel.text = "NA"
        medianNormalLabel.text = "NA"
        highNormalLabel.text = "NA"
        marketNormalLabel.text = "NA"
        lowFoilLabel.text = "NA"
        medianFoilLabel.text = "NA"
        highFoilLabel.text = "NA"
        marketFoilLabel.text = "NA"
    }

    private func updateDataDisplay() {
        guard let card = card else {
            clearDataDisplay()
            return
        }
        
        for pricing in card.pricings {
            if pricing.isFoil {
                lowNormalLabel.text = pricing.lowPrice > 0 ? String(format: "$%.2f", pricing.lowPrice) : "NA"
                medianNormalLabel.text = pricing.midPrice > 0 ? String(format: "$%.2f", pricing.midPrice) : "NA"
                highNormalLabel.text = pricing.highPrice > 0 ? String(format: "$%.2f", pricing.highPrice) : "NA"
                marketNormalLabel.text = pricing.marketPrice > 0 ? String(format: "$%.2f", pricing.marketPrice) : "NA"
            } else {
                lowFoilLabel.text = pricing.lowPrice > 0 ? String(format: "$%.2f", pricing.lowPrice) : "NA"
                medianFoilLabel.text = pricing.midPrice > 0 ? String(format: "$%.2f", pricing.midPrice) : "NA"
                highFoilLabel.text = pricing.highPrice > 0 ? String(format: "$%.2f", pricing.highPrice) : "NA"
                marketFoilLabel.text = pricing.marketPrice > 0 ? String(format: "$%.2f", pricing.marketPrice) : "NA"
            }
        }
    }
}
