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
        latestSetsViewModel.mode = .loading
        topRatedViewModel.mode = .loading
        topViewedViewModel.mode = .loading
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let cell = tableView.cellForRow(at: IndexPath(row: FeaturedSection.latestCards.rawValue,
                                                         section: 0)) as? LatestCardsTableViewCell {
            cell.startSlideShow()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let cell = tableView.cellForRow(at: IndexPath(row: FeaturedSection.latestCards.rawValue,
                                                         section: 0)) as? LatestCardsTableViewCell {
            cell.stopSlideShow()
        }
        topRatedViewModel.stopMonitoring()
        topViewedViewModel.stopMonitoring()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        flowLayoutHeight = (view.frame.size.height / 3) - 50
        tableView.reloadData()
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedSection.latestCards.rawValue,
                                                            section: 0)) as? LatestCardsTableViewCell else {
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
                let dest = nav.children.first as? CardViewController,
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
                let set = sender as? CMSet else {
                return
            }
            
            dest.viewModel = SetViewModel(withSet: set, languageCode: "en")

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
        var width = self.flowLayoutHeight + (self.flowLayoutHeight / 2)
        var itemSize = CGSize(width: width - 20, height: flowLayoutHeight - 5)
        
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
            guard let c = tableView.dequeueReusableCell(withIdentifier: FeaturedTableViewCell.reuseIdentifier,
                                                        for: indexPath) as? FeaturedTableViewCell else {
                fatalError("\(FeaturedTableViewCell.reuseIdentifier) not found")
            }

            c.setupCollectionView(itemSize: itemSize)
            c.titleLabel.text = FeaturedSection.latestSets.description
            c.section = .latestSets
            c.viewModel = latestSetsViewModel
            c.delegate = self
            
            if latestSetsViewModel.mode == .loading {
                firstly {
                    latestSetsViewModel.fetchData()
                }.done {
                    let divisor = CGFloat(UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4)
                    width = (self.view.frame.size.width / divisor) - 20
                    itemSize = CGSize(width: width - 20, height: self.flowLayoutHeight - 5)
                    
                    self.latestSetsViewModel.mode = self.latestSetsViewModel.isEmpty() ? .noResultsFound : .resultsFound
                    c.setupCollectionView(itemSize: itemSize)
                    c.collectionView.reloadData()
                }.catch { error in
                    self.topRatedViewModel.mode = .error
                    c.collectionView.reloadData()
                }
            }
            cell = c
            
        case FeaturedSection.topRated.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: FeaturedTableViewCell.reuseIdentifier,
                                                        for: indexPath) as? FeaturedTableViewCell else {
                fatalError("\(FeaturedTableViewCell.reuseIdentifier) not found")
            }
            
            c.setupCollectionView(itemSize: itemSize)
            c.titleLabel.text = FeaturedSection.topRated.description
            c.seeAllButton.isHidden = true
            c.section = .topRated
            c.viewModel = topRatedViewModel
            c.delegate = self
            if topRatedViewModel.mode == .loading {
                firstly {
                    when(fulfilled: [topRatedViewModel.fetchRemoteData(),
                                     topRatedViewModel.fetchData()])
                }.done {
                    self.topRatedViewModel.mode = self.topRatedViewModel.isEmpty() ? .noResultsFound : .resultsFound
                    c.collectionView.reloadData()
                }.catch { error in
                    self.topRatedViewModel.mode = .error
                    c.collectionView.reloadData()
                }
            }
            
            cell = c
            
        case FeaturedSection.topViewed.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: FeaturedTableViewCell.reuseIdentifier,
                                                        for: indexPath) as? FeaturedTableViewCell else {
                                                            fatalError("\(FeaturedTableViewCell.reuseIdentifier) not found")
            }
            
            c.setupCollectionView(itemSize: itemSize)
            c.titleLabel.text = FeaturedSection.topViewed.description
            c.seeAllButton.isHidden = true
            c.section = .topViewed
            c.viewModel = topViewedViewModel
            c.delegate = self
            if topViewedViewModel.mode == .loading {
                firstly {
                    when(fulfilled: [topViewedViewModel.fetchRemoteData(),
                                     topViewedViewModel.fetchData()])
                }.done {
                    self.topViewedViewModel.mode = self.topViewedViewModel.isEmpty() ? .noResultsFound : .resultsFound
                    c.collectionView.reloadData()
                }.catch { error in
                    self.topViewedViewModel.mode = .error
                    c.collectionView.reloadData()
                }
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
            height = UITableView.automaticDimension
        }
        
        return height
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

// MARK: FeaturedTableViewCellDelegate
extension FeaturedViewController: FeaturedTableViewCellDelegate {
    func showItem(section: FeaturedSection, index: Int, objects: [NSManagedObject], sorters: [NSSortDescriptor]?) {
        switch section {
        case .latestCards:
            ()
        case .latestSets:
            performSegue(withIdentifier: "showSet", sender: objects[0])
        case .topRated,
             .topViewed:
            let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            var sender = ["cardIndex": index] as [String : Any]
            var cardIDs = [String]()
            
            for mo in objects {
                if let card = mo as? CMCard {
                    cardIDs.append(card.id!)
                }
            }
            sender["cardIDs"] = cardIDs
            if let sorters = sorters {
                sender["sortDescriptors"] = sorters
            }
            performSegue(withIdentifier: identifier, sender: sender)
        }
    }
    
    func seeAllItems(section: FeaturedSection) {
        switch section {
        case .latestCards:
            ()
        case .latestSets:
            performSegue(withIdentifier: "showSets", sender: nil)
        case .topRated,
             .topViewed:
            ()
        }
    }
}
