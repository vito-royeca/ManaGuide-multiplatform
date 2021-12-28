//
//  SearchModeTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 04.10.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PromiseKit
import SDWebImage

class SearchModeTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SearchModeCell"
    
    // MARK: Variables
    var mode: ViewModelMode! {
        didSet {
            guard let cardArt = mode.cardArt,
                let urlString = cardArt["artCropURL"],
                let url = URL(string: urlString),
                let path = SDImageCache.shared.cachePath(forKey: urlString) else {
                return
            }
            
            messageLabel.text = mode.description
            
            if let image = UIImage(contentsOfFile: path) {
                backgroundImage.image = image
                MGUtilities.updateColor(ofLabel: messageLabel, from: image)
            } else {
                backgroundImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                
                firstly {
                    ManaKit.sharedInstance.downloadImage(url: url)
                }.done {
                    if let image = UIImage(contentsOfFile: path) {
                        let animations = {
                            self.backgroundImage.image = image
                        }
                        UIView.transition(with: self.backgroundImage,
                                          duration: 1.0,
                                          options: .transitionCrossDissolve,
                                          animations: animations,
                                          completion: nil)
                        MGUtilities.updateColor(ofLabel: self.messageLabel, from: image)
                    }
                }.catch { error in
                        print("\(error)")
                }
            }
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        backgroundImage.layer.cornerRadius = 10
    }
}
