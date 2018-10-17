//
//  BrowserTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 26/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit

class BrowserTableViewCell: UITableViewCell {
    static let reuseIdentifier = "BrowserCell"
    
    // MARK: Outlets
    @IBOutlet weak var webView: UIWebView!
    
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
    
}
