//
//  FeaturedViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import ManaKit
import MBProgressHUD
import PromiseKit

class FeaturedViewController: BaseViewController {

    // MARK: Variables
    let latestSetsViewModel  = LatestSetsViewModel()
    let topRatedViewModel    = TopRatedViewModel()
    let topViewedViewModel   = TopViewedViewModel()
    
    var flowLayoutHeight = CGFloat(0)
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedSection.latestCards.rawValue, section: 0)) as? LatestCardsTableViewCell else {
            return
        }
        
        cell.startSlideShow()
        topRatedViewModel.fetchData()
        topViewedViewModel.fetchData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedSection.latestCards.rawValue, section: 0)) as? LatestCardsTableViewCell else {
            return
        }
        
        cell.stopSlideShow()
        topRatedViewModel.stopMonitoring()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        flowLayoutHeight = (view.frame.size.height / 3) - 50
        tableView.reloadData()
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedSection.latestCards.rawValue, section: 0)) as? LatestCardsTableViewCell else {
            return
        }
        cell.carousel.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String] else {
                return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withCardIDs: cardIDs,
                                           withSortDescriptors: dict["sortDescriptors"] as? [NSSortDescriptor])
            
        } else if segue.identifier == "showCardModal" {
            guard let nav = segue.destination as? UINavigationController,
                let dest = nav.childViewControllers.first as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String] else {
                return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withCardIDs: cardIDs,
                                           withSortDescriptors: dict["sortDescriptors"] as? [NSSortDescriptor])
            
        } else if segue.identifier == "showSet" {
            guard let dest = segue.destination as? SetViewController,
                let dict = sender as? [String: Any],
                let set = dict["set"] as? CMSet else {
                return
            }
            
            dest.viewModel = SetViewModel(withSet: set)

        } else if segue.identifier == "showSets" {
            guard let dest = segue.destination as? SetsViewController else {
                return
            }
            
            dest.title = "Sets"
        }
    }

    // MARK: Custom methods
    @objc func reloadTopRated(_ notification: Notification) {
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
    
    @objc func reloadTopViewed(_ notification: Notification) {
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

    @objc func showAllSets(_ sender: UIButton) {
        performSegue(withIdentifier: "showSets", sender: nil)
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
            guard let c = tableView.dequeueReusableCell(withIdentifier: LatestCardsTableViewCell.reuseIdentifier, for: indexPath) as? LatestCardsTableViewCell else {
                fatalError("LatestCardsTableViewCell not found")
            }
            c.delegate = self
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
                    flowLayout.sectionInset = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 0)
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
                    flowLayout.sectionInset = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 0)
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
                    flowLayout.sectionInset = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 0)
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
            count = latestSetsViewModel.numberOfRows(inSection: section)
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
            c.set = latestSetsViewModel.object(forRowAt: indexPath)
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
        var cardIDs = [String]()
        
        switch collectionView.tag {
        case FeaturedSection.latestSets.rawValue:
            let set = latestSetsViewModel.object(forRowAt: indexPath)
            identifier = "showSet"
            sender = ["set": set]
        case FeaturedSection.topRated.rawValue:
            for i in 0...topRatedViewModel.numberOfRows(inSection: 0) - 1 {
                cardIDs.append(topRatedViewModel.object(forRowAt: IndexPath(row: i, section: 0)).id!)
            }
            
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": indexPath.row,
                      "cardIDs": cardIDs,
                      "sortDescriptors": topRatedViewModel.sortDescriptors]
            
        case FeaturedSection.topViewed.rawValue:
            for i in 0...topViewedViewModel.numberOfRows(inSection: 0) - 1 {
                cardIDs.append(topViewedViewModel.object(forRowAt: IndexPath(row: i, section: 0)).id!)
            }
            
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": indexPath.row,
                      "cardIDs": cardIDs,
                      "sortDescriptors": topViewedViewModel.sortDescriptors]
        default:
            ()
        }
        
        performSegue(withIdentifier: identifier, sender: sender)
    }
}

// MARK: LatestCardsTableViewDelegate
extension FeaturedViewController : LatestCardsTableViewDelegate {
    func cardSelected(card: CMCard) {
        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
        let sender = ["cardIndex": 0,
                      "cardIDs": [card.id]] as [String : Any]
        performSegue(withIdentifier: identifier, sender: sender)
    }
}

