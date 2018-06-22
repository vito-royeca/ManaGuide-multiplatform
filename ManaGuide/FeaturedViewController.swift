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
import iCarousel
import ManaKit
import MBProgressHUD
import PromiseKit

enum FeaturedViewControllerSection: Int {
    case randomCards
    case latestSets
    case topRated
    case topViewed
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .randomCards: return "Random Cards"
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
    var randomCards: [CMCard]?
    var topRated: [CMCard]?
    var topViewed: [CMCard]?
    var latestSets: [CMSet]?
    var randomCardView: RandomCardView?
    var slideshowTimer: Timer?
    var randomCardsTimer: Timer?
    var flowLayoutHeight = CGFloat(0)
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fetchRandomCards()
        fetchLatestSets()
        randomCardsTimer = Timer.scheduledTimer(timeInterval: 60 * 5, target: self, selector: #selector(fetchRandomCards), userInfo: nil, repeats: true)
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
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.randomCards.rawValue, section: 0)) else {
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
                let dict = sender as? [String: Any] else {
                return
            }
            dest.cardIndex = dict["cardIndex"] as! Int
            dest.cards = dict["cards"] as? [CMCard]
            
        } else if segue.identifier == "showCardModal" {
            guard let nav = segue.destination as? UINavigationController else {
                return
            }
            guard let dest = nav.childViewControllers.first as? CardViewController,
                let dict = sender as? [String: Any] else {
                return
            }
            
            dest.cardIndex = dict["cardIndex"] as! Int
            dest.cards = dict["cards"] as? [CMCard]
            dest.title = dest.cards?[dest.cardIndex].name
            
        } else if segue.identifier == "showSet" {
            guard let dest = segue.destination as? SetViewController,
                let set = sender as? CMSet else {
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
        slideshowTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(showSlide), userInfo: nil, repeats: true)
    }
    
    func stopSlideShow() {
        if slideshowTimer != nil {
            slideshowTimer!.invalidate()
        }
        slideshowTimer = nil
    }
    
    func showSlide() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: FeaturedViewControllerSection.randomCards.rawValue, section: 0)) else {
            return
        }
        guard let carouselView = cell.viewWithTag(100) as? iCarousel else {
            return
        }
        
        var index = carouselView.currentItemIndex
        index += 1
        
        carouselView.scrollToItem(at: index, animated: true)
    }
    
    func fetchRandomCards() {
        let request = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "multiverseid != 0")
        
        randomCards = [CMCard]()
        guard let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMCard] else {
            return
        }
        
        repeat {
            let card = result[Int(arc4random_uniform(UInt32(result.count)))]
            if !randomCards!.contains(card) {
                randomCards!.append(card)
            }
        } while randomCards!.count <= 5
    }
    
    func fetchLatestSets() {
        let request = CMSet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
        request.fetchLimit = 10
        
        guard let result = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMSet] else {
            return
        }
        
        latestSets = result
    }
    
    func fetchTopRated() {
        FirebaseManager.sharedInstance.monitorTopRated(completion: { (cards) in
            DispatchQueue.main.async {
                self.showTopRated(cards: cards)
            }
        })
    }
    
    func fetchTopViewed() {
        FirebaseManager.sharedInstance.monitorTopViewed(completion: { (cards) in
            DispatchQueue.main.async {
                self.showTopViewed(cards: cards)
            }
        })
    }

    func showTopRated(cards: [CMCard]) {
        topRated = cards
        
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
    
    func showTopViewed(cards: [CMCard]) {
        topViewed = cards
        
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
        case FeaturedViewControllerSection.randomCards.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "RandomCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            guard let carouselView = c.viewWithTag(100) as? iCarousel else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            carouselView.dataSource = self
            carouselView.delegate = self
            carouselView.type = .linear
            carouselView.isPagingEnabled = true
            carouselView.currentItemIndex = 3
            cell = c
            
        case FeaturedViewControllerSection.latestSets.rawValue:
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            guard let titleLabel = c.viewWithTag(100) as? UILabel,
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
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            guard let titleLabel = c.viewWithTag(100) as? UILabel,
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
            guard let c = tableView.dequeueReusableCell(withIdentifier: "SliderCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            guard let titleLabel = c.viewWithTag(100) as? UILabel,
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
        case FeaturedViewControllerSection.randomCards.rawValue,
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
            let set = latestSets![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SetItemCell", for: indexPath)
            if let label = cell?.viewWithTag(100) as? UILabel {
                label.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
            }
            if let label = cell?.viewWithTag(200) as? UILabel {
                label.text = set.name
            }

        case FeaturedViewControllerSection.topRated.rawValue:
            let card = topRated![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopRatedItemCell", for: indexPath)
            if let thumbnailImage = cell?.viewWithTag(100) as? UIImageView {
                thumbnailImage.layer.cornerRadius = 10
                
                if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                    thumbnailImage.image = croppedImage
                } else {
                    thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)

                    firstly {
                        ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .artCrop)
                    }.done { (image: UIImage?) in
                        UIView.transition(with: thumbnailImage,
                                          duration: 1.0,
                                          options: .transitionCrossDissolve,
                                          animations: {
                                              thumbnailImage.image = image
                                          },
                                          completion: nil)
                    }.catch { error in
                            
                    }
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
            if let ratingView = cell?.viewWithTag(400) as? CosmosView {
                ratingView.rating = card.rating
                ratingView.settings.emptyBorderColor = kGlobalTintColor
                ratingView.settings.filledBorderColor = kGlobalTintColor
                ratingView.settings.filledColor = kGlobalTintColor
                ratingView.settings.fillMode = .precise
            }
            
        case FeaturedViewControllerSection.topViewed.rawValue:
            let card = topViewed![indexPath.row]
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopViewedItemCell", for: indexPath)
            if let thumbnailImage = cell?.viewWithTag(100) as? UIImageView {
                thumbnailImage.layer.cornerRadius = 10
                
                if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                    thumbnailImage.image = croppedImage
                } else {
                    thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cardBackCropped)
                    
                    firstly {
                        ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .artCrop)
                    }.done { (image: UIImage?) in
                        UIView.transition(with: thumbnailImage,
                                          duration: 1.0,
                                          options: .transitionCrossDissolve,
                                          animations: {
                                              thumbnailImage.image = image
                                          },
                                          completion: nil)
                    }.catch { error in
                            
                    }
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
                label.setFAText(prefixText: "", icon: .FAEye, postfixText: " \(card.views)", size: CGFloat(13))
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
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": indexPath.row,
                      "cards": topRated!]
        case FeaturedViewControllerSection.topViewed.rawValue:
            identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            sender = ["cardIndex": indexPath.row,
                      "cards": topViewed!]
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

// MARK: iCarouselDataSource
extension FeaturedViewController : iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
        var items = 0
        
        if let randomCards = randomCards {
            items = randomCards.count
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
        
        if let rcv = rcv,
            let randomCards = randomCards {
            let card = randomCards[index]
            rcv.card = card
            rcv.hideNameandSet()
            rcv.showImage()
        }
        
        return rcv!
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
        guard let randomCards = randomCards else {
            return
        }
        
        let card = randomCards[index]
        
        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
        let sender = ["cardIndex": 0,
                      "cards": [card]] as [String : Any]
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

