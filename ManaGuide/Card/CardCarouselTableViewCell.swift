//
//  CardCarouselTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 04/12/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import iCarousel
import IDMPhotoBrowser
import ManaKit
import PromiseKit

protocol CardCarouselTableViewCellDelegate: NSObjectProtocol {
    func showPhotoBrowser(_ browser: IDMPhotoBrowser)
    func updatePricingAndActions()
    func updateCardImage()
}

class CardCarouselTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CardCarouselCell"
    
    // MARK: Variables
    var viewModel: CardViewModel! {
        didSet {
            carouselView.dataSource = self
            carouselView.delegate = self
            carouselView.currentItemIndex = viewModel.cardIndex
        }
    }
    var delegate: CardCarouselTableViewCellDelegate?
    
    // MARK: Outlets
    @IBOutlet weak var carouselView: iCarousel!
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        carouselView.type = .coverFlow2
        carouselView.isPagingEnabled = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Custom methods
    func showImage(ofCard card: CMCard, inImageView imageView: UIImageView, animate: Bool) {
        if let image = ManaKit.sharedInstance.cardImage(card,
                                                        imageType: .normal,
                                                        faceOrder: viewModel.faceOrder,
                                                        roundCornered: true) {
            
            if animate {
                guard let layout = card.layout,
                    let layoutName = layout.name else {
                    return
                }
                
                if layoutName == "Double faced token" ||
                    layoutName == "Transform" {
                    let animations = {
                        imageView.image = image
                    }
                    UIView.transition(with: imageView,
                                      duration: 1.0,
                                      options: .transitionFlipFromRight,
                                      animations: animations,
                                      completion: nil)
                    
                } else if layoutName == "Flip"  ||
                    layoutName == "Planar" {
                    imageView.image = image
                    UIView.animate(withDuration: 1.0, animations: {
                        imageView.transform = CGAffineTransform(rotationAngle: self.viewModel.flipAngle)
                    })
                }
            } else {
                imageView.image = image
                imageView.transform = CGAffineTransform(rotationAngle: 0)
            }
            
        } else {
            imageView.image = ManaKit.sharedInstance.cardBack(card)
            
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card,
                                                     imageType: .normal,
                                                     faceOrder: viewModel.faceOrder)
            }.done {
                guard let image = ManaKit.sharedInstance.cardImage(card,
                                                                   imageType: .normal,
                                                                   faceOrder: self.viewModel.faceOrder,
                                                                   roundCornered: true) else {
                    return
                }
                
                let animations = {
                    imageView.image = image
                }
                UIView.transition(with: imageView,
                                  duration: 1.0,
                                  options: .transitionCrossDissolve,
                                  animations: animations,
                                  completion: nil)
                
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    func movePhotoTo(index: Int) {
        viewModel.cardIndex = index
        viewModel.cardRelatedDataLoaded = false
        viewModel.faceOrder = 0
        viewModel.flipAngle = 0
        viewModel.reloadRelatedCards()
        delegate?.updatePricingAndActions()
    }
    
    @objc func imageAction() {
        var photos = [ManaGuidePhoto]()
        
        for i in 0...viewModel.numberOfCards() - 1 {
            if let card = viewModel.object(forRowAt: IndexPath(row: i, section: 0)) as? CMCard {
                photos.append(ManaGuidePhoto(withCard: card))
            }
        }
        
        if let browser = IDMPhotoBrowser(photos: photos) {
            browser.setInitialPageIndex(UInt(viewModel.cardIndex))
            browser.displayActionButton = false
            browser.usePopAnimation = true
            browser.forceHideStatusBar = true
            browser.delegate = self
            delegate?.showPhotoBrowser(browser)
        }
    }
    
    @objc func buttonAction() {
        guard let imageView = carouselView.itemView(at: viewModel.cardIndex) as? UIImageView,
            let card = viewModel.object(forRowAt: IndexPath(row: viewModel.cardIndex, section: 0)) as? CMCard,
            let layout = card.layout,
            let layoutName = layout.name else {
            return
        }
        
        if layoutName == "Double faced token" ||
            layoutName == "Transform" {
            if let facesSet = card.faces,
                let faces = facesSet.allObjects as? [CMCard] {
                
                let orderedFaces = faces.sorted(by: {(a, b) -> Bool in
                    return a.faceOrder < b.faceOrder
                })
                let count = orderedFaces.count
                
                if (viewModel.faceOrder + 1) >= count {
                    viewModel.faceOrder = 0
                } else {
                    viewModel.faceOrder += 1
                }
            }
        } else if layoutName == "Flip" {
            viewModel.flipAngle = viewModel.flipAngle == 0 ? CGFloat(180 * Double.pi / 180) : 0
        } else if layoutName == "Planar" {
            viewModel.flipAngle = viewModel.flipAngle == 0 ? CGFloat(90 * Double.pi / 180) : 0
        }
        
        showImage(ofCard: card, inImageView: imageView, animate: true)
    }
}

