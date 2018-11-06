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
    
    // MARK: Variables
    var card: CMCard? {
        didSet {
            guard let card = card else {
                clearDataDisplay()
                return
            }
            
            var willFetchPricing = false
            if let set = card.set {
                willFetchPricing = !set.isOnlineOnly
            }
            if willFetchPricing {
                firstly {
                    ManaKit.sharedInstance.fetchTCGPlayerCardPricing(card: card)
                    }.done {
                        self.updatePricing()
                    }.catch { error in
                        self.updatePricing()
                }
            } else {
                updatePricing()
            }
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var lowPriceLabel: UILabel!
    @IBOutlet weak var midPriceLabel: UILabel!
    @IBOutlet weak var highPriceLabel: UILabel!
    @IBOutlet weak var foilPriceLabel: UILabel!
    
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
        lowPriceLabel.text = "NA"
        lowPriceLabel.textColor = ManaKit.PriceColors.normal
        
        midPriceLabel.text = "NA"
        midPriceLabel.textColor = ManaKit.PriceColors.normal
        
        highPriceLabel.text = "NA"
        highPriceLabel.textColor = ManaKit.PriceColors.normal
        
        foilPriceLabel.text = "NA"
        foilPriceLabel.textColor = ManaKit.PriceColors.normal
    }

    func updatePricing() {
        guard let card = card,
            let pricing = card.pricing else {
                clearDataDisplay()
                return
        }
        
        lowPriceLabel.text = pricing.low > 0 ? String(format: "$%.2f", pricing.low) : "NA"
        lowPriceLabel.textColor = pricing.low > 0 ? ManaKit.PriceColors.low : ManaKit.PriceColors.normal
        
        midPriceLabel.text = pricing.average > 0 ? String(format: "$%.2f", pricing.average) : "NA"
        midPriceLabel.textColor = pricing.average > 0 ? ManaKit.PriceColors.mid : ManaKit.PriceColors.normal
        
        highPriceLabel.text = pricing.high > 0 ? String(format: "$%.2f", pricing.high) : "NA"
        highPriceLabel.textColor = pricing.high > 0 ? ManaKit.PriceColors.high : ManaKit.PriceColors.normal
        
        foilPriceLabel.text = pricing.foil > 0 ? String(format: "$%.2f", pricing.foil) : "NA"
        foilPriceLabel.textColor = pricing.foil > 0 ? ManaKit.PriceColors.foil : ManaKit.PriceColors.normal
    }
}
