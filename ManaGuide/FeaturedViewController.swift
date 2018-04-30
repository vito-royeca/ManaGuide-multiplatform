//
//  FeaturedViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import Cosmos
import DATASource
import Font_Awesome_Swift
import ManaKit
import MBProgressHUD

let kSliderTableViewCellHeight = CGFloat(140)
let kSliderTableViewCellContentHeight = CGFloat(112)
//let kFeaturedTopRatedTag  = 100
//let kFeaturedTopViewedTag = 200
//let kFeaturedAllSetsTag   = 300

class FeaturedViewController: BaseViewController {

    // MARK: Variables
    var topRated: [CMCard]?
    var topViewed: [CMCard]?
    var latestSets: [CMSet]?
    var topRatedCollectionView: UICollectionView?
    var topViewedCollectionView: UICollectionView?
    var latestSetsCollectionView: UICollectionView?
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateLatestSets()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTopRated()
        fetchTopViewed()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        FirebaseManager.sharedInstance.demonitorTopCharts()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            if let dest = segue.destination as? CardViewController,
                let dict = sender as? [String: Any] {
                dest.cardIndex = dict["cardIndex"] as! Int
                dest.cards = dict["cards"] as? [CMCard]
            }
        } else if segue.identifier == "showCardModal" {
            if let nav = segue.destination as? UINavigationController {
                if let dest = nav.childViewControllers.first as? CardViewController,
                    let dict = sender as? [String: Any] {
                    dest.cardIndex = dict["cardIndex"] as! Int
                    dest.cards = dict["cards"] as? [CMCard]
                    dest.title = dest.cards?[dest.cardIndex].name
                }
            }
        } else if segue.identifier == "showSet" {
            if let dest = segue.destination as? SetViewController,
                let set = sender as? CMSet {
                
                dest.title = set.name
                dest.set = set
            }
        } else if segue.identifier == "showSets" {
            if let dest = segue.destination as? SetsViewController {
                dest.title = "Sets"
            }
        }
    }

    // MARK: Custom methods
    func fetchTopRated() {
        FirebaseManager.sharedInstance.monitorTopRated(completion: { (cards) in
            DispatchQueue.main.async {
                self.updateTopRated()
            }
        })
    }
    
    func fetchTopViewed() {
        FirebaseManager.sharedInstance.monitorTopViewed(completion: { (cards) in
            DispatchQueue.main.async {
                self.updateTopViewed()
            }
        })
    }
    
    func updateTopRated() {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
        request.predicate = NSPredicate(format: "rating > 0")
        request.fetchLimit = Int(kMaxFetchTopRated)
        request.sortDescriptors = [NSSortDescriptor(key: "rating", ascending: false),
                                   NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                   NSSortDescriptor(key: "name", ascending: true)]
        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
            topRated = result
            if let topRatedCollectionView = topRatedCollectionView {
                topRatedCollectionView.reloadData()
            }
        }
    }
    
    func updateTopViewed() {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
        request.predicate = NSPredicate(format: "views > 0")
        request.fetchLimit = Int(kMaxFetchTopViewed)
        request.sortDescriptors = [NSSortDescriptor(key: "views", ascending: false),
                                   NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                   NSSortDescriptor(key: "name", ascending: true)]
        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
            topViewed = result
            if let topViewedCollectionView = topViewedCollectionView {
                topViewedCollectionView.reloadData()
            }
        }
    }
    
    func updateLatestSets() {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMSet")
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = 10
        
        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMSet] {
            latestSets = result
            if let latestSetsCollectionView = latestSetsCollectionView {
                latestSetsCollectionView.reloadData()
            }
        }
    }

    func showAllSets(_ sender: UIButton) {
        performSegue(withIdentifier: "showSets", sender: nil)
    }
}

