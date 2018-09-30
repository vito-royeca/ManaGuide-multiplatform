//
//  BrowserNavigatorTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 27.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import Font_Awesome_Swift

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
        
        backButton.setImage(UIImage(bgIcon: .FAArrowCircleLeft,
                                    orientation: UIImageOrientation.up,
                                    bgTextColor: LookAndFeel.GlobalTintColor,
                                    bgBackgroundColor: UIColor.clear,
                                    topIcon: .FAArrowCircleLeft,
                                    topTextColor: UIColor.clear,
                                    bgLarge: true,
                                    size: CGSize(width: 20, height: 20)),
                            for: .normal)
        
        forwardButton.setImage(UIImage(bgIcon: .FAArrowRight,
                                       orientation: UIImageOrientation.up,
                                       bgTextColor: LookAndFeel.GlobalTintColor,
                                       bgBackgroundColor: UIColor.clear,
                                       topIcon: .FAArrowRight,
                                       topTextColor: UIColor.clear,
                                       bgLarge: true,
                                       size: CGSize(width: 20, height: 20)),
                               for: .normal)
        
        refreshButton.setImage(UIImage(bgIcon: .FARefresh,
                                       orientation: UIImageOrientation.up,
                                       bgTextColor: LookAndFeel.GlobalTintColor,
                                       bgBackgroundColor: UIColor.clear,
                                       topIcon: .FARefresh,
                                       topTextColor: UIColor.clear,
                                       bgLarge: true,
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
