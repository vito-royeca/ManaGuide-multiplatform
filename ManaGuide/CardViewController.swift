//
//  CardViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 27/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import FontAwesome_swift
import ManaKit

let kNotificationSwipedToCard = "kNotificationSwipedToCard"

enum CardViewControllerSegmentedIndex: Int {
    case card, details, pricing
}

class CardViewController: BaseViewController {
    // MARK: Variables
    var cardIndex = 0
    var cards: [CMCard]?
    var variations: [CMCard]?
    var printings: [CMCard]?
    var cardsCollectionView: UICollectionView?
    var variationsCollectionView: UICollectionView?
    var printingsCollectionView: UICollectionView?
    var segmentedIndex: CardViewControllerSegmentedIndex = .card

    // MARK: Constants
    let detailsSections = ["Text", "Rulings", "Legalities", "Artist", "Card Number", "Types", "Subtypes", "Supertypes", "Variations", "Printings"]
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    // MARK: Actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Card")
    }
    
    @IBAction func segmentedAction(_ sender: UISegmentedControl) {
        segmentedIndex = CardViewControllerSegmentedIndex(rawValue: sender.selectedSegmentIndex)!
        tableView.reloadData()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .gear, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        rightMenuButton.title = nil
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kNotificationCardImageDownloaded), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showCardImage(_:)), name: NSNotification.Name(rawValue: kNotificationCardImageDownloaded), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let cardsCollectionView = cardsCollectionView {
            cardsCollectionView.scrollToItem(at: IndexPath(item: cardIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            if let dest = segue.destination as? CardViewController,
                let cell = sender as? UICollectionViewCell {
                
                var parentView = cell.superview
                while parentView is UICollectionView != true {
                    parentView = parentView?.superview
                }
                
                if let parentView = parentView {
                    if let variationsCollectionView = variationsCollectionView,
                        let variations = variations {
                        if parentView == variationsCollectionView {
                            dest.cards = [variations[variationsCollectionView.indexPath(for: cell)!.item]]
                        }
                    }
                    
                    if let printingsCollectionView = printingsCollectionView,
                        let printings = printings {
                        if parentView == printingsCollectionView {
                            dest.cards = [printings[printingsCollectionView.indexPath(for: cell)!.item]]
                        }
                    }
                }
                
                dest.cardIndex = 0
                
                dest.title = ""
            }
        }
    }
    
    // MARK: Custom methods
    func showCardImage(_ notification: Notification) {
        if let cardsCollectionView = cardsCollectionView,
            let cards = cards,
            let userInfo = notification.userInfo {
            
            if  let dCard = userInfo["card"] as? CMCard {
                if dCard == cards[cardIndex] {
                    let indexPath = IndexPath(item: cardIndex, section: 0)
                    cardsCollectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }

}

// MARK: UITableViewDataSource
extension CardViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        
        switch segmentedIndex {
        case .card:
            rows = 3
        case .details:
            switch section {
            case 0:
                rows = 2
            case 9, 10:
                rows = 1
            default:
                rows = 0
            }
        case .pricing:
            rows = 2
        }
        
        return rows
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var rows = 0
        
        switch segmentedIndex {
        case .card:
            rows = 1
        case .details:
            rows = 11
        case .pricing:
            rows = 1
        }
        
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        switch segmentedIndex {
        case .card:
            switch indexPath.row {
            case 0:
                if let c = tableView.dequeueReusableCell(withIdentifier: "CardCell") as? CardTableViewCell,
                    let cards = cards {
                    c.card = cards[cardIndex]
                    c.updateDataDisplay()
                    cell = c
                }
            case 1:
                if let c = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell") {
                    cell = c
                }
            case 2:
                if let c = tableView.dequeueReusableCell(withIdentifier: "CardsCell") {
                    if let collectionView = c.viewWithTag(100) as? UICollectionView {
                        cardsCollectionView = collectionView
                        
                        if let bgImage = ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.grayPatterned) {
                            collectionView.backgroundColor = UIColor(patternImage: bgImage)
                        }
                        
                        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                            let width = tableView.frame.size.width - 80
                            let height = tableView.frame.size.height - kCardTableViewCellHeight - CGFloat(44) - 40
                            flowLayout.itemSize = CGSize(width: width, height: height)
                            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
                        }
                        
                        collectionView.dataSource = self
                        collectionView.delegate = self
                    }
                    cell = c
                }
            default:
                ()
            }
        
        case .details:
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    if let c = tableView.dequeueReusableCell(withIdentifier: "CardCell") as? CardTableViewCell,
                        let cards = cards {
                        c.card = cards[cardIndex]
                        c.updateDataDisplay()
                        cell = c
                    }
                case 1:
                    if let c = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell") {
                        cell = c
                    }
                default:
                    ()
                }
            case 9,10:
                if let c = tableView.dequeueReusableCell(withIdentifier: "ThumbnailsCell") {
                    if let collectionView = c.viewWithTag(100) as? UICollectionView {
                        if let bgImage = ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.grayPatterned) {
                            collectionView.backgroundColor = UIColor(patternImage: bgImage)
                        }
                        
                        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                            let width = CGFloat(100)
                            let height = CGFloat(72)
                            flowLayout.itemSize = CGSize(width: width, height: height)
                            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                        }
                        
                        collectionView.dataSource = self
                        collectionView.delegate = self
                        
                        if indexPath.section == 9 {
                            variationsCollectionView = collectionView
                        } else if indexPath.section == 10 {
                            printingsCollectionView = collectionView
                        }
                    }
                    
                    cell = c
                }
            default:
                ()
            }
        
        case .pricing:
            switch indexPath.row {
            case 0:
                if let c = tableView.dequeueReusableCell(withIdentifier: "CardCell") as? CardTableViewCell,
                    let cards = cards {
                    c.card = cards[cardIndex]
                    c.updateDataDisplay()
                    cell = c
                }
            case 1:
                if let c = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell") {
                    cell = c
                }
            default:
                ()
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var headerTitle: String?
        
        switch segmentedIndex {
        case .details:
            switch section {
            case 0:
                ()
            default:
                headerTitle = detailsSections[section - 1]
            }
        default:
            ()
        }
        
        return headerTitle
    }
}

