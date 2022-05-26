//
//  DynamicHeightTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 05.10.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit

class DynamicHeightTableViewCell: UITableViewCell {
    static let reuseIdentifier = "DynamicHeightCell"
    
    // MARK: Outlets
    @IBOutlet weak var dynamicLabel: UILabel!
    
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
