//
//  CardViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 27/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import Cosmos
import DATASource
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKMessengerShareKit
import Firebase
import Font_Awesome_Swift
import iCarousel
import IDMPhotoBrowser
import ManaKit
import MBProgressHUD
import PromiseKit
import NYAlertViewController
import TwitterKit
import TwitterCore

enum CardViewControllerSegmentedIndex: Int {
    case image
    case details
    case store
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .image: return "Image"
        case .details: return "Details"
        case .store: return "Store"
        }
    }
    
    static var count: Int {
        return 3
    }
}

enum CardViewControllerImageSection : Int {
    case pricing
    case image
    case actions
    
    static var count: Int {
        return 3
    }
}

enum CardViewControllerDetailsSection : Int {
    case manaCost
    case type
    case oracleText
    case originalText
    case flavorText
    case artist
    case set
    case otherNames
    case otherPrintings
    case variations
    case rulings
    case legalities
    case otherDetails
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .manaCost: return "Mana Cost"
        case .type: return "Type"
        case .oracleText: return "Text"
        case .originalText: return "Original Text"
        case .flavorText: return "Flavor Text"
        case .artist: return "Artist"
        case .set: return "Set"
        case .otherNames: return "Other Names"
        case .otherPrintings: return "Other Printings"
        case .variations: return "Variations"
        case .rulings: return "Rulings"
        case .legalities: return "Legalities"
        case .otherDetails: return "Other Details"
        }
    }
    
    static var count: Int {
        return 13
    }
}

class CardViewController: BaseViewController {
    // MARK: Variables
    var cardIndex = 0
    var cardMIDs: [NSManagedObjectID]?
    var otherPrintingMIDs: [NSManagedObjectID]?
    var otherPrintingsCollectionView: UICollectionView?
    var variationMIDs: [NSManagedObjectID]?
    var variationsCollectionView: UICollectionView?
    var cardViewIncremented = false
    var firstAppearance = true
    
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var activityButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var favoriteTapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        guard let card = loadCard(atIndex: cardIndex) else {
            return
        }
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.image.rawValue:
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
        case CardViewControllerSegmentedIndex.details.rawValue:
            if !cardViewIncremented {
                cardViewIncremented = true
                incrementCardViews()
            }
            