// MARK: UITableViewDelegate
extension CardViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)
        
        switch segmentedIndex {
        case .card:
            switch indexPath.row {
            case 0:
                height = kCardTableViewCellHeight
            case 1:
                height = CGFloat(44)
            case 2:
                height = tableView.frame.size.height - kCardTableViewCellHeight - CGFloat(44)
            default:
                ()
            }
            
        case .details:
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    height = kCardTableViewCellHeight
                case 1:
                    height = CGFloat(44)
                default:
                    ()
                }
            case 9,10:
                height = CGFloat(88)
            default:
                ()
            }
            
        case .pricing:
            switch indexPath.row {
            case 0:
                height = kCardTableViewCellHeight
            case 1:
                height = CGFloat(44)
            default:
                ()
            }
        }
        
        return height
    }
}

// MARK: UICollectionViewDataSource
extension CardViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var items = 0
        
        switch segmentedIndex {
        case .card:
            if let cards = cards {
                items = cards.count
            }
            
        case .details:
            if collectionView == variationsCollectionView {
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let variations_ = card.variations_ {
                        items = variations_.allObjects.count
                    }
                }
            } else if collectionView == printingsCollectionView {
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let printings_ = card.printings_ {
                        items = printings_.allObjects.count
                    }
                }
            }
            
        case .pricing:
            ()
        }

        return items
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell:UICollectionViewCell?
        
        switch segmentedIndex {
        case .card:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardItemCell", for: indexPath)
            
            if let imageView = cell!.viewWithTag(100) as? UIImageView,
                let cards = cards {
                let card = cards[indexPath.row]
                
                imageView.image = ManaKit.sharedInstance.cardImage(card)
            }
            
        case .details:
            if collectionView == variationsCollectionView {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailItemCell", for: indexPath)
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let variations_ = card.variations_,
                        let thumbnailImage = cell!.viewWithTag(100) as? UIImageView,
                        let setImage = cell!.viewWithTag(200) as? UIImageView {
                        
                        thumbnailImage.layer.cornerRadius = thumbnailImage.frame.height / 6
                        thumbnailImage.layer.masksToBounds = true
                        
                        variations = variations_.allObjects as? [CMCard]
                        let v = variations![indexPath.row]
                        if let croppedImage = ManaKit.sharedInstance.croppedImage(v) {
                            thumbnailImage.image = croppedImage
                        } else {
                            thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cropBack)
                            ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                                if error == nil {
                                    if v == c {
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
                        
                        setImage.image = ManaKit.sharedInstance.setImage(set: v.set!, rarity: v.rarity_)
                    }
                }
                
            } else if collectionView == printingsCollectionView {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailItemCell", for: indexPath)
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let printings_ = card.printings_,
                        let thumbnailImage = cell!.viewWithTag(100) as? UIImageView,
                        let setImage = cell!.viewWithTag(200) as? UIImageView {
                        
                        thumbnailImage.layer.cornerRadius = thumbnailImage.frame.height / 6
                        thumbnailImage.layer.masksToBounds = true
                        
                        let array = printings_.allObjects as! [CMSet]
                        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                        request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: true),
                                                   NSSortDescriptor(key: "number", ascending: true),
                                                   NSSortDescriptor(key: "mciNumber", ascending: true)]
                        request.predicate = NSPredicate(format: "name = %@ AND set.code IN %@", card.name!, array.map({$0.code}))
                        
                        printings = try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request) as? [CMCard]
                        let printing = printings![indexPath.row]
                        
                        if let croppedImage = ManaKit.sharedInstance.croppedImage(printing) {
                            thumbnailImage.image = croppedImage
                        } else {
                            thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cropBack)
                            ManaKit.sharedInstance.downloadCardImage(printing, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                                if error == nil {
                                    if printing == c {
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
                        
                        setImage.image = ManaKit.sharedInstance.setImage(set: printing.set!, rarity: printing.rarity_)
                    }
                }
            }
            
        case .pricing:
            ()
        }
        
        return cell!
    }
}

