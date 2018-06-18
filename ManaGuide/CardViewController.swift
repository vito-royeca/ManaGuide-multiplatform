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
    case otherPrintings
    case otherNames
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
        case .otherPrintings: return "Other Printings"
        case .otherNames: return "Other Names"
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
    var cards: [CMCard]?
    var otherPrintings: [CMCard]?
    var otherPrintingsCollectionView: UICollectionView?
    var variations: [CMCard]?
    var variationsCollectionView: UICollectionView?
    var segmentedIndex: CardViewControllerSegmentedIndex = .image
    var cardViewIncremented = false
    
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var activityButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var favoriteTapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        segmentedIndex = CardViewControllerSegmentedIndex(rawValue: sender.selectedSegmentIndex)!
        
        guard let cards = cards else {
            return
        }
        let card = cards[cardIndex]
        
        if segmentedIndex == .image {
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
        } else if segmentedIndex == .details {
            if !cardViewIncremented {
                cardViewIncremented = true
                incrementCardViews()
            }
            
            if let printings_ = card.printings_ {
                let sets = printings_.allObjects as! [CMSet]
                var filteredSets = [CMSet]()
                let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                
                if let set = card.set {
                    filteredSets = sets.filter({ $0.code != set.code})
                }
                
                request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: true),
                                           NSSortDescriptor(key: "number", ascending: true),
                                           NSSortDescriptor(key: "mciNumber", ascending: true)]
                request.predicate = NSPredicate(format: "name = %@ AND set.code IN %@", card.name!, filteredSets.map({$0.code}))
                
                otherPrintings = try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request) as? [CMCard]
            }
            
            if let variations = card.variations_ {
                self.variations = variations.allObjects as? [CMCard]
            } else {
                variations = [CMCard]()
            }
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            
        } else if segmentedIndex == .store {
            tableView.reloadData()
            MBProgressHUD.showAdded(to: tableView, animated: true)

            firstly {
                ManaKit.sharedInstance.fetchTCGPlayerStorePricing(card: card)
            }.done {
                MBProgressHUD.hide(for: self.tableView, animated: true)
                self.tableView.reloadData()
            }.catch { error in
                
            }
        }
    }
    
    @IBAction func activityAction(_ sender: UIBarButtonItem) {
        guard let cards = cards else {
            return
        }
        
        let card = cards[cardIndex]
        
        if let _ = ManaKit.sharedInstance.cardImage(card, imageType: .normal) {
            showActivityViewController(sender, card: card)
        } else {
            MBProgressHUD.showAdded(to: view, animated: true)
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
            }.done { (image: UIImage?) in
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
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentSegmentedControl.setFAIcon(icon: .FAImage, forSegmentAtIndex: 0)
        contentSegmentedControl.setFAIcon(icon: .FAEye, forSegmentAtIndex: 1)
        contentSegmentedControl.setFAIcon(icon: .FAShoppingCart, forSegmentAtIndex: 2)
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        tableView.register(UINib(nibName: "StoreTableViewCell", bundle: nil), forCellReuseIdentifier: "StoreCell")

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCardActionRows(_:)), name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kCardViewsUpdatedNotification), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCardActionRows(_:)), name: NSNotification.Name(rawValue: kCardViewsUpdatedNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kFavoriteToggleNotification), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCardActionRows(_:)), name: NSNotification.Name(rawValue: kFavoriteToggleNotification), object: nil)
        
        guard let cards = cards else {
            return
        }
        
        let card = cards[cardIndex]
        title = card.name
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            if let dest = segue.destination as? CardViewController {
                var cards: [CMCard]?
                
                if let cell = sender as? UICollectionViewCell {
                    var parentView = cell.superview
                    while parentView is UICollectionView != true {
                        parentView = parentView?.superview
                    }
                    
                    if let parentView = parentView {
                        if parentView == otherPrintingsCollectionView {
                            if let otherPrintingsCollectionView = otherPrintingsCollectionView,
                                let otherPrintings = otherPrintings {
                                cards = [otherPrintings[otherPrintingsCollectionView.indexPath(for: cell)!.item]]
                            }
                        } else if parentView == variationsCollectionView {
                            if let variationsCollectionView = variationsCollectionView,
                                let variations = variations {
                                cards = [variations[variationsCollectionView.indexPath(for: cell)!.item]]
                            }
                        }
                    }
                } else if let dict = sender as? [String: Any]  {
                    if let card = dict["card"] as? CMCard {
                        cards = [card]
                    }
                }
                
                dest.cards = cards
                dest.cardIndex = 0
            }
        } else if segue.identifier == "showSearch" {
            if let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any] {
                
                dest.request = dict["request"] as? NSFetchRequest<NSFetchRequestResult>
                dest.title = dict["title"] as? String
            }
        } else if segue.identifier == "showSet" {
            if let dest = segue.destination as? SetViewController,
                let set = sender as? CMSet {
                
                dest.title = set.name
                dest.set = set
            }
        } else if segue.identifier == "showLogin" {
            if let dest = segue.destination as? UINavigationController {
                if let loginVC = dest.childViewControllers.first as? LoginViewController,
                    let dict = sender as? [String: Any] {
                    if let actionAfterLogin = dict["actionAfterLogin"] as? ((Bool) -> Void) {
                        loginVC.actionAfterLogin = actionAfterLogin
                    }
                }
            }
        }
    }
    
    // MARK: Custom methods
    func showActivityViewController(_ sender: UIBarButtonItem, card: CMCard) {
        let provider = CardActivityItemProvider(card)
        let activityVC = UIActivityViewController(activityItems: [provider], applicationActivities: [FacebookShareActivity(parent: self), TwitterShareActivity(parent: self)])

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
                    print("error saving meme: \(e.localizedDescription)")
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
        self.present(activityVC, animated: true, completion: nil)
    }

    func showUpdateRatingDialog() {
        if let cards = cards {
            let card = cards[cardIndex]
            var rating = Double(0)
            
            // get user's rating for this card, if there is
            for c in FirebaseManager.sharedInstance.ratedCards {
                if c.id == card.id {
                    rating = c.rating
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
                FirebaseManager.sharedInstance.updateCardRatings(card.id!, rating: ratingView.rating, firstAttempt: true)
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
    }
    
    func incrementCardViews() {
        if let cards = cards {
            let card = cards[cardIndex]
            FirebaseManager.sharedInstance.incrementCardViews(card.id!, firstAttempt: true)
        }
    }
    
    func toggleCardFavorite() {
        if let cards = cards {
            let card = cards[cardIndex]
            var isFavorite = false
            
            for c in FirebaseManager.sharedInstance.favorites {
                if c.id == card.id {
                    isFavorite = true
                    break
                }
            }
            
            MBProgressHUD.showAdded(to: view, animated: true)
            FirebaseManager.sharedInstance.toggleCardFavorite(card.id!, favorite: !isFavorite, firstAttempt: true)
        }
    }
    
    func reloadCardActionRows(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let card = userInfo["card"] as? CMCard {
                cards?[cardIndex] = card
            }
        }
        
        MBProgressHUD.hide(for: view, animated: true)
        if segmentedIndex == .image {
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.actions.rawValue)], with: .automatic)
        }
    }
    
    func showImage(ofCard card: CMCard, inImageView imageView: UIImageView) {
        if let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) {
            imageView.image = image
        } else {
            imageView.image = ManaKit.sharedInstance.cardBack(card)
            
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
            }.done { (image: UIImage?) in
                
                if let image = image {
                    UIView.transition(with: imageView,
                                      duration: 1.0,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                          imageView.image = image
                                      },
                                      completion: nil)
                }
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    func movePhotoTo(index: Int) {
        cardIndex = index
        cardViewIncremented = false
        
        if let cards = cards {
            let card = cards[cardIndex]
            title = card.name
        }
        
        if segmentedIndex == .image {
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.pricing.rawValue),
                                      IndexPath(row: 0, section: CardViewControllerImageSection.actions.rawValue)], with: .automatic)
        }
    }
    
    func handleLink(_ tapGesture: UITapGestureRecognizer) {
        // TODO: handle tap here...
        
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
}

