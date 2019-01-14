//
//  LatestCardsTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 09.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import iCarousel
import ManaKit
import PromiseKit

protocol LatestCardsTableViewDelegate : NSObjectProtocol {
    func cardSelected(card: CMCard)
}

class LatestCardsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "LatestCardsCell"
    
    // MARK: Outlets
    @IBOutlet weak var carousel: iCarousel!

    // MARK: Variables
    var delegate: LatestCardsTableViewDelegate?
    var viewModel = LatestCardsViewModel()
    
    private var _slideshowTimer: Timer?
    private var _latestCardsTimer: Timer?
    
    @objc    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        carousel.type = .linear
        carousel.isPagingEnabled = true
        carousel.currentItemIndex = 3
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: Custom methods
    func startSlideShow() {
        setupCarousel()
        stopSlideShow()

        _latestCardsTimer = Timer.scheduledTimer(timeInterval: 60 * 5,
                                                 target: self,
                                                 selector: #selector(fetchData),
                                                 userInfo: nil, repeats: true)
        
        _slideshowTimer = Timer.scheduledTimer(timeInterval: 5,
                                               target: self,
                                               selector: #selector(showSlide),
                                               userInfo: nil,
                                               repeats: true)
    }
    
    func stopSlideShow() {
        if _latestCardsTimer != nil {
            _latestCardsTimer!.invalidate()
        }
        _latestCardsTimer = nil
        
        if _slideshowTimer != nil {
            _slideshowTimer!.invalidate()
        }
        _slideshowTimer = nil
    }
    
    @objc func showSlide() {
        var index = carousel.currentItemIndex
        index += 1
        
        carousel.scrollToItem(at: index, animated: true)
    }
    
    @objc private func fetchData() {
        firstly {
            viewModel.fetchData()
        }.done {
            self.viewModel.mode = self.viewModel.isEmpty() ? .noResultsFound : .resultsFound
            self.carousel.reloadData()
        }.catch { error in
            self.viewModel.mode = .error
            self.carousel.reloadData()
        }
    }
    
    private func setupCarousel() {
        carousel.dataSource = self
        carousel.delegate = self
    }
}

// MARK: iCarouselDataSource
extension LatestCardsTableViewCell : iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
        return viewModel.numberOfRows(inSection: 0)
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var rcv: HeroCardView?
        
        //reuse view if available, otherwise create a new view
        if let v = view as? HeroCardView {
            rcv = v
        } else {
            if let r = Bundle.main.loadNibNamed("HeroCardView", owner: self, options: nil)?.first as? HeroCardView {
                let height = contentView.frame.size.height
                var width = contentView.frame.size.width
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    width = width / 3
                }
                
                r.frame = CGRect(x: 0, y: 0, width: width, height: height)
                rcv = r
            }
        }
        
        rcv!.card = viewModel.object(forRowAt: IndexPath(row: index, section: 0)) as? CMCard
        rcv!.hideNameAndSet()
        rcv!.showImage()
        return rcv!
    }
}

// MARK: iCarouselDelegate
extension LatestCardsTableViewCell : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        guard let rcv = carousel.itemView(at: carousel.currentItemIndex) as? HeroCardView else {
            return
        }
        
        for v in carousel.visibleItemViews {
            if let a = v as? HeroCardView {
                if rcv == a {
                    a.showNameAndSet()
                } else {
                    a.hideNameAndSet()
                }
            }
        }
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        guard let card = viewModel.object(forRowAt: IndexPath(row: index, section: 0)) as? CMCard,
            let delegate = delegate else {
            return
        }
        
        delegate.cardSelected(card: card)
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        var returnValue = CGFloat(0)
        
        switch option {
        case .wrap:
            returnValue = CGFloat(1)
        default:
            returnValue = value
        }
        
        return returnValue
    }
}