            if let printings_ = card.printings_ {
                let sets = printings_.allObjects as! [CMSet]
                var filteredSets = [CMSet]()
                let request = CMCard.fetchRequest()
                
                if let set = card.set {
                    filteredSets = sets.filter({ $0.code != set.code})
                }
                
                request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: true),
                                           NSSortDescriptor(key: "number", ascending: true),
                                           NSSortDescriptor(key: "mciNumber", ascending: true)]
                request.predicate = NSPredicate(format: "name = %@ AND set.code IN %@", card.name!, filteredSets.map({$0.code}))
                
                if let otherPrintings = try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request) as? [CMCard] {
                    otherPrintingMIDs = [NSManagedObjectID]()
                    for c in otherPrintings {
                        otherPrintingMIDs!.append(c.objectID)
                    }
                }
            }
            
            variationMIDs = [NSManagedObjectID]()
            if let variations_ = card.variations_ {
                if let variations = variations_.allObjects as? [CMCard] {
                    for variation in variations {
                        variationMIDs!.append(variation.objectID)
                    }
                }
            }
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
        case CardViewControllerSegmentedIndex.store.rawValue:
            tableView.reloadData()
            
            MBProgressHUD.showAdded(to: tableView, animated: true)
            firstly {
                ManaKit.sharedInstance.fetchTCGPlayerStorePricing(card: card)
            }.done {
                MBProgressHUD.hide(for: self.tableView, animated: true)
            }.catch { error in
                MBProgressHUD.hide(for: self.tableView, animated: true)
            }
            
        default:
            ()
        }
    }
    
    @IBAction func activityAction(_ sender: UIBarButtonItem) {
        guard let card = loadCard(atIndex: cardIndex) else {
            return
        }
        
        if let _ = ManaKit.sharedInstance.cardImage(card, imageType: .normal) {
            showActivityViewController(sender, card: card)
        } else {
            MBProgressHUD.showAdded(to: view, animated: true)
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
            }.done {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.showActivityViewController(sender, card: card)
                
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    @IBAction func favoriteAction(_ sender: UITapGestureRecognizer) {
        if let _ = Auth.auth().currentUser {
            toggleCardFavorite()
        } else {
            let actionAfterLogin = {(success: Bool) in
                if success {
                    self.toggleCardFavorite()
                }
            }
            performSegue(withIdentifier: "showLogin", sender: ["actionAfterLogin": actionAfterLogin])
        }
    }
    
    func ratingAction() {
        if let _ = Auth.auth().currentUser {
            self.showUpdateRatingDialog()
        } else {
            let actionAfterLogin = {(success: Bool) in
                if success {
                    self.showUpdateRatingDialog()
                }
            }
            performSegue(withIdentifier: "showLogin", sender: ["actionAfterLogin": actionAfterLogin])
        }
    }
    
    // MARK: Overrides
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentSegmentedControl.setFAIcon(icon: .FAImage, forSegmentAtIndex: 0)
        contentSegmentedControl.setFAIcon(icon: .FAEye, forSegmentAtIndex: 1)
        contentSegmentedControl.setFAIcon(icon: .FAShoppingCart, forSegmentAtIndex: 2)
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        tableView.register(UINib(nibName: "StoreTableViewCell", bundle: nil), forCellReuseIdentifier: "StoreCell")

        guard let card = loadCard(atIndex: cardIndex) else {
            return
        }
        title = card.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadViewController(_:)),
                                               name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification),
                                               object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kCardViewsUpdatedNotification),
                                                  object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadViewController(_:)),
                                               name: NSNotification.Name(rawValue: kCardViewsUpdatedNotification),
                                               object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kFavoriteToggleNotification),
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadViewController(_:)),
                                               name: NSNotification.Name(rawValue: kFavoriteToggleNotification),
                                               object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: nil)
        
        if firstAppearance {
            firstAppearance = false
        } else {
            reloadViewController(Notification(name: NSNotification.Name.NSManagedObjectContextObjectsDidChange))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification),
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kCardViewsUpdatedNotification),
                                                  object:nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kFavoriteToggleNotification),
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                                  object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController else {
                return
            }
            
            var destCardMIDs: [NSManagedObjectID]?
            
            if let cell = sender as? UICollectionViewCell {
                var parentView = cell.superview
                while parentView is UICollectionView != true {
                    parentView = parentView?.superview
                }
                
                if let parentView = parentView {
                    if parentView == otherPrintingsCollectionView {
                        if let otherPrintingsCollectionView = otherPrintingsCollectionView,
                            let otherPrintingMIDs = otherPrintingMIDs {
                            destCardMIDs = [otherPrintingMIDs[otherPrintingsCollectionView.indexPath(for: cell)!.item]]
                        }
                    } else if parentView == variationsCollectionView {
                        if let variationsCollectionView = variationsCollectionView,
                            let variationMIDs = variationMIDs {
                            destCardMIDs = [variationMIDs[variationsCollectionView.indexPath(for: cell)!.item]]
                        }
                    }
                }
            } else if let dict = sender as? [String: Any]  {
                if let cardMID = dict["cardMID"] as? NSManagedObjectID {
                    destCardMIDs = [cardMID]
                }
            }
            
            dest.cardMIDs = destCardMIDs
            dest.cardIndex = 0
            
        } else if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any] else {
                return
            }
            
            dest.request = dict["request"] as? NSFetchRequest<NSFetchRequestResult>
            dest.title = dict["title"] as? String
            
        } else if segue.identifier == "showSet" {
            guard let dest = segue.destination as? SetViewController,
                let dict = sender as? [String: Any],
                let set = dict["set"] as? CMSet else {
                return
            }
            
            dest.title = set.name
            dest.set = set
            
        } else if segue.identifier == "showLogin" {
            guard let dest = segue.destination as? UINavigationController,
                let loginVC = dest.childViewControllers.first as? LoginViewController,
                let dict = sender as? [String: Any],
                let actionAfterLogin = dict["actionAfterLogin"] as? ((Bool) -> Void) else {
                return
            }
                    
            loginVC.actionAfterLogin = actionAfterLogin
        }
    }
    
    func reloadViewController(_ notification: Notification) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch self.contentSegmentedControl.selectedSegmentIndex {
            case CardViewControllerSegmentedIndex.image.rawValue:
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.pricing.rawValue),
                                               IndexPath(row: 0, section: CardViewControllerImageSection.actions.rawValue)],
                                          with: .automatic)
            case CardViewControllerSegmentedIndex.store.rawValue:
                self.tableView.reloadData()
            default:
                ()
            }
        }
    }
    
    // MARK: Core Data notifications
    func changeNotification(_ notification: Notification) {
        guard let card = loadCard(atIndex: cardIndex) else {
            return
        }
        
        var willReload = false
        
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] {
            if let set = updatedObjects as? NSSet {
                for o in set.allObjects {
                    if let c = o as? CMCard {
                        if c.objectID == card.objectID {
                            willReload = true
                            break
                        }
                    }
                }
            }
        }
        
        if willReload {
            reloadViewController(notification)
        }
    }

    // MARK: Custom methods
    func showActivityViewController(_ sender: UIBarButtonItem, card: CMCard) {
        let provider = CardActivityItemProvider(card)
        let activityVC = UIActivityViewController(activityItems: [provider],
                                                  applicationActivities: [FacebookShareActivity(parent: self), TwitterShareActivity(parent: self)])

        var excludedActivityTypes: [UIActivityType] = [.addToReadingList, .openInIBooks, .postToFacebook, .postToTwitter]
        if #available(iOS 11.0, *) {
            excludedActivityTypes.append(.markupAsPDF)
        }

        if let popoverPresentationController = activityVC.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }
        
        activityVC.excludedActivityTypes = excludedActivityTypes
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            // user did not cancel
            if success {
                if let e = error {
                    print("error: \(e.localizedDescription)")
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
        self.present(activityVC, animated: true, completion: nil)
    }

    func showUpdateRatingDialog() {
        guard let card = loadCard(atIndex: cardIndex),
            let id = card.id else {
            return
        }
        
        var rating = Double(0)
        
        // get user's rating for this card, if there is
        for mid in FirebaseManager.sharedInstance.ratedCardMIDs {
            if mid == card.objectID {
                rating = card.rating
                break
            }
        }
        
        let ratingView = CosmosView(frame: CGRect.zero)
        ratingView.rating = rating
        ratingView.settings.emptyBorderColor = kGlobalTintColor
        ratingView.settings.filledBorderColor = kGlobalTintColor
        ratingView.settings.filledColor = kGlobalTintColor
        ratingView.settings.fillMode = .full
        
        let nyAlertController = NYAlertViewController(nibName: nil, bundle: nil)
        let confirmAction = NYAlertAction(title: "Ok", style: .default, handler: {(action: NYAlertAction?) -> Void in
            self.dismiss(animated: false, completion: nil)
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            FirebaseManager.sharedInstance.updateCardRatings(id, rating: ratingView.rating, firstAttempt: true)
        })
        let cancelAction = NYAlertAction(title: "Cancel", style: .default, handler:  {(action: NYAlertAction?) -> Void in
            self.dismiss(animated: false, completion: nil)
        })

        nyAlertController.title = "Rating"
        nyAlertController.message = rating > 0 ? "Update your rating for this card." : "Submit your rating for this card."
        nyAlertController.buttonColor = kGlobalTintColor
        nyAlertController.addAction(cancelAction)
        nyAlertController.addAction(confirmAction)
        nyAlertController.alertViewContentView = ratingView
        
        self.present(nyAlertController, animated: true, completion: nil)
    }
    
    func incrementCardViews() {
        guard let card = loadCard(atIndex: cardIndex),
            let id = card.id else {
            return
        }
        
        FirebaseManager.sharedInstance.incrementCardViews(id, firstAttempt: true)
    }
    
    func toggleCardFavorite() {
        guard let card = loadCard(atIndex: cardIndex),
            let id = card.id else {
            return
        }
        
        var isFavorite = false
        
        for mid in FirebaseManager.sharedInstance.favoriteMIDs {
            if mid == card.objectID {
                isFavorite = true
                break
            }
        }
        
        MBProgressHUD.showAdded(to: view, animated: true)
        FirebaseManager.sharedInstance.toggleCardFavorite(id, favorite: !isFavorite, firstAttempt: true)
    }
    
    func showImage(ofCard card: CMCard, inImageView imageView: UIImageView) {
        if let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) {
            imageView.image = image
        } else {
            imageView.image = ManaKit.sharedInstance.cardBack(card)
            
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
            }.done {
                guard let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) else {
                    return
                }
                
                let animations = {
                    imageView.image = image
                }
                UIView.transition(with: imageView,
                                  duration: 1.0,
                                  options: .transitionCrossDissolve,
                                  animations: animations,
                                  completion: nil)
                
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    func movePhotoTo(index: Int) {
        guard let card = loadCard(atIndex: index) else {
            return
        }
        
        cardIndex = index
        cardViewIncremented = false
        title = card.name
        
        if contentSegmentedControl.selectedSegmentIndex == CardViewControllerSegmentedIndex.image.rawValue {
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.pricing.rawValue),
                                      IndexPath(row: 0, section: CardViewControllerImageSection.actions.rawValue)], with: .automatic)
        }
    }
    
    func handleLink(_ tapGesture: UITapGestureRecognizer) {
        guard let label = tapGesture.view as? UILabel else {
            return
        }
        guard let attributedText = label.attributedText else {
            return
        }

        let storage = NSTextStorage(attributedString: attributedText)
        let textContainer = NSTextContainer(size: label.bounds.size)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)
        
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        
        let location = tapGesture.location(in: label)
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex < storage.length {
            guard let link = attributedText.attribute(NSLinkAttributeName, at: characterIndex, effectiveRange: nil) else {
                return
            }
            guard let url = URL(string: "\(link)") else {
                return
            }
            open(url)
        }
    }
    
    func updatePricing(inCell cell: UITableViewCell) {
        guard let card = loadCard(atIndex: cardIndex),
            let pricing = ManaKit.sharedInstance.findObject("CMCardPricing", objectFinder: ["card.id": card.id as AnyObject], createIfNotFound: true) as? CMCardPricing,
            let label100 = cell.viewWithTag(100) as? UILabel,
            let label200 = cell.viewWithTag(200) as? UILabel,
            let label300 = cell.viewWithTag(300) as? UILabel,
            let label400 = cell.viewWithTag(400) as? UILabel else {
            return
        }
        
        label100.text = pricing.low > 0 ? String(format: "$%.2f", pricing.low) : "NA"
        label200.text = pricing.average > 0 ? String(format: "$%.2f", pricing.average) : "NA"
        label300.text = pricing.high > 0 ? String(format: "$%.2f", pricing.high) : "NA"
        label400.text = pricing.foil > 0 ? String(format: "$%.2f", pricing.foil) : "NA"
    }
    
    func loadCard(atIndex index: Int) -> CMCard? {
        guard let cardMIDs = cardMIDs else {
            return nil
        }
        let cardMID = cardMIDs[index]
        
        guard let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: cardMID) as? CMCard else {
            return nil
        }
        
        return card
    }
}

