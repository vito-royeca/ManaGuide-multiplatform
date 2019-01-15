//
//  CardActionsTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import Cosmos

protocol CardActionsTableViewCellDelegate : NSObjectProtocol {
    func favoriteAction()
    func ratingAction()
}

class CardActionsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CardActionsCell"
    static let cellHeight = CGFloat(44)
    
    // MARK: Variables
    var delegate: CardActionsTableViewCellDelegate?
    
    // MARK: Outlets
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var viewsLabel: UILabel!

    // MARK: Actions
    
    @IBAction func favoriteAction(_ sender: UIButton) {
        delegate?.favoriteAction()
    }
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        ratingView.settings.emptyBorderColor = LookAndFeel.GlobalTintColor
        ratingView.settings.filledBorderColor = LookAndFeel.GlobalTintColor
        ratingView.settings.filledColor = LookAndFeel.GlobalTintColor
        ratingView.settings.fillMode = .precise
        ratingView.didFinishTouchingCosmos = { _ in
            self.delegate?.ratingAction()
        }
        
        favoriteButton.setTitleColor(LookAndFeel.GlobalTintColor,
                                     for: .normal)
        selectionStyle = .none
        accessoryType = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
