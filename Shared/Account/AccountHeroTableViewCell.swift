//
//  AccountHeroTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import Firebase
import FontAwesome_swift
import SDWebImage

class AccountHeroTableViewCell: UITableViewCell {
    static let reuseIdentifier = "AccountHeroCell"

    // MARK: Variables
    var user: User? {
        didSet {
            let image = UIImage.fontAwesomeIcon(name: .userCircle,
                                                style: .solid,
                                                textColor: UIColor.lightGray,
                                                size: CGSize(width: 60, height: 60))
            avatarImage.image = image
            
            if let u = user {
                avatarImage.sd_setImage(with: u.photoURL, completed: nil)
                nameLabel.text = u.displayName
            } else {
                avatarImage.image = image
                nameLabel.text = "Not logged in"
            }
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        avatarImage.layer.cornerRadius = avatarImage.frame.height / 2
        accessoryType = .none
    }

}