// MARK: UITableViewDataSource
extension CardViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let card = loadCard(atIndex: cardIndex) else {
            return 0
        }
        
        var rows = 0
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.image.rawValue:
            rows = 1
            
        case CardViewControllerSegmentedIndex.details.rawValue:
            switch section {
            case CardViewControllerDetailsSection.otherNames.rawValue:
                if let names_ = card.names_ {
                    if let array = names_.allObjects as? [CMCard] {
                        rows = array.filter({ $0.name != card.name}).count
                    }
                }
                if rows == 0 {
                    rows = 1
                }
            case CardViewControllerDetailsSection.rulings.rawValue:
                if let rulings_ = card.rulings_ {
                    rows = rulings_.allObjects.count >= 1 ? rulings_.allObjects.count : 1
                }
            case CardViewControllerDetailsSection.legalities.rawValue:
                if let cardLegalities_ = card.cardLegalities_ {
                    rows = cardLegalities_.allObjects.count >= 1 ? cardLegalities_.allObjects.count : 1
                }
            default:
                rows = 1
            }
            
        case CardViewControllerSegmentedIndex.store.rawValue:
            guard let suppliers = card.suppliers else {
                return rows
            }
            rows = suppliers.count + 1
            
        default:
            ()
        }
        
        return rows
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 0
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.image.rawValue:
            sections = CardViewControllerImageSection.count
        case CardViewControllerSegmentedIndex.details.rawValue:
            sections = CardViewControllerDetailsSection.count
        case CardViewControllerSegmentedIndex.store.rawValue:
            sections = 1
        default:
            ()
        }
        
        return sections
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let card = loadCard(atIndex: cardIndex) else {
            return UITableViewCell(frame: CGRect.zero)
        }
        
        var cell: UITableViewCell?
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.image.rawValue:
            tableView.separatorStyle = .none
            
            switch indexPath.section {
            case CardViewControllerImageSection.pricing.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "PricingCell") else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                firstly {
                    ManaKit.sharedInstance.fetchTCGPlayerCardPricing(card: card)
                }.done {
                    self.updatePricing(inCell: c)
                }.catch { error in
                    self.updatePricing(inCell: c)
                }
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerImageSection.image.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "CarouselCell"),
                    let carouselView = c.viewWithTag(100) as? iCarousel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                carouselView.dataSource = self
                carouselView.delegate = self
                carouselView.type = .coverFlow2
                carouselView.isPagingEnabled = true
                carouselView.currentItemIndex = cardIndex
            
                if let imageView = carouselView.itemView(at: cardIndex) as? UIImageView {
                    showImage(ofCard: card, inImageView: imageView)
                }
            
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerImageSection.actions.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "ActionsCell"),
                    let ratingView = c.viewWithTag(100) as? CosmosView,
                    let label101 = c.viewWithTag(101) as? UILabel,
                    let label200 = c.viewWithTag(200) as? UILabel,
                    let label300 = c.viewWithTag(300) as? UILabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                
                ratingView.didFinishTouchingCosmos = { _ in
                    self.ratingAction()
                }
                ratingView.rating = card.rating //Double(arc4random_uniform(5) + 1)
                ratingView.settings.emptyBorderColor = kGlobalTintColor
                ratingView.settings.filledBorderColor = kGlobalTintColor
                ratingView.settings.filledColor = kGlobalTintColor
                ratingView.settings.fillMode = .precise
                
                label101.text = "\(card.ratings) Rating\(card.ratings > 1 ? "s" : "")"
                
                var isFavorite = false
                for mid in FirebaseManager.sharedInstance.favoriteMIDs {
                    if mid == card.objectID {
                        isFavorite = true
                        break
                    }
                }
                if let taps = label200.gestureRecognizers {
                    for tap in taps {
                        label200.removeGestureRecognizer(tap)
                    }
                }
                label200.setFAText(prefixText: "", icon: isFavorite ? .FAHeart : .FAHeartO, postfixText: "", size: CGFloat(30))
                label200.addGestureRecognizer(favoriteTapGestureRecognizer)
                label200.textColor = kGlobalTintColor
                
                label300.setFAText(prefixText: "", icon: .FAEye, postfixText: " \(card.views)", size: CGFloat(13))
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            default:
                ()
            }
            
        case CardViewControllerSegmentedIndex.details.rawValue:
            tableView.separatorStyle = .singleLine
            
            switch indexPath.section {
            case CardViewControllerDetailsSection.manaCost.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let label = c.textLabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let text = card.manaCost {
                    label.attributedText = NSAttributedString(symbol: text, pointSize: label.font.pointSize)
                } else {
                    label.text = " "
                }
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.type.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let label = c.textLabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let _ = card.type_ {
                    label.attributedText = MGUtilities.composeType(of: card, pointSize: label.font.pointSize)
                    label.adjustsFontSizeToFitWidth = true
                } else {
                    label.text = " "
                    label.adjustsFontSizeToFitWidth = false
                }
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.oracleText.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let label = c.viewWithTag(100) as? UILabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let text = card.text {
                    label.attributedText = NSAttributedString(symbol: "\n\(text)\n ", pointSize: label.font.pointSize)
                } else {
                    label.text = " "
                }
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.originalText.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let label = c.viewWithTag(100) as? UILabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let text = card.originalText {
                    label.attributedText = NSAttributedString(symbol: "\n\(text)\n ", pointSize: label.font.pointSize)
                } else {
                    label.text = " "
                }
                    
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.flavorText.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let label = c.viewWithTag(100) as? UILabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let text = card.flavor {
                    label.text = "\n\(text)\n"
                } else {
                    label.text = "\n"
                }
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.artist.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let label = c.textLabel,
                    let detailTextLabel = c.detailTextLabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if let artist = card.artist_ {
                    label.adjustsFontSizeToFitWidth = true
                    label.text = artist.name
                    detailTextLabel.text = "More Cards"
                } else {
                    label.text = " "
                    detailTextLabel.text = " "
                }
                c.selectionStyle = .default
                c.accessoryType = .disclosureIndicator
                cell = c
                
            case CardViewControllerDetailsSection.set.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let label = c.textLabel,
                    let detailTextLabel = c.detailTextLabel,
                    let set = card.set,
                    let setName = set.name,
                    let keyruneUnicode = ManaKit.sharedInstance.keyruneUnicode(forSet: set),
                    let keyruneColor = ManaKit.sharedInstance.keyruneColor(forCard: card) else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                let attributes = [NSFontAttributeName: UIFont(name: "Keyrune", size: 17)!,
                                  NSForegroundColorAttributeName: keyruneColor]
                let attributedString = NSMutableAttributedString(string: keyruneUnicode,
                                                                 attributes: attributes)
                
                attributedString.append(NSMutableAttributedString(string: " \(setName)",
                    attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
                
                label.attributedText = attributedString
                label.adjustsFontSizeToFitWidth = true
                detailTextLabel.text = "More Cards"
                
                c.selectionStyle = .default
                c.accessoryType = .disclosureIndicator
                cell = c

            case CardViewControllerDetailsSection.otherNames.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let label = c.textLabel else {
                        return UITableViewCell(frame: CGRect.zero)
                }
                
                var otherCard: CMCard?
                
                if let names_ = card.names_ {
                    if let array = names_.allObjects as? [CMCard] {
                        let array2 = array.filter({ $0.name != card.name})
                        if array2.count > 0 {
                            otherCard = array2[indexPath.row]
                        }
                    }
                }
                
                if let otherCard = otherCard {
                    label.text = otherCard.name
                    c.selectionStyle = .default
                    c.accessoryType = .disclosureIndicator
                } else {
                    label.text = " "
                    c.selectionStyle = .none
                    c.accessoryType = .none
                }
                
                cell = c

            case CardViewControllerDetailsSection.otherPrintings.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "ThumbnailsCell") else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.variations.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "ThumbnailsCell") else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.rulings.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let label = c.viewWithTag(100) as? UILabel,
                    let rulings_ = card.rulings_ else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                let array = rulings_.allObjects.sorted(by: {(first: Any, second: Any) -> Bool in
                    if let a = first as? CMRuling,
                        let b = second as? CMRuling {
                        if let aDate = a.date,
                            let bDate = b.date {
                            return aDate > bDate
                        }
                    }
                    return false
                }) as! [CMRuling]
                
                
                if array.count > 0 {
                    let ruling = array[indexPath.row]
                    var contents = ""
                    
                    if let date = ruling.date {
                        contents.append(date)
                    }
                    if let text = ruling.text {
                        if contents.count > 0 {
                            contents.append("\n\n")
                        }
                        contents.append(text)
                    }
                    
                    label.attributedText = NSAttributedString(symbol: contents, pointSize: label.font.pointSize)
                } else {
                    label.text = "\n"
                }
                
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.legalities.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let label = c.textLabel,
                    let detailTextLabel = c.detailTextLabel,
                    let cardLegalities_ = card.cardLegalities_ else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                let array = cardLegalities_.allObjects as! [CMCardLegality]
                
                if array.count > 0 {
                    let cardLegality = array[indexPath.row]
                    label.text = cardLegality.format!.name
                    detailTextLabel.text = cardLegality.legality!.name
                } else {
                    label.text = " "
                    detailTextLabel.text = " "
                }
                    
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            case CardViewControllerDetailsSection.otherDetails.rawValue:
                guard let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let label = c.viewWithTag(100) as? UILabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                label.attributedText = MGUtilities.composeOtherDetails(forCard: card)
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            default:
                ()
            }
            
        case CardViewControllerSegmentedIndex.store.rawValue:
            guard let suppliers = card.suppliers else {
                return UITableViewCell(frame: CGRect.zero)
            }
            let count = suppliers.allObjects.count
            
            if count == 0 {
                guard let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let label = c.viewWithTag(100) as? UILabel else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                if card.storePricingLastUpdate == nil {
                    label.attributedText = NSAttributedString(html: "<html><center>Loading...</center></html>")
                } else {
                    label.attributedText = NSAttributedString(html: "<html><center>No data found.</center></html>")
                }
                label.isUserInteractionEnabled = false
                if let taps = label.gestureRecognizers {
                    for tap in taps {
                        label.removeGestureRecognizer(tap)
                    }
                }
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
                
            } else {
                if indexPath.row <= count - 1 {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "StoreCell") as? StoreTableViewCell,
                        let suppliers = card.suppliers,
                        let supplier = suppliers.allObjects[indexPath.row] as? CMSupplier else {
                        return UITableViewCell(frame: CGRect.zero)
                    }
                    
                    c.delegate = self
                    c.display(supplier)
                
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                    
                } else {
                    guard let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                        let label = c.viewWithTag(100) as? UILabel,
                        let note = card.storePricingNote else {
                            return UITableViewCell(frame: CGRect.zero)
                    }
                    
                    label.attributedText = NSAttributedString(html: note)
                    label.isUserInteractionEnabled = true
                    label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLink(_:))))
                    
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            }
            
        default:
            ()
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let card = loadCard(atIndex: cardIndex) else {
            return nil
        }
        
        var headerTitle: String?
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.details.rawValue:
            switch section {
            case CardViewControllerDetailsSection.manaCost.rawValue:
                headerTitle = CardViewControllerDetailsSection.manaCost.description
            case CardViewControllerDetailsSection.type.rawValue:
                headerTitle = CardViewControllerDetailsSection.type.description
            case CardViewControllerDetailsSection.oracleText.rawValue:
                headerTitle = CardViewControllerDetailsSection.oracleText.description
            case CardViewControllerDetailsSection.originalText.rawValue:
                headerTitle = CardViewControllerDetailsSection.originalText.description
            case CardViewControllerDetailsSection.flavorText.rawValue:
                headerTitle = CardViewControllerDetailsSection.flavorText.description
            case CardViewControllerDetailsSection.artist.rawValue:
                headerTitle = CardViewControllerDetailsSection.artist.description
            case CardViewControllerDetailsSection.set.rawValue:
                headerTitle = CardViewControllerDetailsSection.set.description
            case CardViewControllerDetailsSection.otherNames.rawValue:
                headerTitle = CardViewControllerDetailsSection.otherNames.description
                var count = 0
                
                if let names_ = card.names_ {
                    if let array = names_.allObjects as? [CMCard] {
                        count = array.filter({ $0.name != card.name}).count
                        
                    }
                }
                headerTitle?.append(": \(count)")
            case CardViewControllerDetailsSection.otherPrintings.rawValue:
                headerTitle = CardViewControllerDetailsSection.otherPrintings.description
                var count = 0
                
                if let otherPrintingMIDs = otherPrintingMIDs {
                    count = otherPrintingMIDs.count
                }
                headerTitle?.append(": \(count)")
            case CardViewControllerDetailsSection.variations.rawValue:
                headerTitle = CardViewControllerDetailsSection.variations.description
                var count = 0
                
                if let variationMIDs = variationMIDs {
                    count = variationMIDs.count
                }
                headerTitle?.append(": \(count)")
            case CardViewControllerDetailsSection.rulings.rawValue:
                headerTitle = CardViewControllerDetailsSection.rulings.description
                var count = 0
                
                if let rulings_ = card.rulings_ {
                    count = rulings_.count
                }
                headerTitle?.append(": \(count)")
            case CardViewControllerDetailsSection.legalities.rawValue:
                headerTitle = CardViewControllerDetailsSection.legalities.description
                var count = 0
                
                if let cardLegalities_ = card.cardLegalities_ {
                    count = cardLegalities_.count
                }
                headerTitle?.append(": \(count)")
            case CardViewControllerDetailsSection.otherDetails.rawValue:
                headerTitle = CardViewControllerDetailsSection.otherDetails.description
            default:
                ()
            }
        default:
            ()
        }
        
        return headerTitle
    }
}