// MARK: iCarouselDataSource
extension CardCarouselTableViewCell : iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
        return viewModel.numberOfCards()
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var imageView = UIImageView(frame: CGRect.zero)
        
        //reuse view if available, otherwise create a new view
        if let v = view as? UIImageView {
            imageView = v
            
        } else {
            let height = contentView.frame.size.height //- 88
            let width = contentView.frame.size.width - 40
            imageView = UIImageView(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: width,
                                                  height: height))
            imageView.contentMode = .scaleAspectFit
            
            // add tap handler
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageAction))
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(tap)
            
            // add drop shadow
//            imageView.layer.shadowColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.45).cgColor
//            imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
//            imageView.layer.shadowOpacity = 1
//            imageView.layer.shadowRadius = 6.0
//            imageView.clipsToBounds = false
        }
        
        if  let card = viewModel.object(forRowAt: IndexPath(row: index, section: 0)) as? CMCard {
            showImage(ofCard: card, inImageView: imageView, animate: false)
            
            // add action button
            for v in imageView.subviews {
                v.removeFromSuperview()
            }
            if let layout = card.layout,
                let layoutName = layout.name {
                
                var buttonImage: UIImage?
                var willAddButton = false
                
                if layoutName == "Double faced token" ||
                    layoutName == "Transform" {
                    buttonImage = UIImage.fontAwesomeIcon(name: .sync,
                                                          style: .solid,
                                                          textColor: UIColor.white,
                                                          size: CGSize(width: 30, height: 30))
                    willAddButton = true
                } else if layoutName == "Flip" ||
                    layoutName == "Planar" {
                    buttonImage = UIImage.fontAwesomeIcon(name: .redo,
                                                          style: .solid,
                                                          textColor: UIColor.white,
                                                          size: CGSize(width: 30, height: 30))
                    willAddButton = true
                }
                
                if willAddButton {
                    let button = UIButton(frame: CGRect(x: imageView.frame.size.width - 60,
                                                        y: (imageView.frame.size.height - 60) / 4,
                                                        width: 60,
                                                        height: 60))
                    button.layer.masksToBounds = true
                    button.layer.cornerRadius = button.frame.height / 2
                    button.setTitle(nil, for: .normal)
                    button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                    button.setBackgroundColor(LookAndFeel.GlobalTintColor, for: .normal)
                    button.setImage(buttonImage, for: .normal)
                    imageView.addSubview(button)
                }
            }
        }

        return imageView
    }
}

// MARK: iCarouselDelegate
extension CardCarouselTableViewCell : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        movePhotoTo(index: carousel.currentItemIndex)
    }
}

// MARK: IDMPhotoBrowserDelegate
extension CardCarouselTableViewCell : IDMPhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser,  didShowPhotoAt index: UInt) {
        let i = Int(index)
        
        if i != viewModel.cardIndex {
            movePhotoTo(index: i)
            delegate?.updateCardImage()
        }
    }
}