// MARK: UITableViewDataSource
extension FeaturedViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = 3
        
        return rows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        
        switch indexPath.row {
        case 0:
            if let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") {
                if let titleLabel = c.viewWithTag(100) as? UILabel {
                    titleLabel.text = "Top Rated"
                }
                
                if let showAllButton = c.viewWithTag(200) as? UIButton {
                    showAllButton.isHidden = true
                }
                
                if let collectionView = c.viewWithTag(300) as? UICollectionView {
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        flowLayout.itemSize = CGSize(width: (collectionView.frame.size.width / 2) - 20, height: (kSliderTableViewCellContentHeight * 2) - 5)
                        flowLayout.scrollDirection = .horizontal
                        flowLayout.minimumInteritemSpacing = CGFloat(5)
                        flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                    }
                    
                    collectionView.dataSource = self
                    collectionView.delegate = self
                    topRatedCollectionView = collectionView
                }
                cell = c
            }
        case 1:
            if let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") {
                if let titleLabel = c.viewWithTag(100) as? UILabel {
                    titleLabel.text = "Top Viewed"
                }
                
                if let showAllButton = c.viewWithTag(200) as? UIButton {
                    showAllButton.isHidden = true
                }
                
                if let collectionView = c.viewWithTag(300) as? UICollectionView {
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        flowLayout.itemSize = CGSize(width: (collectionView.frame.size.width / 2) - 20, height: (kSliderTableViewCellContentHeight * 2) - 5)
                        flowLayout.scrollDirection = .horizontal
                        flowLayout.minimumInteritemSpacing = CGFloat(5)
                        flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                    }
                    
                    collectionView.dataSource = self
                    collectionView.delegate = self
                    topViewedCollectionView = collectionView
                }
                cell = c
            }
        case 2:
            if let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") {
                if let titleLabel = c.viewWithTag(100) as? UILabel {
                    titleLabel.text = "Latest Sets"
                }
                
                if let showAllButton = c.viewWithTag(200) as? UIButton {
                    showAllButton.addTarget(self, action: #selector(self.showAllSets(_:)), for: .touchUpInside)
                }
                
                if let collectionView = c.viewWithTag(300) as? UICollectionView {
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        flowLayout.itemSize = CGSize(width: (collectionView.frame.size.width / 3) - 20, height: kSliderTableViewCellContentHeight - 5)
                        flowLayout.scrollDirection = .horizontal
                        flowLayout.minimumInteritemSpacing = CGFloat(5)
                        flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                    }
                    
                    collectionView.dataSource = self
                    collectionView.delegate = self
                    latestSetsCollectionView = collectionView
                }
                
                cell = c
            }
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
        case 0, 1:
            height = kSliderTableViewCellHeight * 2
        case 2:
            height = kSliderTableViewCellHeight
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
        
        if collectionView == topRatedCollectionView {
            if let topRated = topRated {
                count = topRated.count
            }
        } else if collectionView == topViewedCollectionView {
            if let topViewed = topViewed {
                count = topViewed.count
            }
        } else if collectionView == latestSetsCollectionView {
            if let latestSets = latestSets {
                count = latestSets.count
            }
        }
        
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        if collectionView == topRatedCollectionView {
            let card = topRated![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopRatedItemCell", for: indexPath)
            if let thumbnailImage = cell?.viewWithTag(100) as? UIImageView {
                thumbnailImage.layer.cornerRadius = 10
                
                if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                    UIView.transition(with: thumbnailImage,
                                      duration: 1.0,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        thumbnailImage.image = croppedImage
                                      },
                                      completion: nil)
                    
                } else {
                    thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                    ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: Error?) in
                        if error == nil {
                            collectionView.reloadItems(at: [IndexPath(item: indexPath.row, section: 0)])
                        }
                    })
                }
            }
            if let setImage = cell?.viewWithTag(200) as? UIImageView,
                let rarity = card.rarity_,
                let set = card.set {
                setImage.image = ManaKit.sharedInstance.setImage(set: set, rarity: rarity)
            }
            if let label = cell?.viewWithTag(300) as? UILabel {
                label.text = card.name
            }
            if let ratingView = cell?.viewWithTag(400) as? CosmosView {
                ratingView.rating = card.rating
                ratingView.settings.fillMode = .precise
            }
            
        } else if collectionView == topViewedCollectionView {
            let card = topViewed![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopViewedItemCell", for: indexPath)
            if let thumbnailImage = cell?.viewWithTag(100) as? UIImageView {
                thumbnailImage.layer.cornerRadius = 10
                
                if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                    UIView.transition(with: thumbnailImage,
                                      duration: 1.0,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        thumbnailImage.image = croppedImage
                                      },
                                      completion: nil)
                } else {
                    thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                    ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: Error?) in
                        if error == nil {
                            collectionView.reloadItems(at: [IndexPath(item: indexPath.row, section: 0)])
                        }
                    })
                }
            }
            if let label = cell?.viewWithTag(200) as? UILabel,
                let rarity = card.rarity_,
                let set = card.set {
                label.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
                label.textColor = ManaKit.sharedInstance.keyruneColor(forRarity: rarity)
                label.layer.cornerRadius = label.frame.height / 2
            }
            if let label = cell?.viewWithTag(300) as? UILabel {
                label.text = card.name
            }
            if let label = cell?.viewWithTag(400) as? UILabel {
                label.FAIcon = .FAEye
            }
            if let label = cell?.viewWithTag(500) as? UILabel {
                label.text = "\(card.views)"
            }
            
        } else if collectionView == latestSetsCollectionView {
            let set = latestSets![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SetItemCell", for: indexPath)
            if let label = cell?.viewWithTag(100) as? UILabel {
                label.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            }
            if let label = cell?.viewWithTag(200) as? UILabel {
                label.text = set.name
            }
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
        var sender: Any?
        
        if collectionView == topRatedCollectionView {
            let card = topRated![indexPath.row]
            let cardIndex = 0
            
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": cardIndex as Any,
                      "cards": [card]]
        } else if collectionView == topViewedCollectionView {
            let card = topViewed![indexPath.row]
            let cardIndex = 0
            
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": cardIndex as Any,
                      "cards": [card]]
        } else if collectionView == latestSetsCollectionView {
            let set = latestSets![indexPath.row]
            identifier = "showSet"
            sender = set
        }
        
        performSegue(withIdentifier: identifier, sender: sender)
    }
}