// MARK: UITableViewDelegate
extension CardViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.details.rawValue:
            switch indexPath.section {
            case CardViewControllerDetailsSection.otherPrintings.rawValue:
                guard let collectionView = cell.viewWithTag(100) as? UICollectionView else {
                    return
                }
                
                if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    let width = CGFloat(100)
                    let height = CGFloat(72)
                    flowLayout.itemSize = CGSize(width: width, height: height)
                    flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                }
                
                collectionView.dataSource = self
                collectionView.delegate = self
                otherPrintingsCollectionView = collectionView
                collectionView.reloadData()
                
            case CardViewControllerDetailsSection.variations.rawValue:
                guard let collectionView = cell.viewWithTag(100) as? UICollectionView else {
                    return
                }
                
                if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    let width = CGFloat(100)
                    let height = CGFloat(72)
                    flowLayout.itemSize = CGSize(width: width, height: height)
                    flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                }
                
                collectionView.dataSource = self
                collectionView.delegate = self
                variationsCollectionView = collectionView
                collectionView.reloadData()
                
            default:
                ()
            }
        default:
            ()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let card = loadCard(atIndex: cardIndex) else {
            return CGFloat(0)
        }
        
        var height = CGFloat(0)
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.image.rawValue:
            switch indexPath.section {
            case CardViewControllerImageSection.pricing.rawValue:
                height = 44
            case CardViewControllerImageSection.image.rawValue:
                height = tableView.frame.size.height - 88
            case CardViewControllerImageSection.actions.rawValue:
                height = 44
            default:
                ()
            }
            
        case CardViewControllerSegmentedIndex.details.rawValue:
            switch indexPath.section {
            case CardViewControllerDetailsSection.otherPrintings.rawValue,
                 CardViewControllerDetailsSection.variations.rawValue:
                height = CGFloat(88)
            default:
                height = UITableViewAutomaticDimension
            }
            
        case CardViewControllerSegmentedIndex.store.rawValue:
            guard let suppliers = card.suppliers else {
                return CGFloat(0)
            }
            let count = suppliers.allObjects.count
            
            if count == 0 {
                height = UITableViewAutomaticDimension
            } else {
                if indexPath.row <= count - 1 {
                    height = kStoreTableViewCellHeight
                } else {
                    height = UITableViewAutomaticDimension
                }
            }
            
        default:
            ()
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let card = loadCard(atIndex: cardIndex) else {
            return nil
        }
        
        var path: IndexPath?
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.details.rawValue:
            switch indexPath.section {
            case CardViewControllerDetailsSection.artist.rawValue,
                 CardViewControllerDetailsSection.set.rawValue:
                path = indexPath
            case CardViewControllerDetailsSection.otherNames.rawValue:
                var otherCard: CMCard?
                
                if let names_ = card.names_ {
                    if let array = names_.allObjects as? [CMCard] {
                        let array2 = array.filter({ $0.name != card.name})
                        if array2.count > 0 {
                            otherCard = array2[indexPath.row]
                        }
                    }
                }
                
                if let _ = otherCard {
                    path = indexPath
                }
                
            default:
                ()
            }
        default:
            ()
        }
            
        return path
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let card = loadCard(atIndex: cardIndex) else {
            return
        }
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case CardViewControllerSegmentedIndex.details.rawValue:
            switch indexPath.section {
            case CardViewControllerDetailsSection.artist.rawValue:
                guard let artist = card.artist_ else {
                    return
                }
                
                let request = CMCard.fetchRequest()
                let predicate = NSPredicate(format: "artist_.name = %@", artist.name!)
                
                request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                           NSSortDescriptor(key: "name", ascending: true),
                                           NSSortDescriptor(key: "set.releaseDate", ascending: true)]
                request.predicate = predicate
                
                performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                                    "title": artist.name!])
                
            case CardViewControllerDetailsSection.set.rawValue:
                guard let set = card.set else {
                    return
                }
                
                performSegue(withIdentifier: "showSet", sender: ["set": set])
                
            case CardViewControllerDetailsSection.otherNames.rawValue:
                var otherCard: CMCard?
                
                if let names_ = card.names_ {
                    if let array = names_.allObjects as? [CMCard] {
                        let array2 = array.filter({ $0.name != card.name})
                        if array2.count > 0 {
                            otherCard = array2[indexPath.row]
                        }
                    }
                }
                
                guard let oc = otherCard else {
                    return
                }
                
                performSegue(withIdentifier: "showCard", sender: ["card": oc])
                
            default:
                ()
            }
        default:
            ()
        }
    }
}

