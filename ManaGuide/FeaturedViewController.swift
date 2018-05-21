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

enum FeaturedViewControllerSection: Int {
    case latestSets
    case topRated
    case topViewed
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .latestSets: return "Latest Sets"
        case .topRated: return "Top Rated"
        case .topViewed: return "Top Viewed"
        }
    }
    
    static var count: Int {
        return 3
    }
}

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
        showLatestSets()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
                self.showTopRated()
            }
        })
    }
    
    func fetchTopViewed() {
        FirebaseManager.sharedInstance.monitorTopViewed(completion: { (cards) in
            DispatchQueue.main.async {
                self.showTopViewed()
            }
        })
    }
    
    func showTopRated() {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
        request.predicate = NSPredicate(format: "rating > 0")
        request.fetchLimit = Int(kMaxFetchTopRated)
        request.sortDescriptors = [NSSortDescriptor(key: "rating", ascending: false),
                                   NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                   NSSortDescriptor(key: "name", ascending: true)]
        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
            topRated = result
            
            if let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.topRated.rawValue, section: 0)) {
                for v in cell.contentView.subviews {
                    if let collectionView = v as? UICollectionView {
                        collectionView.reloadData()
                        break
                    }
                }
            }
        }
    }
    
    func showTopViewed() {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
        request.predicate = NSPredicate(format: "views > 0")
        request.fetchLimit = Int(kMaxFetchTopViewed)
        request.sortDescriptors = [NSSortDescriptor(key: "views", ascending: false),
                                   NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                   NSSortDescriptor(key: "name", ascending: true)]
        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
            topViewed = result
            
            if let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.topViewed.rawValue, section: 0)) {
                for v in cell.contentView.subviews {
                    if let collectionView = v as? UICollectionView {
                        collectionView.reloadData()
                        break
                    }
                }
            }
        }
    }
    
    func showLatestSets() {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMSet")
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = 10
        
        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMSet] {
            latestSets = result
            
            if let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.latestSets.rawValue, section: 0)) {
                for v in cell.contentView.subviews {
                    if let collectionView = v as? UICollectionView {
                        collectionView.reloadData()
                        break
                    }
                }
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
        return FeaturedViewControllerSection.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        
        switch indexPath.row {
        case FeaturedViewControllerSection.topRated.rawValue:
            if let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") {
                if let titleLabel = c.viewWithTag(100) as? UILabel {
                    titleLabel.text = FeaturedViewControllerSection.topRated.description
                }
                
                if let showAllButton = c.viewWithTag(200) as? UIButton {
                    showAllButton.isHidden = true
                }
                
                var collectionView: UICollectionView?
                for v in c.contentView.subviews {
                    if let cv = v as? UICollectionView {
                        collectionView = cv
                        break
                    }
                }
                
                if let collectionView = collectionView {
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        flowLayout.itemSize = CGSize(width: (collectionView.frame.size.width / 2) - 20, height: (kSliderTableViewCellContentHeight * 2) - 5)
                        flowLayout.scrollDirection = .horizontal
                        flowLayout.minimumInteritemSpacing = CGFloat(5)
                        flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                    }
                    
                    collectionView.dataSource = self
                    collectionView.delegate = self
                    collectionView.tag = FeaturedViewControllerSection.topRated.rawValue
                }
                cell = c
            }
        case FeaturedViewControllerSection.topViewed.rawValue:
            if let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") {
                if let titleLabel = c.viewWithTag(100) as? UILabel {
                    titleLabel.text = FeaturedViewControllerSection.topViewed.description
                }
                
                if let showAllButton = c.viewWithTag(200) as? UIButton {
                    showAllButton.isHidden = true
                }
                
                var collectionView: UICollectionView?
                for v in c.contentView.subviews {
                    if let cv = v as? UICollectionView {
                        collectionView = cv
                        break
                    }
                }
                
                if let collectionView = collectionView {
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        flowLayout.itemSize = CGSize(width: (collectionView.frame.size.width / 2) - 20, height: (kSliderTableViewCellContentHeight * 2) - 5)
                        flowLayout.scrollDirection = .horizontal
                        flowLayout.minimumInteritemSpacing = CGFloat(5)
                        flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                    }
                    
                    collectionView.dataSource = self
                    collectionView.delegate = self
                    collectionView.tag = FeaturedViewControllerSection.topViewed.rawValue
                }
                cell = c
            }
        case FeaturedViewControllerSection.latestSets.rawValue:
            if let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") {
                if let titleLabel = c.viewWithTag(100) as? UILabel {
                    titleLabel.text = FeaturedViewControllerSection.latestSets.description
                }
                
                if let showAllButton = c.viewWithTag(200) as? UIButton {
                    showAllButton.addTarget(self, action: #selector(self.showAllSets(_:)), for: .touchUpInside)
                }
                
                var collectionView: UICollectionView?
                for v in c.contentView.subviews {
                    if let cv = v as? UICollectionView {
                        collectionView = cv
                        break
                    }
                }
                
                if let collectionView = collectionView {
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        flowLayout.itemSize = CGSize(width: (collectionView.frame.size.width / 3) - 20, height: kSliderTableViewCellContentHeight - 5)
                        flowLayout.scrollDirection = .horizontal
                        flowLayout.minimumInteritemSpacing = CGFloat(5)
                        flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 0)
                    }
                    
                    collectionView.dataSource = self
                    collectionView.delegate = self
                    collectionView.tag = FeaturedViewControllerSection.latestSets.rawValue
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
        case FeaturedViewControllerSection.topRated.rawValue,
             FeaturedViewControllerSection.topViewed.rawValue:
            height = kSliderTableViewCellHeight * 2
        case FeaturedViewControllerSection.latestSets.rawValue:
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
        
        switch collectionView.tag {
        case FeaturedViewControllerSection.topRated.rawValue:
            if let topRated = topRated {
                count = topRated.count
            }
        case FeaturedViewControllerSection.topViewed.rawValue:
            if let topViewed = topViewed {
                count = topViewed.count
            }
        case FeaturedViewControllerSection.latestSets.rawValue:
            if let latestSets = latestSets {
                count = latestSets.count
            }
        default:
            ()
        }
        
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        switch collectionView.tag {
        case FeaturedViewControllerSection.topRated.rawValue:
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
            
        case FeaturedViewControllerSection.topViewed.rawValue:
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
            
        case FeaturedViewControllerSection.latestSets.rawValue:
            let set = latestSets![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SetItemCell", for: indexPath)
            if let label = cell?.viewWithTag(100) as? UILabel {
                label.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            }
            if let label = cell?.viewWithTag(200) as? UILabel {
                label.text = set.name
            }
            
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
        var sender: Any?
        
        switch collectionView.tag {
        case FeaturedViewControllerSection.topRated.rawValue:
            let card = topRated![indexPath.row]
            let cardIndex = 0
            
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": cardIndex as Any,
                      "cards": [card]]
        case FeaturedViewControllerSection.topViewed.rawValue:
            let card = topViewed![indexPath.row]
            let cardIndex = 0
            
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": cardIndex as Any,
                      "cards": [card]]
        case FeaturedViewControllerSection.latestSets.rawValue:
            let set = latestSets![indexPath.row]
            identifier = "showSet"
            sender = set
            
        default:
            ()
        }
        
        performSegue(withIdentifier: identifier, sender: sender)
    }
}