// UICollectionViewDelegate
extension CardViewController : UICollectionViewDelegate {
    
}

// MARK: UIScrollViewDelegate
extension CardViewController : UIScrollViewDelegate {
    func scrollToNearestVisibleCollectionViewCell() {
        if let collectionView = cardsCollectionView {
            let visibleCenterPositionOfScrollView = Float(collectionView.contentOffset.x + (collectionView.bounds.size.width / 2))
            var closestCellIndex = -1
            var closestDistance: Float = .greatestFiniteMagnitude
            
            for i in 0..<collectionView.visibleCells.count {
                let cell = collectionView.visibleCells[i]
                let cellWidth = cell.bounds.size.width
                let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
                
                // Now calculate closest cell
                let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
                if distance < closestDistance {
                    closestDistance = distance
                    closestCellIndex = collectionView.indexPath(for: cell)!.row
                }
            }
            if closestCellIndex != -1 {
                collectionView.scrollToItem(at: IndexPath(row: closestCellIndex, section: 0), at: .centeredHorizontally, animated: false)
                
                // update the first table row cell
                cardIndex = closestCellIndex
                tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                if let cards = cards {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: kNotificationSwipedToCard), object: nil, userInfo: ["card": cards[cardIndex]])
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == cardsCollectionView {
            scrollToNearestVisibleCollectionViewCell()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == cardsCollectionView && !decelerate {
            scrollToNearestVisibleCollectionViewCell()
        }
    }
}