// MARK: UICollectionViewDataSource
extension CardViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var items = 0
        
        if collectionView == otherPrintingsCollectionView {
            if let otherPrintingMIDs = otherPrintingMIDs {
                items = otherPrintingMIDs.count
            }
        } else if collectionView == variationsCollectionView {
            if let variationMIDs = variationMIDs {
                items = variationMIDs.count
            }
        }

        return items
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailItemCell", for: indexPath)
        var card: CMCard?
        
        if collectionView == otherPrintingsCollectionView {
            if let otherPrintingMIDs = otherPrintingMIDs {
                card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: otherPrintingMIDs[indexPath.row]) as? CMCard
            }
        } else if collectionView == variationsCollectionView {
            if let variationMIDs = variationMIDs {
                card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: variationMIDs[indexPath.row]) as? CMCard
            }
        }
        
        guard let c = card,
            let thumbnailImage = cell.viewWithTag(100) as? UIImageView,
            let setImage = cell.viewWithTag(200) as? UILabel else {
            return cell
        }
        
        if let croppedImage = ManaKit.sharedInstance.croppedImage(c) {
            thumbnailImage.image = croppedImage
        } else {
            thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cropBack)
            
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: c, imageType: .artCrop)
            }.done {
                guard let image = ManaKit.sharedInstance.croppedImage(c) else {
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
        
        setImage.layer.cornerRadius = setImage.frame.height / 2
        setImage.text = ManaKit.sharedInstance.keyruneUnicode(forSet: c.set!)
        setImage.textColor = ManaKit.sharedInstance.keyruneColor(forCard: c)
        
        return cell
    }
}

