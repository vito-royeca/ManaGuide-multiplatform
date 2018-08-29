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
import InAppSettingsKit
import iCarousel
import ManaKit
import MBProgressHUD
import PromiseKit

enum FeaturedViewControllerSection: Int {
    case latestCards
    case latestSets
    case topRated
    case topViewed
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .latestCards: return "Latest Cards"
        case .latestSets: return "Latest Sets"
        case .topRated: return "Top Rated"
        case .topViewed: return "Top Viewed"
        }
    }
    
    static var count: Int {
        return 4
    }
}

class FeaturedViewController: BaseViewController {

    // MARK: Variables
    var latestCardMIDs: [NSManagedObjectID]?
    var topRated: [NSManagedObjectID]?
    var topViewed: [NSManagedObjectID]?
    var latestSets: [CMSet]?
    var randomCardView: RandomCardView?
    var slideshowTimer: Timer?
    var latestCardsTimer: Timer?
    var flowLayoutHeight = CGFloat(0)
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        NotificationCenter.default.removeObserver(self,
//                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
//                                                  object:nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(self.updateData(_:)),
//                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
//                                               object: nil)
        
//        rightMenuButton.image = UIImage.init(icon: .FABars,
//                                             size: CGSize(width: 30, height: 30),
//                                             textColor: .white,
//                                             backgroundColor: .clear)
//        rightMenuButton.title = nil
        
        fetchLatestSets()
        fetchLatestCards()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSlideShow()
        fetchTopRated()
        fetchTopViewed()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSlideShow()
        FirebaseManager.sharedInstance.demonitorTopCharts()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        flowLayoutHeight = (view.frame.size.height / 3) - 50
        tableView.reloadData()
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.latestCards.rawValue, section: 0)) else {
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
    func startSlideShow() {
        latestCardsTimer = Timer.scheduledTimer(timeInterval: 60 * 5,
                                                target: self,
                                                selector: #selector(fetchLatestCards),
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
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.latestCards.rawValue, section: 0)) else {
            return
        }
        guard let carouselView = cell.viewWithTag(100) as? iCarousel else {
            return
        }
        
        var index = carouselView.currentItemIndex
        index += 1
        
        carouselView.scrollToItem(at: index, animated: true)
    }
    
    func fetchLatestCards() {
        guard let latestSets = latestSets else {
            return
        }
        
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "multiverseid != 0 AND set.code IN %@", latestSets.map( { $0.code} ))
        
        latestCardMIDs = [NSManagedObjectID]()
        let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
        
        repeat {
            let card = result[Int(arc4random_uniform(UInt32(result.count)))]
            let cardMID = card.objectID
            if !latestCardMIDs!.contains(cardMID) {
                latestCardMIDs!.append(cardMID)
            }
        } while latestCardMIDs!.count <= 5
    }
    
    func fetchLatestSets() {
        let request: NSFetchRequest<CMSet> = CMSet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = 10
        
        latestSets = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
    }
    
    func fetchTopRated() {
        FirebaseManager.sharedInstance.monitorTopRated(completion: { cardMIDs in
            DispatchQueue.main.async {
                self.showTopRated(cardMIDs: cardMIDs)
            }
        })
    }
    
    func fetchTopViewed() {
        FirebaseManager.sharedInstance.monitorTopViewed(completion: { cardMIDs in
            DispatchQueue.main.async {
                self.showTopViewed(cardMIDs: cardMIDs)
            }
        })
    }

    func showTopRated(cardMIDs: [NSManagedObjectID]) {
        topRated = cardMIDs
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.topRated.rawValue, section: 0)) else {
            return
        }
        
        for v in cell.contentView.subviews {
            if let collectionView = v as? UICollectionView {
                collectionView.reloadData()
                break
            }
        }
    }
    
    func showTopViewed(cardMIDs: [NSManagedObjectID]) {
        topViewed = cardMIDs
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.topViewed.rawValue, section: 0)) else {
            return
        }
        
        for v in cell.contentView.subviews {
            if let collectionView = v as? UICollectionView {
                collectionView.reloadData()
                break
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
        
        if flowLayoutHeight == 0 {
            flowLayoutHeight = (view.frame.size.height / 3) - 50
        }

        switch indexPath.row {
        case FeaturedViewControllerSection.latestCards.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "RandomCell"),
                let carouselView = c.viewWithTag(100) as? iCarousel else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            carouselView.dataSource = self
            carouselView.delegate = self
            carouselView.type = .linear
            carouselView.isPagingEnabled = true
            carouselView.currentItemIndex = 3
            cell = c
            
        case FeaturedViewControllerSection.latestSets.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell"),
                let titleLabel = c.viewWithTag(100) as? UILabel,
                let showAllButton = c.viewWithTag(200) as? UIButton else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            titleLabel.text = FeaturedViewControllerSection.latestSets.description
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
                collectionView.tag = FeaturedViewControllerSection.latestSets.rawValue
                collectionView.reloadData()
            }
            
            cell = c
            
        case FeaturedViewControllerSection.topRated.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell"),
                let titleLabel = c.viewWithTag(100) as? UILabel,
                let showAllButton = c.viewWithTag(200) as? UIButton else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            titleLabel.text = FeaturedViewControllerSection.topRated.description
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
                collectionView.tag = FeaturedViewControllerSection.topRated.rawValue
            }
            cell = c
            
        case FeaturedViewControllerSection.topViewed.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell"),
                let titleLabel = c.viewWithTag(100) as? UILabel,
                let showAllButton = c.viewWithTag(200) as? UIButton else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            titleLabel.text = FeaturedViewControllerSection.topViewed.description
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
                collectionView.tag = FeaturedViewControllerSection.topViewed.rawValue
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
        case FeaturedViewControllerSection.latestCards.rawValue,
             FeaturedViewControllerSection.latestSets.rawValue,
             FeaturedViewControllerSection.topRated.rawValue,
             FeaturedViewControllerSection.topViewed.rawValue:
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
        case FeaturedViewControllerSection.latestSets.rawValue:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SetItemCell", for: indexPath)
            let set = latestSets![indexPath.row]
            
            guard let label100 = cell?.viewWithTag(100) as? UILabel,
                let label200 = cell?.viewWithTag(200) as? UILabel else {
                return cell!
            }
            label100.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            label200.text = set.name
            
        case FeaturedViewControllerSection.topRated.rawValue:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopRatedItemCell", for: indexPath)
            let cardMID = topRated![indexPath.row]
            
            guard let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: cardMID) as? CMCard,
                let set = card.set,
                let thumbnailImage = cell?.viewWithTag(100) as? UIImageView,
                let label200 = cell?.viewWithTag(200) as? UILabel,
                let label300 = cell?.viewWithTag(300) as? UILabel,
                let ratingView = cell?.viewWithTag(400) as? CosmosView else {
                return cell!
            }
        
            thumbnailImage.layer.cornerRadius = 10
            if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                thumbnailImage.image = croppedImage
            } else {
                thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)

                firstly {
                    ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .artCrop)
                }.done {
                    guard let image = ManaKit.sharedInstance.croppedImage(card) else {
                        return
                    }
                    
                    let animations = {
                        thumbnailImage.image = image
                    }
                    UIView.transition(with: thumbnailImage,
                                      duration: 1.0,
                                      options: .transitionCrossDissolve,
                                      animations: animations,
                                      completion: nil)
                }.catch { error in
                    
                }
            }
        
            
            label200.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            label200.textColor = ManaKit.sharedInstance.keyruneColor(forCard: card)
            label200.layer.cornerRadius = label200.frame.height / 2
            label300.text = card.name
            
            ratingView.rating = card.rating
            ratingView.settings.emptyBorderColor = LookAndFeel.GlobalTintColor
            ratingView.settings.filledBorderColor = LookAndFeel.GlobalTintColor
            ratingView.settings.filledColor = LookAndFeel.GlobalTintColor
            ratingView.settings.fillMode = .precise
            
        case FeaturedViewControllerSection.topViewed.rawValue:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopViewedItemCell", for: indexPath)
            let cardMID = topViewed![indexPath.row]
            
            guard let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: cardMID) as? CMCard,
                let set = card.set,
                let thumbnailImage = cell?.viewWithTag(100) as? UIImageView,
                let label200 = cell?.viewWithTag(200) as? UILabel,
                let label300 = cell?.viewWithTag(300) as? UILabel,
                let label400 = cell?.viewWithTag(400) as? UILabel else {
                return cell!
            }
            
            thumbnailImage.layer.cornerRadius = 10
            if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                thumbnailImage.image = croppedImage
            } else {
                thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                
                firstly {
                    ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .artCrop)
                }.done {
                    guard let image = ManaKit.sharedInstance.croppedImage(card) else {
                        return
                    }
                    
                    let animations = {
                        thumbnailImage.image = image
                    }
                    UIView.transition(with: thumbnailImage,
                                      duration: 1.0,
                                      options: .transitionCrossDissolve,
                                      animations: animations,
                                      completion: nil)
                }.catch { error in
                    
                }
            }
            
            label200.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            label200.textColor = ManaKit.sharedInstance.keyruneColor(forCard: card)
            label200.layer.cornerRadius = label200.frame.height / 2
            label300.text = card.name
            label400.setFAText(prefixText: "", icon: .FAEye, postfixText: " \(card.views)", size: CGFloat(13))
            
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
        case FeaturedViewControllerSection.topRated.rawValue:
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": indexPath.row,
                      "cardMIDs": topRated!]
        case FeaturedViewControllerSection.topViewed.rawValue:
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": indexPath.row,
                      "cardMIDs": topViewed!]
        case FeaturedViewControllerSection.latestSets.rawValue:
            let set = latestSets![indexPath.row]
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
        var items = 0
        
        if let latestCardMIDs = latestCardMIDs {
            items = latestCardMIDs.count
        }
        return items
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var rcv: RandomCardView?
        
        //reuse view if available, otherwise create a new view
        if let v = view as? RandomCardView {
            rcv = v
        } else {
            if let r = Bundle.main.loadNibNamed("RandomCardView", owner: self, options: nil)?.first as? RandomCardView {
                let height = tableView.frame.size.height / 3
                var width = tableView.frame.size.width
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    width = width / 3
                }
                
                r.frame = CGRect(x: 0, y: 0, width: width, height: height)
                rcv = r
            }
        }
        
        guard let rcvNew = rcv,
            let latestCardMIDs = latestCardMIDs,
            let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: latestCardMIDs[index]) as? CMCard else {
            return rcv!
        }
        
        rcvNew.cardMID = card.objectID
        rcvNew.hideNameandSet()
        rcvNew.showImage()
        return rcvNew
    }
}

// MARK: iCarouselDelegate
extension FeaturedViewController : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        guard let rcv = carousel.itemView(at: carousel.currentItemIndex) as? RandomCardView else {
            return
        }
        
        for v in carousel.visibleItemViews {
            if let a = v as? RandomCardView {
                if rcv == a {
                    a.showNameandSet()
                } else {
                    a.hideNameandSet()
                }
            }
        }
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        guard let latestCardMIDs = latestCardMIDs,
            let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: latestCardMIDs[index]) as? CMCard else {
            return
        }
        
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



