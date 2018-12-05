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
    func showImage(ofCard card: CMCard, inImageView imageView: UIImageView) {
        if let image = ManaKit.sharedInstance.cardImage(card,
                                                        imageType: .normal,
                                                        faceOrder: viewModel.faceOrder,
                                                        roundCornered: true) {
            imageView.image = image
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
        viewModel.cardViewIncremented = false
        viewModel.faceOrder = 0
        viewModel.faceAngle = 0
        delegate?.updatePricingAndActions()
        viewModel.loadCardData()
        viewModel.reloadRelatedCards()
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
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            imageView.contentMode = .scaleAspectFit
            
            // add drop shadow
//            imageView.layer.shadowColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.45).cgColor
//            imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
//            imageView.layer.shadowOpacity = 1
//            imageView.layer.shadowRadius = 6.0
//            imageView.clipsToBounds = false
        }
        
        if  let card = viewModel.object(forRowAt: IndexPath(row: index, section: 0)) as? CMCard {
            showImage(ofCard: card, inImageView: imageView)
        }

        return imageView
    }
}

// MARK: iCarouselDelegate
extension CardCarouselTableViewCell : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        movePhotoTo(index: carousel.currentItemIndex)
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        var photos = [ManaGuidePhoto]()
        
        for i in 0...viewModel.numberOfCards() - 1 {
            if let card = viewModel.object(forRowAt: IndexPath(row: i, section: 0)) as? CMCard {
                photos.append(ManaGuidePhoto(withCard: card))
            }
        }
        
        if let browser = IDMPhotoBrowser(photos: photos) {
            browser.setInitialPageIndex(UInt(index))
            browser.displayActionButton = false
            browser.usePopAnimation = true
            browser.forceHideStatusBar = true
            browser.delegate = self
            delegate?.showPhotoBrowser(browser)
        }
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