// UICollectionViewDelegate
extension CardViewController : UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        if collectionView == otherPrintingsCollectionView {
//            if let thumbnailImage = cell.viewWithTag(100) as? UIImageView {
//                thumbnailImage.layer.cornerRadius = 10
//                thumbnailImage.layer.masksToBounds = true
//            }
//        }
//    }
}

// MARK: iCarouselDataSource
extension CardViewController : iCarouselDataSource {
    func numberOfItems(in carousel: iCarousel) -> Int {
        guard let cardMIDs = cardMIDs else {
            return 0
        }
        
        return cardMIDs.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var imageView = UIImageView(frame: CGRect.zero)
        
        //reuse view if available, otherwise create a new view
        if let v = view as? UIImageView {
            imageView = v
            
        } else {
            let height = tableView.frame.size.height - 88
            let width = tableView.frame.size.width - 40
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            imageView.contentMode = .scaleAspectFit

            // add drop shadow
            imageView.layer.shadowColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.45).cgColor
            imageView.layer.shadowOffset = CGSize(width: 1, height: 1)
            imageView.layer.shadowOpacity = 1
            imageView.layer.shadowRadius = 6.0
            imageView.clipsToBounds = false
        }
        
        guard let card = loadCard(atIndex: index) else {
            return imageView
        }
        
