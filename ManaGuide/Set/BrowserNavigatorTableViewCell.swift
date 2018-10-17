//
//  BrowserNavigatorTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 27.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import FontAwesome_swift

protocol BrowserNavigatorTableViewCellDelegate: NSObjectProtocol {
    func back()
    func forward()
    func reload()
}

class BrowserNavigatorTableViewCell: UITableViewCell {
    static let reuseIdentifier = "BrowserNavigatorCell"
    
    // MARK: Variables
    var delegate: BrowserNavigatorTableViewCellDelegate?
    
    // MARK: Outlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    // MARK: Actions
    @IBAction func backAction(_ sender: UIButton) {
        delegate?.back()
    }
    
    @IBAction func forwardAction(_ sender: UIButton) {
        delegate?.forward()
    }
    
    @IBAction func refreshAction(_ sender: UIButton) {
        delegate?.reload()
    }
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        backButton.setImage(UIImage.fontAwesomeIcon(name: .arrowCircleLeft,
                                                    style: .solid,
                                                    textColor: LookAndFeel.GlobalTintColor,
                                                    size: CGSize(width: 20, height: 20)),
                            for: .normal)
        
        forwardButton.setImage(UIImage.fontAwesomeIcon(name: .arrowRight,
                                                       style: .solid,
                                                       textColor: LookAndFeel.GlobalTintColor,
                                                       size: CGSize(width: 20, height: 20)),
                               for: .normal)

        refreshButton.setImage(UIImage.fontAwesomeIcon(name: .redo,
                                                       style: .solid,
                                                       textColor: LookAndFeel.GlobalTintColor,
                                                       size: CGSize(width: 20, height: 20)),
                               for: .normal)
        
        selectionStyle = .none
        accessoryType = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
