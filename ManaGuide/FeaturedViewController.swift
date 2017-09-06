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
import FontAwesome_swift
import ManaKit
import MBProgressHUD

let kSliderTableViewCellHeight = CGFloat(140)
let kSliderTableViewCellContentHeight = CGFloat(112)
let kFeaturedTopRatedTag  = 100
let kFeaturedTopViewedTag = 200
let kFeaturedAllSetsTag   = 300

class FeaturedViewController: BaseViewController {

    // MARK: Variables
    var topRated: [CMCard]?
    var topViewed: [CMCard]?
    var latestSets: [CMSet]?
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kNotificationCardViewsUpdated), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTopCharts), name: NSNotification.Name(rawValue: kNotificationCardViewsUpdated), object: nil)
        
        fetchTopCharts()
        fetchLatestSets()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateTopCharts()
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
    func fetchTopCharts() {
        FirebaseManager.sharedInstance.monitorTopRated(completion: { (cards) in
            FirebaseManager.sharedInstance.monitorTopViewed(completion: { (cards) in
                self.updateTopCharts()
            })
        })
    }
    
    func updateTopCharts() {
        var request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
        request.predicate = NSPredicate(format: "rating > 0")
        request.fetchLimit = Int(kMaxFetchTopRated)
        request.sortDescriptors = [NSSortDescriptor(key: "rating", ascending: false),
                                   NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                   NSSortDescriptor(key: "name", ascending: true)]
        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
            topRated = result
        }
        
        request = NSFetchRequest(entityName: "CMCard")
        request.predicate = NSPredicate(format: "views > 0")
        request.fetchLimit = Int(kMaxFetchTopViewed)
        request.sortDescriptors = [NSSortDescriptor(key: "views", ascending: false),
                                   NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                   NSSortDescriptor(key: "name", ascending: true)]
        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
            topViewed = result
        }

        tableView.reloadData()
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
            tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
    }

    func fetchLatestSets() {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMSet")
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = 10

        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMSet] {
            latestSets = result
            tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
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
                    collectionView.tag = kFeaturedTopRatedTag
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
                    collectionView.tag = kFeaturedTopViewedTag
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
                    collectionView.tag = kFeaturedAllSetsTag
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
        
        if collectionView.tag == kFeaturedTopRatedTag {
            if let topRated = topRated {
                count = topRated.count
            }
        } else if collectionView.tag == kFeaturedTopViewedTag {
            if let topViewed = topViewed {
                count = topViewed.count
            }
        } else if collectionView.tag == kFeaturedAllSetsTag {
            if let latestSets = latestSets {
                count = latestSets.count
            }
        }
        
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        if collectionView.tag == kFeaturedTopRatedTag {
            let card = topRated![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopRatedItemCell", for: indexPath)
            if let thumbnailImage = cell?.viewWithTag(100) as? UIImageView {
                thumbnailImage.layer.cornerRadius = thumbnailImage.frame.height / 6
                thumbnailImage.layer.masksToBounds = true
                
                if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                    thumbnailImage.image = croppedImage
                } else {
                    thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                    ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                        if error == nil {
                            if self.topViewed![indexPath.row] == c {
                                UIView.transition(with: thumbnailImage,
                                                  duration: 1.0,
                                                  options: .transitionCrossDissolve,
                                                  animations: {
                                                    thumbnailImage.image = croppedImage
                                },
                                                  completion: nil)
                            }
                        }
                    })
                }
            }
            if let setImage = cell?.viewWithTag(200) as? UIImageView,
                let rarity = card.rarity_,
                let set = card.set {
                setImage.image = ManaKit.sharedInstance.setImage(set: set, rarity: rarity)
            }
            if let nameLabel = cell?.viewWithTag(300) as? UILabel {
                nameLabel.adjustsFontSizeToFitWidth = true
                nameLabel.text = card.name
            }
            if let ratingView = cell?.viewWithTag(400) as? CosmosView {
                ratingView.rating = card.rating
                ratingView.settings.fillMode = .precise
            }
            
        } else if collectionView.tag == kFeaturedTopViewedTag {
            let card = topViewed![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopViewedItemCell", for: indexPath)
            if let thumbnailImage = cell?.viewWithTag(100) as? UIImageView {
                thumbnailImage.layer.cornerRadius = thumbnailImage.frame.height / 6
                thumbnailImage.layer.masksToBounds = true
                
                if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                    thumbnailImage.image = croppedImage
                } else {
                    thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                    ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                        if error == nil {
                            if self.topViewed![indexPath.row] == c {
                                UIView.transition(with: thumbnailImage,
                                                  duration: 1.0,
                                                  options: .transitionCrossDissolve,
                                                  animations: {
                                                    thumbnailImage.image = croppedImage
                                },
                                                  completion: nil)
                            }
                        }
                    })
                }
            }
            if let setImage = cell?.viewWithTag(200) as? UIImageView,
                let rarity = card.rarity_,
                let set = card.set {
                setImage.image = ManaKit.sharedInstance.setImage(set: set, rarity: rarity)
            }
            if let nameLabel = cell?.viewWithTag(300) as? UILabel {
                nameLabel.adjustsFontSizeToFitWidth = true
                nameLabel.text = card.name
            }
            if let viewedImage = cell?.viewWithTag(400) as? UIImageView {
                let image = UIImage.fontAwesomeIcon(name: .eye, textColor: UIColor.black, size: CGSize(width: 20, height: 20))
                viewedImage.image = image
            }
            if let viewsLabel = cell?.viewWithTag(500) as? UILabel {
                viewsLabel.text = "\(card.views)"
            }
            
        } else if collectionView.tag == kFeaturedAllSetsTag {
            let set = latestSets![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SetItemCell", for: indexPath)
            if let iconView = cell?.viewWithTag(100) as? UIImageView {
                iconView.image = ManaKit.sharedInstance.setImage(set: set, rarity: nil)
            }
            if let nameLabel = cell?.viewWithTag(200) as? UILabel {
                nameLabel.adjustsFontSizeToFitWidth = true
                nameLabel.text = set.name
            }
        }
        
        return cell!
    }
}

// MARK: UICollectionViewDelegate
extension FeaturedViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == kFeaturedTopRatedTag {
            let card = topRated![indexPath.row]
            let cardIndex = 0
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                performSegue(withIdentifier: "showCard", sender: ["cardIndex": cardIndex as Any,
                                                                  "cards": [card]])
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                performSegue(withIdentifier: "showCardModal", sender: ["cardIndex": cardIndex as Any,
                                                                       "cards": [card]])
            }
        } else if collectionView.tag == kFeaturedTopViewedTag {
            let card = topViewed![indexPath.row]
            let cardIndex = 0
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                performSegue(withIdentifier: "showCard", sender: ["cardIndex": cardIndex as Any,
                                                                  "cards": [card]])
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                performSegue(withIdentifier: "showCardModal", sender: ["cardIndex": cardIndex as Any,
                                                                       "cards": [card]])
            }
        } else if collectionView.tag == kFeaturedAllSetsTag {
            let set = latestSets![indexPath.row]
            performSegue(withIdentifier: "showSet", sender: set)
        }
    }
}
