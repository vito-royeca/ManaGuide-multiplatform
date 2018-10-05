//
//  EmptyTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 04.10.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PromiseKit

class EmptyTableViewCell: UITableViewCell {
    static let reuseIdentifier = "EmptyCell"
    
    // MARK: Outlets
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        let objectFinder = ["name": LookAndFeel.EmptySearchCardName,
                            "set.code": LookAndFeel.EmptySearchSetCode] as [String: AnyObject]
        guard let card = ManaKit.sharedInstance.findObject("CMCard",
                                                           objectFinder: objectFinder,
                                                           createIfNotFound: false) as? CMCard else {
                                                            return
        }
        
        if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
            backgroundImage.image = croppedImage
        } else {
            backgroundImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
            
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .artCrop)
                }.done {
                    guard let image = ManaKit.sharedInstance.croppedImage(card) else {
                        return
                    }
                    
                    let animations = {
                        self.backgroundImage.image = image
                    }
                    UIView.transition(with: self.backgroundImage,
                                      duration: 1.0,
                                      options: .transitionCrossDissolve,
                                      animations: animations,
                                      completion: nil)
                }.catch { error in
                    
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