// MARK: UITableViewDataSource
extension CardViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let cards = cards else {
            return 0
        }
        
        let card = cards[cardIndex]
        var rows = 0
        
        switch segmentedIndex {
        case .image:
            rows = 1
        case .details:
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
        case .store:
            guard let suppliers = card.suppliers else {
                return rows
            }
            rows = suppliers.count + 1
        }
        
        return rows
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 0
        
        switch segmentedIndex {
        case .image:
            sections = CardViewControllerImageSection.count
        case .details:
            sections = CardViewControllerDetailsSection.count
        case .store:
            sections = 1
        }
        
        return sections
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cards = cards else {
            return UITableViewCell(frame: CGRect.zero)
        }
        
        let card = cards[cardIndex]
        var cell: UITableViewCell?
        
        switch segmentedIndex {
        case .image:
            tableView.separatorStyle = .none
            
            switch indexPath.section {
            case CardViewControllerImageSection.pricing.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "PricingCell") {
                    if let label = c.viewWithTag(100) as? UILabel {
                        label.text = "NA"
                    }
                    if let label = c.viewWithTag(200) as? UILabel {
                        label.text = "NA"
                    }
                    if let label = c.viewWithTag(300) as? UILabel {
                        label.text = "NA"
                    }
                    if let label = c.viewWithTag(400) as? UILabel {
                        label.text = "NA"
                    }
                    
                    firstly {
                        ManaKit.sharedInstance.fetchTCGPlayerCardPricing(card: card)
                    }.done { (pricing: CMCardPricing?) in
                        if let pricing = pricing {
                            if let label = c.viewWithTag(100) as? UILabel {
                                label.text = pricing.low > 0 ? String(format: "$%.2f", pricing.low) : "NA"
                            }
                            if let label = c.viewWithTag(200) as? UILabel {
                                label.text = pricing.average > 0 ? String(format: "$%.2f", pricing.average) : "NA"
                            }
                            if let label = c.viewWithTag(300) as? UILabel {
                                label.text = pricing.high > 0 ? String(format: "$%.2f", pricing.high) : "NA"
                            }
                            if let label = c.viewWithTag(400) as? UILabel {
                                label.text = pricing.foil > 0 ? String(format: "$%.2f", pricing.foil) : "NA"
                            }
                        }
                    }.catch { error in
                        
                    }
                    
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerImageSection.image.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "CarouselCell") {
                    if let carouselView = c.viewWithTag(100) as? iCarousel {
                        carouselView.dataSource = self
                        carouselView.delegate = self
                        carouselView.type = .coverFlow2
                        carouselView.isPagingEnabled = true
                        carouselView.currentItemIndex = cardIndex
                        
                        if let imageView = carouselView.itemView(at: cardIndex) as? UIImageView {
                            showImage(ofCard: card, inImageView: imageView)
                        }
                    }
                    
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerImageSection.actions.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "ActionsCell") {
                    
                    if let ratingView = c.viewWithTag(100) as? CosmosView {
                        ratingView.didFinishTouchingCosmos = { _ in
                            self.ratingAction()
                        }
                        ratingView.rating = card.rating //Double(arc4random_uniform(5) + 1)
                        ratingView.settings.emptyBorderColor = kGlobalTintColor
                        ratingView.settings.filledBorderColor = kGlobalTintColor
                        ratingView.settings.filledColor = kGlobalTintColor
                        ratingView.settings.fillMode = .precise
                    }
                    if let label = c.viewWithTag(101) as? UILabel {
                        label.text = "\(card.ratings) Rating\(card.ratings > 1 ? "s" : "")"
                    }
                    if let label = c.viewWithTag(200) as? UILabel {
                        var isFavorite = false
                        
                        for c in FirebaseManager.sharedInstance.favorites {
                            if c.id == card.id {
                                isFavorite = true
                                break
                            }
                        }
                        if isFavorite {
                            label.setFAText(prefixText: "", icon: .FAHeart, postfixText: "", size: CGFloat(30))
                        } else {
                            label.setFAText(prefixText: "", icon: .FAHeartO, postfixText: "", size: CGFloat(30))
                        }
                        
                        if let taps = label.gestureRecognizers {
                            for tap in taps {
                                label.removeGestureRecognizer(tap)
                            }
                        }
                        label.addGestureRecognizer(favoriteTapGestureRecognizer)
                        label.textColor = kGlobalTintColor
                    }
                    if let label = c.viewWithTag(300) as? UILabel {
                        label.setFAText(prefixText: "", icon: .FAEye, postfixText: " \(card.views)", size: CGFloat(13))
                    }
                    
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
                
            default:
                ()
            }
            
        case .details:
            tableView.separatorStyle = .singleLine
            
            switch indexPath.section {
            case CardViewControllerDetailsSection.manaCost.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell") {
                    if let label = c.textLabel {
                        if let text = card.manaCost {
                            label.attributedText = MGUtilities.addSymbols(toText: "\(text))", pointSize: label.font.pointSize)
                        } else {
                            label.text = " "
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.type.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell") {
                    if let label = c.textLabel {
                        if let _ = card.type_ {
                            label.attributedText = MGUtilities.composeType(of: card, pointSize: label.font.pointSize)
                            label.adjustsFontSizeToFitWidth = true
                        } else {
                            label.text = " "
                            label.adjustsFontSizeToFitWidth = false
                        }
                        
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.oracleText.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell") {
                    if let label = c.viewWithTag(100) as? UILabel {
                        if let text = card.text {
                            label.attributedText = MGUtilities.addSymbols(toText: "\n\(text)\n", pointSize: label.font.pointSize)
                        } else {
                            label.text = " "
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.originalText.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell") {
                    if let label = c.viewWithTag(100) as? UILabel {
                        if let text = card.originalText {
                            label.attributedText = MGUtilities.addSymbols(toText: "\n\(text)\n", pointSize: label.font.pointSize)
                        } else {
                            label.text = " "
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.flavorText.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell") {
                    if let label = c.viewWithTag(100) as? UILabel {
                        if let text = card.flavor {
                            label.text = "\n\(text)\n"
                        } else {
                            label.text = " "
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.artist.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell") {
                    if let artist = card.artist_ {
                        c.textLabel?.adjustsFontSizeToFitWidth = true
                        c.textLabel?.text = artist.name
                        c.detailTextLabel?.text = "More Cards"
                    } else {
                        c.textLabel?.text = " "
                        c.detailTextLabel?.text = " "
                    }
                    c.selectionStyle = .default
                    c.accessoryType = .disclosureIndicator
                    cell = c
                }
            case CardViewControllerDetailsSection.set.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell") {
                    if let set = card.set,
                        let label = c.textLabel {
                        
                        let attributedString = NSMutableAttributedString(string: "\(ManaKit.sharedInstance.keyruneUnicode(forSet: set)!)",
                            attributes: [NSFontAttributeName: UIFont(name: "Keyrune", size: 17)!,
                                         NSForegroundColorAttributeName: ManaKit.sharedInstance.keyruneColor(forRarity: card.rarity_!)!])
                        
                        attributedString.append(NSMutableAttributedString(string: " \(set.name!)",
                            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
                        
                        label.attributedText = attributedString
                        label.adjustsFontSizeToFitWidth = true
                        c.detailTextLabel?.text = "More Cards"
                    } else {
                        c.textLabel?.text = " "
                        c.detailTextLabel?.text = " "
                    }
                    c.selectionStyle = .default
                    c.accessoryType = .disclosureIndicator
                    cell = c
                }
            case CardViewControllerDetailsSection.otherPrintings.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "ThumbnailsCell") {
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.otherNames.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell") {
                    if let label = c.textLabel {
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
                    }
                    
                    cell = c
                }
            case CardViewControllerDetailsSection.variations.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "ThumbnailsCell") {
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.rulings.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell") {
                    if let rulings_ = card.rulings_,
                        let label = c.viewWithTag(100) as? UILabel {
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
                        var contents = ""
                        
                        if array.count > 0 {
                            let ruling = array[indexPath.row]
                            
                            if let date = ruling.date {
                                contents.append(date)
                            }
                            if let text = ruling.text {
                                if contents.count > 0 {
                                    contents.append("\n\n")
                                }
                                contents.append(text)
                            }
                        } else {
                            contents = " "
                        }
                        
                        label.attributedText = MGUtilities.addSymbols(toText: contents, pointSize: label.font.pointSize)
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.legalities.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell") {
                    if let cardLegalities_ = card.cardLegalities_ {
                        let array = cardLegalities_.allObjects as! [CMCardLegality]
                        
                        if array.count > 0 {
                            let cardLegality = array[indexPath.row]
                            c.textLabel?.text = cardLegality.format!.name
                            c.detailTextLabel?.text = cardLegality.legality!.name
                        } else {
                            c.textLabel?.text = " "
                            c.detailTextLabel?.text = " "
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.otherDetails.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell") {
                    if let label = c.viewWithTag(100) as? UILabel {
                        label.attributedText = MGUtilities.composeOtherDetails(forCard: card)
                    }
                    
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            default:
                ()
            }
        case .store:
            guard let suppliers = card.suppliers else {
                return UITableViewCell(frame: CGRect.zero)
            }
            let count = suppliers.allObjects.count
            
            if count == 0 {
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell") {
                    if let label = c.viewWithTag(100) as? UILabel {
                        guard let note = card.storePricingNote else {
                            return UITableViewCell(frame: CGRect.zero)
                        }
                        label.attributedText = MGUtilities.convertToHtml(note)
                        label.isUserInteractionEnabled = true
                        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLink(_:))))
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            } else {
                if indexPath.row <= count - 1 {
                    if let c = tableView.dequeueReusableCell(withIdentifier: "StoreCell") as? StoreTableViewCell {
                        if let suppliers = card.suppliers {
                            if let supplier = suppliers.allObjects[indexPath.row] as? CMSupplier {
                                c.delegate = self
                                c.display(supplier)
                            }
                        }
                        c.selectionStyle = .none
                        c.accessoryType = .none
                        cell = c
                    }
                } else {
                    if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell") {
                        if let label = c.viewWithTag(100) as? UILabel {
                            guard let note = card.storePricingNote else {
                                return UITableViewCell(frame: CGRect.zero)
                            }
                            label.attributedText = MGUtilities.convertToHtml(note)
                            label.isUserInteractionEnabled = true
                            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLink(_:))))
                        }
                        c.selectionStyle = .none
                        c.accessoryType = .none
                        cell = c
                    }
                }
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let cards = cards else {
            return nil
        }
        
        let card = cards[cardIndex]
        var headerTitle: String?
        
        switch segmentedIndex {
        case .details:
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
            case CardViewControllerDetailsSection.otherPrintings.rawValue:
                headerTitle = CardViewControllerDetailsSection.otherPrintings.description
                var count = 0
                
                if let otherPrintings = otherPrintings {
                    count = otherPrintings.count
                }
                headerTitle?.append(": \(count)")
            case CardViewControllerDetailsSection.otherNames.rawValue:
                headerTitle = CardViewControllerDetailsSection.otherNames.description
                var count = 0
                
                if let names_ = card.names_ {
                    if let array = names_.allObjects as? [CMCard] {
                        count = array.filter({ $0.name != card.name}).count
                        
                    }
                }
                headerTitle?.append(": \(count)")
            case CardViewControllerDetailsSection.variations.rawValue:
                headerTitle = CardViewControllerDetailsSection.variations.description
                var count = 0
                
                if let variations = variations {
                    count = variations.count
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
        switch segmentedIndex {
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.otherPrintings.rawValue:
                if let collectionView = cell.viewWithTag(100) as? UICollectionView{
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
                }
            case CardViewControllerDetailsSection.variations.rawValue:
                if let collectionView = cell.viewWithTag(100) as? UICollectionView {
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
                }
            default:
                ()
            }
        default:
            ()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cards = cards else {
            return CGFloat(0)
        }
        
        let card = cards[cardIndex]
        var height = CGFloat(0)
        
        switch segmentedIndex {
        case .image:
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
            
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.otherPrintings.rawValue,
                 CardViewControllerDetailsSection.variations.rawValue:
                height = CGFloat(88)
            default:
                height = UITableViewAutomaticDimension
            }
        case .store:
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
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let cards = cards else {
            return nil
        }
        let card = cards[cardIndex]
        var path: IndexPath?
        
        switch segmentedIndex {
        case .details:
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
        /*case .store:
            guard let suppliers = card.suppliers else {
                return nil
            }
            let count = suppliers.allObjects.count
            
            if count == 0 {
                path = indexPath
            } else {
                if indexPath.row <= count - 1 {
                    return nil
                } else {
                    path = indexPath
                }
            }*/
        default:
            ()
        }
            
        return path
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cards = cards else {
            return
        }
        let card = cards[cardIndex]
        
        switch segmentedIndex {
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.artist.rawValue:
                if let artist = card.artist_ {
                    let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                    let predicate = NSPredicate(format: "artist_.name = %@", artist.name!)
                    
                    request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                               NSSortDescriptor(key: "name", ascending: true),
                                               NSSortDescriptor(key: "set.releaseDate", ascending: true)]
                    request.predicate = predicate
                    
                    performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                                        "title": artist.name!])
                }
            case CardViewControllerDetailsSection.set.rawValue:
                if let set = card.set {
                    performSegue(withIdentifier: "showSet", sender: set)
                }
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
                
                if let otherCard = otherCard {
                    performSegue(withIdentifier: "showCard", sender: ["card": otherCard])
                }
            default:
                ()
            }
        /*case .store:
            guard let suppliers = card.suppliers else {
                return
            }
            guard let note = card.storePricingNote else {
                return
            }
            let count = suppliers.allObjects.count
            
            if count == 0 {
                
            } else {
                if indexPath.row <= count - 1 {
                    return
                } else {
                    
                }
            }*/
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
            if let otherPrintings = otherPrintings {
                items = otherPrintings.count
            }
        } else if collectionView == variationsCollectionView {
            if let variations = variations {
                items = variations.count
            }
        }

        return items
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailItemCell", for: indexPath)
        var card: CMCard?
        
        if collectionView == otherPrintingsCollectionView {
            if let otherPrintings = otherPrintings {
                card = otherPrintings[indexPath.row]
            }
        } else if collectionView == variationsCollectionView {
            if let variations = variations {
                card = variations[indexPath.row]
            }
        }
        
        if let card = card,
            let thumbnailImage = cell.viewWithTag(100) as? UIImageView,
            let setImage = cell.viewWithTag(200) as? UILabel {
            
            if let croppedImage = ManaKit.sharedInstance.croppedImage(card) {
                thumbnailImage.image = croppedImage
            } else {
                thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cropBack)
                
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
            
            setImage.layer.cornerRadius = setImage.frame.height / 2
            setImage.text = ManaKit.sharedInstance.keyruneUnicode(forSet: card.set!)
            setImage.textColor = ManaKit.sharedInstance.keyruneColor(forRarity: card.rarity_!)
        }
        
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
        var items = 0
        
        if let cards = cards {
            items = cards.count
        }
        return items
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var imageView: UIImageView?
        
        //reuse view if available, otherwise create a new view
        if let v = view as? UIImageView {
            imageView = v
            
        } else {
            let height = tableView.frame.size.height - 88
            let width = tableView.frame.size.width - 40
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            imageView!.contentMode = .scaleAspectFit

            // add drop shadow
            imageView!.layer.shadowColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.45).cgColor
            imageView!.layer.shadowOffset = CGSize(width: 1, height: 1)
            imageView!.layer.shadowOpacity = 1
            imageView!.layer.shadowRadius = 6.0
            imageView!.clipsToBounds = false
        }
        
        if let imageView = imageView,
            let cards = cards {
            let card = cards[index]
            showImage(ofCard: card, inImageView: imageView)
        }
        
        return imageView!
    }
}

// MARK: iCarouselDelegate
extension CardViewController : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        movePhotoTo(index: carousel.currentItemIndex)
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        guard let cards = cards else {
            return
        }
        
        var photos = [ManaGuidePhoto]()
        
        for card in cards {
            photos.append(ManaGuidePhoto(card: card))
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
