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
    
    // MARK: Outlets
    @IBOutlet weak var lowPriceLabel: UILabel!
    @IBOutlet weak var midPriceLabel: UILabel!
    @IBOutlet weak var highPriceLabel: UILabel!
    @IBOutlet weak var foilPriceLabel: UILabel!
    
    // MARK: Variables
    var card: CMCard? {
        didSet {
            guard let card = card else {
                clearDataDisplay()
                return
            }
            
            var willFetchPricing = false
            if let set = card.set {
                willFetchPricing = !set.onlineOnly
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
        lowPriceLabel.textColor = kNormalColor
        
        midPriceLabel.text = "NA"
        midPriceLabel.textColor = kNormalColor
        
        highPriceLabel.text = "NA"
        highPriceLabel.textColor = kNormalColor
        
        foilPriceLabel.text = "NA"
        foilPriceLabel.textColor = kNormalColor
    }

    func updatePricing() {
        guard let card = card,
            let pricing = card.pricing else {
                lowPriceLabel.text = "NA"
                lowPriceLabel.textColor = kNormalColor
                
                midPriceLabel.text = "NA"
                midPriceLabel.textColor = kNormalColor
                
                highPriceLabel.text = "NA"
                highPriceLabel.textColor = kNormalColor
                
                foilPriceLabel.text = "NA"
                foilPriceLabel.textColor = kNormalColor
                return
        }
        
        lowPriceLabel.text = pricing.low > 0 ? String(format: "$%.2f", pricing.low) : "NA"
        lowPriceLabel.textColor = pricing.low > 0 ? kLowPriceColor : kNormalColor
        
        midPriceLabel.text = pricing.average > 0 ? String(format: "$%.2f", pricing.average) : "NA"
        midPriceLabel.textColor = pricing.average > 0 ? kMidPriceColor : kNormalColor
        
        highPriceLabel.text = pricing.high > 0 ? String(format: "$%.2f", pricing.high) : "NA"
        highPriceLabel.textColor = pricing.high > 0 ? kHighPriceColor : kNormalColor
        
        foilPriceLabel.text = pricing.foil > 0 ? String(format: "$%.2f", pricing.foil) : "NA"
        foilPriceLabel.textColor = pricing.foil > 0 ? kFoilPriceColor : kNormalColor
    }
}
