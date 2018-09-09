//
//  FeaturedViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import Cosmos
import iCarousel
import ManaKit
import MBProgressHUD
import PromiseKit

class FeaturedViewController: BaseViewController {

    // MARK: Variables
    let latestCardsViewModel = LatestCardsViewModel()
    let latestSetsViewModel  = LatestSetsViewModel()
    let topRatedViewModel    = TopRatedViewModel()
    let topViewedViewModel   = TopViewedViewModel()
    
    var slideshowTimer: Timer?
    var latestCardsTimer: Timer?
    var flowLayoutHeight = CGFloat(0)
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        latestCardsViewModel.fetchData()
        latestSetsViewModel.fetchData()
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadTopRated(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                               object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadTopViewed(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                               object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSlideShow()
        topRatedViewModel.fetchData()
        topViewedViewModel.fetchData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSlideShow()
        topRatedViewModel.stopMonitoring()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        flowLayoutHeight = (view.frame.size.height / 3) - 50
        tableView.reloadData()
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedSection.latestCards.rawValue, section: 0)) else {
            return
        }
        guard let carouselView = cell.viewWithTag(100) as? iCarousel else {
            return
        }
        
        carouselView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let cardMIDs = dict["cardMIDs"] as? [NSManagedObjectID] else {
                return
            }
            
            dest.cardIndex = cardIndex
            dest.cardMIDs = cardMIDs
            
        } else if segue.identifier == "showCardModal" {
            guard let nav = segue.destination as? UINavigationController,
                let dest = nav.childViewControllers.first as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let cardMIDs = dict["cardMIDs"] as? [NSManagedObjectID] else {
                return
            }
            
            let cardMID = cardMIDs[cardIndex]
            guard let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: cardMID) as? CMCard else {
                return
            }
            
            dest.cardIndex = cardIndex
            dest.cardMIDs = cardMIDs
            dest.title = card.name
            
        } else if segue.identifier == "showSet" {
            guard let dest = segue.destination as? SetViewController,
                let dict = sender as? [String: Any],
                let set = dict["set"] as? CMSet else {
                return
            }
            
            dest.title = set.name
            dest.set = set

        } else if segue.identifier == "showSets" {
            guard let dest = segue.destination as? SetsViewController else {
                return
            }
            
            dest.title = "Sets"
        }
    }

    // MARK: Custom methods
    func reloadTopRated(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: FeaturedSection.topRated.rawValue, section: 0)) else {
                return
            }
            
            for v in cell.contentView.subviews {
                if let collectionView = v as? UICollectionView {
                    collectionView.reloadData()
                    break
                }
            }
        }
    }
    
    func reloadTopViewed(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let cell = self.tableView.cellForRow(at: IndexPath(row: FeaturedSection.topViewed.rawValue, section: 0)) else {
                return
            }
            
            for v in cell.contentView.subviews {
                if let collectionView = v as? UICollectionView {
                    collectionView.reloadData()
                    break
                }
            }
        }
    }

    func showAllSets(_ sender: UIButton) {
        performSegue(withIdentifier: "showSets", sender: nil)
    }
    
    // MARK: Slideshow
    func startSlideShow() {
        latestCardsTimer = Timer.scheduledTimer(timeInterval: 60 * 5,
                                                target: latestCardsViewModel,
                                                selector: #selector(LatestSetsViewModel.fetchData),
                                                userInfo: nil, repeats: true)
        
        slideshowTimer = Timer.scheduledTimer(timeInterval: 5,
                                              target: self,
                                              selector: #selector(showSlide),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    func stopSlideShow() {
        if latestCardsTimer != nil {
            latestCardsTimer!.invalidate()
        }
        latestCardsTimer = nil
        
        if slideshowTimer != nil {
            slideshowTimer!.invalidate()
        }
        slideshowTimer = nil
    }
    
    func showSlide() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedSection.latestCards.rawValue, section: 0)) else {
            return
        }
        guard let carouselView = cell.viewWithTag(100) as? iCarousel else {
            return
        }
        
        var index = carouselView.currentItemIndex
        index += 1
        
        carouselView.scrollToItem(at: index, animated: true)
    }
}