        showImage(ofCard: card, inImageView: imageView)
        return imageView
    }
}

// MARK: iCarouselDelegate
extension CardViewController : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        movePhotoTo(index: carousel.currentItemIndex)
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        guard let cardMIDs = cardMIDs else {
            return
        }
        
        var photos = [ManaGuidePhoto]()
        
        for cardMID in cardMIDs {
            if let card = ManaKit.sharedInstance.dataStack?.mainContext.object(with: cardMID) as? CMCard {
                photos.append(ManaGuidePhoto(cardMID: card.objectID))
            }
        }
        
        if let browser = IDMPhotoBrowser(photos: photos) {
            browser.setInitialPageIndex(UInt(index))

            browser.displayActionButton = false
            browser.usePopAnimation = true
            browser.forceHideStatusBar = true
            browser.delegate = self

            present(browser, animated: true, completion: nil)
        }
    }
}

// MARK: IDMPhotoBrowserDelegate
extension CardViewController : IDMPhotoBrowserDelegate {
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser,  didShowPhotoAt index: UInt) {
        let i = Int(index)
        
        if i != cardIndex {
            movePhotoTo(index: i)
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.image.rawValue)], with: .none)
        }
    }
}

// MARK: StoreTableViewCellDelegate
extension CardViewController : StoreTableViewCellDelegate {
    func open(_ link: URL) {
        UIApplication.shared.open(link)
    }
}

