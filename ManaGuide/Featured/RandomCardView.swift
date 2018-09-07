//
//  RandomCardView.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 14/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit

import CoreData
import ChameleonFramework
import ManaKit
import PromiseKit

class RandomCardView: UIView {

    // MARK: Constants
    let preEightEditionFont      = UIFont(name: "Magic:the Gathering", size: 20.0)
    let eightEditionFont         = UIFont(name: "Matrix-Bold", size: 20.0)
    let magic2015Font            = UIFont(name: "Beleren", size: 20.0)

    // MARK: Variables
    var cardMID: NSManagedObjectID?
//    var contrastColor: UIColor?
    
    // MARK: Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var setIcon: UILabel!
    @IBOutlet weak var cropImageView: UIImageView!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        setIcon.layer.cornerRadius = setIcon.frame.height / 2
    }
    
    // MARK: Custom methods
    func showImage() {
        guard let cardMID = cardMID,
            let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: cardMID) as? CMCard else {
            return
        }
        
        if let image = ManaKit.sharedInstance.cardImage(card, imageType: .artCrop) {
            cropImageView.image = image
            updateNameLabelColorFrom(image: image)
        } else {
            cropImageView.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
            updateNameLabelColorFrom(image: cropImageView.image!)
            
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .artCrop)
            }.done {
                guard let image = ManaKit.sharedInstance.cardImage(card, imageType: .artCrop) else {
                    return
                }
                
                let animations = {
                    self.cropImageView.image = image
                }
                UIView.transition(with: self.cropImageView,
                                  duration: 1.0,
                                  options: .transitionCrossDissolve,
                                  animations: animations,
                                  completion: nil)
                self.updateNameLabelColorFrom(image: image)
                
                
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    func showNameandSet() {
        guard let cardMID = cardMID,
            let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: cardMID) as? CMCard else {
                return
        }
        
        nameLabel.text = card.name
        
        if let releaseDate = card.set!.releaseDate {
            let isModern = ManaKit.sharedInstance.isModern(card)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            if let m15Date = formatter.date(from: "2014-07-18"),
                let setReleaseDate = formatter.date(from: releaseDate) {
                
                if setReleaseDate.compare(m15Date) == .orderedSame ||
                    setReleaseDate.compare(m15Date) == .orderedDescending {
                    nameLabel.font = magic2015Font
                    
                } else {
                    nameLabel.font = isModern ? eightEditionFont : preEightEditionFont
                }
            }
        }
        
        if let set = card.set {
            setIcon.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            setIcon.textColor = ManaKit.sharedInstance.keyruneColor(forCard: card)
            setIcon.backgroundColor = UIColor.white
        }
    }
    
    func hideNameandSet() {
        nameLabel.text = ""
        setIcon.text = ""
        setIcon.backgroundColor = UIColor.clear
    }
    
    func updateNameLabelColorFrom(image: UIImage) {
        let averageColor = AverageColorFromImage(image)
        let shadowColor = averageColor
        let shadowOffset = CGSize(width: 2, height: 2)

        nameLabel.textColor = UIColor.white
        nameLabel.shadowColor = shadowColor
        nameLabel.shadowOffset = shadowOffset
    }
}