// MARK: UITableViewDataSource
extension FeaturedViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FeaturedSection.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        
        if flowLayoutHeight == 0 {
            flowLayoutHeight = (view.frame.size.height / 3) - 50
        }

        switch indexPath.row {
        case FeaturedSection.latestCards.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "HeroCell"),
                let carouselView = c.viewWithTag(100) as? iCarousel else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            carouselView.dataSource = self
            carouselView.delegate = self
            carouselView.type = .linear
            carouselView.isPagingEnabled = true
            carouselView.currentItemIndex = 3
            cell = c
            
        case FeaturedSection.latestSets.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell"),
                let titleLabel = c.viewWithTag(100) as? UILabel,
                let showAllButton = c.viewWithTag(200) as? UIButton else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            titleLabel.text = FeaturedSection.latestSets.description
            showAllButton.addTarget(self, action: #selector(self.showAllSets(_:)), for: .touchUpInside)
            
            var collectionView: UICollectionView?
            for v in c.contentView.subviews {
                if let cv = v as? UICollectionView {
                    collectionView = cv
                    break
                }
            }
            
            if let collectionView = collectionView {
                if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    let divisor = CGFloat(UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4)
                    let width = (view.frame.size.width / divisor) - 20
                    flowLayout.itemSize = CGSize(width: width - 20, height: flowLayoutHeight - 5)
                    flowLayout.scrollDirection = .horizontal
                    flowLayout.minimumInteritemSpacing = CGFloat(5)
                    flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                }
                
                collectionView.dataSource = self
                collectionView.delegate = self
                collectionView.tag = FeaturedSection.latestSets.rawValue
                collectionView.reloadData()
            }
            
            cell = c
            
        case FeaturedSection.topRated.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell"),
                let titleLabel = c.viewWithTag(100) as? UILabel,
                let showAllButton = c.viewWithTag(200) as? UIButton else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            titleLabel.text = FeaturedSection.topRated.description
            showAllButton.isHidden = true
            
            var collectionView: UICollectionView?
            for v in c.contentView.subviews {
                if let cv = v as? UICollectionView {
                    collectionView = cv
                    break
                }
            }
            
            if let collectionView = collectionView {
                if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    let width = flowLayoutHeight + (flowLayoutHeight / 2)
                    flowLayout.itemSize = CGSize(width: width - 20, height: flowLayoutHeight - 5)
                    flowLayout.scrollDirection = .horizontal
                    flowLayout.minimumInteritemSpacing = CGFloat(5)
                    flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                }
                
                collectionView.dataSource = self
                collectionView.delegate = self
                collectionView.tag = FeaturedSection.topRated.rawValue
            }
            cell = c
            
        case FeaturedSection.topViewed.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell"),
                let titleLabel = c.viewWithTag(100) as? UILabel,
                let showAllButton = c.viewWithTag(200) as? UIButton else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            titleLabel.text = FeaturedSection.topViewed.description
            showAllButton.isHidden = true
            
            var collectionView: UICollectionView?
            for v in c.contentView.subviews {
                if let cv = v as? UICollectionView {
                    collectionView = cv
                    break
                }
            }
            
            if let collectionView = collectionView {
                if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    let width = flowLayoutHeight + (flowLayoutHeight / 2)
                    flowLayout.itemSize = CGSize(width: width - 20, height: flowLayoutHeight - 5)
                    flowLayout.scrollDirection = .horizontal
                    flowLayout.minimumInteritemSpacing = CGFloat(5)
                    flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                }
                
                collectionView.dataSource = self
                collectionView.delegate = self
                collectionView.tag = FeaturedSection.topViewed.rawValue
            }
            cell = c
            
        default:
            ()
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension FeaturedViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)
        
        switch indexPath.row {
        case FeaturedSection.latestCards.rawValue,
             FeaturedSection.latestSets.rawValue,
             FeaturedSection.topRated.rawValue,
             FeaturedSection.topViewed.rawValue:
            height = view.frame.size.height / 3
        default:
            height = UITableViewAutomaticDimension
        }
        
        return height
    }
}

