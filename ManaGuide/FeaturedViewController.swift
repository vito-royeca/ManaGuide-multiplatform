//
//  FeaturedViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import FontAwesome_swift
import ManaKit
import MBProgressHUD

let kSliderTableViewCellHeight = CGFloat(140)
let kSliderTableViewCellContentHeight = CGFloat(112)

class FeaturedViewController: BaseViewController {

    // MARK: Variables
    var topViewed: [CMCard]?
    var latestSets: [CMSet]?
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        showTopViewed()
        showLatestSets()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSet" {
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
    func showTopViewed() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        FirebaseManager.sharedInstance.monitorTopViewed(completion: { (cards) in
            MBProgressHUD.hide(for: self.view, animated: true)
            
            let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
            request.predicate = NSPredicate(format: "id in %@", cards.map({ $0.key }))
            request.sortDescriptors = [NSSortDescriptor(key: "views", ascending: false),
                                       NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                       NSSortDescriptor(key: "name", ascending: true)]
            
            if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] {
                self.topViewed = result
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        })
    }

    func showLatestSets() {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMSet")
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = 10

        if let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMSet] {
            DispatchQueue.main.async {
            self.latestSets = result
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
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
        let rows = 2
        
        return rows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        
        switch indexPath.row {
        case 0:
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
                    collectionView.tag = 100
                }
                cell = c
            }
        case 1:
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
                    collectionView.tag = 200
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
        case 0:
            height = kSliderTableViewCellHeight * 2
        case 1:
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
        
        if collectionView.tag == 100 {
            if let topViewed = topViewed {
                count = topViewed.count
            }
        } else if collectionView.tag == 200 {
            if let latestSets = latestSets {
                count = latestSets.count
            }
        }
        
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        if collectionView.tag == 100 {
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
            
        } else if collectionView.tag == 200 {
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
        if collectionView.tag == 200 {
            let set = latestSets![indexPath.row]
            performSegue(withIdentifier: "showSet", sender: set)
        }
    }
}