// MARK: UICollectionViewDataSource
extension FeaturedViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        switch collectionView.tag {
        case FeaturedSection.topRated.rawValue:
            count = topRatedViewModel.numberOfRows(inSection: section)
        case FeaturedSection.topViewed.rawValue:
            count = topViewedViewModel.numberOfRows(inSection: section)
        case FeaturedSection.latestSets.rawValue:
            count = latestSetsViewModel.numberOfItems()
        default:
            ()
        }
        
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        switch collectionView.tag {
        case FeaturedSection.latestSets.rawValue:
            guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: LatestSetItemCell.reuseIdentifier,
                                                            for: indexPath) as? LatestSetItemCell else {
                fatalError("LatestSetItemCell not found")
            }
            c.set = latestSetsViewModel.objectAt(indexPath.item)
            cell = c
            
        case FeaturedSection.topRated.rawValue:
            guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: TopRatedItemCell.reuseIdentifier,
                                                                for: indexPath) as? TopRatedItemCell else {
                fatalError("TopRatedItemCell not found")
            }
            c.card = topRatedViewModel.object(forRowAt: indexPath)
            cell = c
            
        case FeaturedSection.topViewed.rawValue:
            guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: TopViewedItemCell.reuseIdentifier,
                                                             for: indexPath) as? TopViewedItemCell else {
                fatalError("TopViewedItemCell not found")
            }
            c.card = topViewedViewModel.object(forRowAt: indexPath)
            cell = c
            
        default:
            ()
        }
        
        if let cell = cell {
            cell.setNeedsLayout()
        }
        return cell!
    }
}

// MARK: UICollectionViewDelegate
extension FeaturedViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var identifier = ""
        var sender: [String: Any]?
        
        switch collectionView.tag {
        case FeaturedSection.topRated.rawValue:
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": indexPath.row/*,
                      "cardMIDs": topRated!*/]
        case FeaturedSection.topViewed.rawValue:
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": indexPath.row/*,
                      "cardMIDs": topViewed!*/]
        case FeaturedSection.latestSets.rawValue:
            let set = latestSetsViewModel.objectAt(indexPath.row)
            identifier = "showSet"
            sender = ["set": set]
            
        default:
            ()
        }
        
        performSegue(withIdentifier: identifier, sender: sender)
    }
}

// MARK: iCarouselDataSource
extension FeaturedViewController : iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
        return latestCardsViewModel.numberOfItems()
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var rcv: HeroCardView?
        
        //reuse view if available, otherwise create a new view
        if let v = view as? HeroCardView {
            rcv = v
        } else {
            if let r = Bundle.main.loadNibNamed("HeroCardView", owner: self, options: nil)?.first as? HeroCardView {
                let height = tableView.frame.size.height / 3
                var width = tableView.frame.size.width
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    width = width / 3
                }
                
                r.frame = CGRect(x: 0, y: 0, width: width, height: height)
                rcv = r
            }
        }
        
        rcv!.card = latestCardsViewModel.objectAt(index)
        rcv!.hideNameAndSet()
        rcv!.showImage()
        return rcv!
    }
}

// MARK: iCarouselDelegate
extension FeaturedViewController : iCarouselDelegate {
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
        let card = latestCardsViewModel.objectAt(index)
        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
        let sender = ["cardIndex": 0,
                      "cardMIDs": [card.objectID]] as [String : Any]
        performSegue(withIdentifier: identifier, sender: sender)
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        var returnValue = CGFloat(0)
        
        switch option {
        case .wrap:
            returnValue = CGFloat(true)
        default:
            returnValue = value
        }
        
        return returnValue
    }
}



