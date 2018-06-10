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
import Firebase
import Font_Awesome_Swift
import iCarousel
import IDMPhotoBrowser
import ManaKit
import MBProgressHUD
import PromiseKit

enum CardViewControllerSegmentedIndex: Int {
    case image
    case details
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .image: return "Image"
        case .details: return "Details"
        }
    }
    
    static var count: Int {
        return 2
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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var favoriteTapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        segmentedIndex = CardViewControllerSegmentedIndex(rawValue: sender.selectedSegmentIndex)!
        
        if segmentedIndex == .details {
            if !cardViewIncremented {
                cardViewIncremented = true
                incrementCardViews()
            }
            
            if let cards = cards {
                let card = cards[cardIndex]
            
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
            }
        }
        
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
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
    
    func ratingAction(rating: Double) {
        if let _ = Auth.auth().currentUser {
            update(rating: rating)
        } else {
            let actionAfterLogin = {(success: Bool) in
                if success {
                    self.update(rating: rating)
                } else {
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.actions.rawValue)], with: .automatic)
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
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kCardViewUpdatedNotification), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateCardViews(_:)), name: NSNotification.Name(rawValue: kCardViewUpdatedNotification), object: nil)
        
        if let cards = cards {
            let card = cards[cardIndex]
            title = card.name
        }
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
    func incrementCardViews() {
        if let cards = cards {
            let card = cards[cardIndex]
            FirebaseManager.sharedInstance.incrementCardViews(card.id!)
        }
    }
    
    func updateCardViews(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            
            if let card = userInfo["card"] as? CMCard {
                cards?[cardIndex] = card
            }
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
            FirebaseManager.sharedInstance.toggleCardFavorite(card.id!, favorite: !isFavorite, completion: {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.actions.rawValue)], with: .automatic)
            })
        }
    }
    
    func update(rating: Double) {
        
        
        let alertController = UIAlertController(title: "Rate this Card", message: nil, preferredStyle: .alert)
        let cosmosView = CosmosView(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        let confirmAction = UIAlertAction(title: "Submit", style: .default) { (_) in }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.view.addSubview(cosmosView)
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        
//        tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.actions.rawValue)], with: .automatic)
    }
    
    func composeType(of card: CMCard, pointSize: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        var cardType: CMCardType?
        var image: UIImage?
        var text:String?
        
        if let types = card.types_ {
            if types.count > 1 {
                image = ManaKit.sharedInstance.symbolImage(name: "Multiple")
                cardType = types.allObjects.first as? CMCardType
                
                for t in types.allObjects {
                    if let t = t as? CMCardType {
                        if t.name == "Creature" {
                            cardType = t
                        }
                    }
                }
            } else {
                if let type = types.allObjects.first as? CMCardType {
                    cardType = type
                }
            }
        }
        
        if let cardType = cardType {
            if let name = cardType.name {
                image = ManaKit.sharedInstance.symbolImage(name: name)
            }
        }

        // type
        if let type = card.type_,
            let cardType = cardType {
            
            text = " "
            if let name = type.name {
                text!.append(name)
            }
            if let name = cardType.name {
                if name == "Creature" {
                    if let power = card.power,
                        let toughness = card.toughness {
                        text!.append(" (\(power)/\(toughness))")
                    }
                }
            }
        }
        
        
        if let image = image,
            let text = text {
            
            let imageAttachment =  NSTextAttachment()
            imageAttachment.image = image
            
            let ratio = image.size.width / image.size.height
            let height = CGFloat(17)
            let width = ratio * height
            var imageOffsetY = CGFloat(0)
            
            if height > pointSize {
                imageOffsetY = -(height - pointSize) / 2.0
            } else {
                imageOffsetY = -(pointSize - height) / 2.0
            }
            
            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: width, height: height)
            
            let attachmentString = NSAttributedString(attachment: imageAttachment)
            attributedString.append(attachmentString)
            attributedString.append(NSAttributedString(string: text))
        }
        
        return attributedString
    }
    
    func addSymbols(toText text: String?, withPointSize pointSize: CGFloat) -> NSAttributedString {
        let newText = NSMutableAttributedString()
        
        if let text = text {
            var fragmentText = NSMutableString()
            var offset = 0
            
            repeat {
                for i in offset...text.count - 1 {
                    let c = text[text.index(text.startIndex, offsetBy: i)]
                    
                    if c == "{" {
                        let symbol = NSMutableString()
                        
                        for j in i...text.count - 1 {
                            let cc = text[text.index(text.startIndex, offsetBy: j)]
                            
                            if cc == "}" {
                                offset = j + 1
                                break
                            } else {
                                symbol.append(String(cc))
                            }
                        }
                        
                        let cleanSymbol = symbol.replacingOccurrences(of: "{", with: "")
                            .replacingOccurrences(of: "}", with: "")
                            .replacingOccurrences(of: "/", with: "")
                        
                        if let image = ManaKit.sharedInstance.symbolImage(name: cleanSymbol as String) {
                            let imageAttachment =  NSTextAttachment()
                            imageAttachment.image = image
                            
                            var width = CGFloat(16)
                            let height = CGFloat(16)
                            var imageOffsetY = CGFloat(0)
                            
                            if cleanSymbol == "100" {
                                width = 35
                            } else if symbol == "1000000" {
                                width = 60
                            }
                            
                            if height > pointSize {
                                imageOffsetY = -(height - pointSize) / 2.0
                            } else {
                                imageOffsetY = -(pointSize - height) / 2.0
                            }
                            
                            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: width, height: height)
                            
                            let attachmentString = NSAttributedString(attachment: imageAttachment)
                            let attributedString = NSMutableAttributedString(string: fragmentText as String)
                            attributedString.append(attachmentString)
                            
                            newText.append(attributedString)
                            fragmentText = NSMutableString()
                            break
                        }
                        
                    } else {
                        fragmentText.append(String(c))
                        offset = i
                    }
                    
                }
            } while offset != text.count - 1
        
            let attributedString = NSMutableAttributedString(string: fragmentText as String)
            newText.append(attributedString)
        }
        
        return newText
    }
    
    func composeOtherDetails(forCard card: CMCard) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .left
        
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                          NSParagraphStyleAttributeName: titleParagraphStyle]
        
        var text = "Layout: "
        if let layout = card.layout {
            text.append(layout)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nConverted Mana Cost: "
        text.append("\(String(format: card.cmc == floor(card.cmc) ? "%.0f" : "%.1f", card.cmc))")
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nColors: "
        if let colors_ = card.colors_ {
            if let s = colors_.allObjects as? [CMColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nColors Identity: "
        if let colorIdentities_ = card.colorIdentities_ {
            if let s = colorIdentities_.allObjects as? [CMColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nOriginal Type: "
        if let originalType = card.originalType {
            text.append(originalType)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nSubtypes: "
        if let subtypes_ = card.subtypes_ {
            if let s = subtypes_.allObjects as? [CMCardType] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nSupertypes: "
        if let supertypes_ = card.supertypes_ {
            if let s = supertypes_.allObjects as? [CMCardType] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                text.append(string.count > 0 ? string : "\u{2014}")
            } else {
                text.append("\u{2014}")
            }
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nRarity: "
        if let rarity = card.rarity_ {
            text.append(rarity.name!)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nSet Online Only: "
        if let set = card.set {
            text.append(set.onlineOnly ? "Yes" : "No")
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nReserved List: "
        text.append(card.reserved ? "Yes" : "No")
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nRelease Date: "
        if let releaseDate = card.releaseDate ?? card.set!.releaseDate {
            text.append(releaseDate)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nSource: "
        if let source = card.source {
            text.append(source)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        text = "\nNumber: "
        if let number = card.number ?? card.mciNumber {
            text.append(number)
        } else {
            text.append("\u{2014}")
        }
        attributedString.append(NSMutableAttributedString(string: text, attributes: attributes))
        
        return attributedString
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
}

// MARK: UITableViewDataSource
extension CardViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        
        switch segmentedIndex {
        case .image:
            rows = 1
        case .details:
            switch section {
            case CardViewControllerDetailsSection.otherNames.rawValue:
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let names_ = card.names_ {
                        if let array = names_.allObjects as? [CMCard] {
                            rows = array.filter({ $0.name != card.name}).count
                        }
                    }
                    if rows == 0 {
                        rows = 1
                    }
                }
            case CardViewControllerDetailsSection.rulings.rawValue:
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let rulings_ = card.rulings_ {
                        rows = rulings_.allObjects.count >= 1 ? rulings_.allObjects.count : 1
                    }
                }
            case CardViewControllerDetailsSection.legalities.rawValue:
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let cardLegalities_ = card.cardLegalities_ {
                        rows = cardLegalities_.allObjects.count >= 1 ? cardLegalities_.allObjects.count : 1
                    }
                }
            default:
                rows = 1
            }
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
        }
        
        return sections
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        switch segmentedIndex {
        case .image:
            tableView.separatorStyle = .none
            
            switch indexPath.section {
            case CardViewControllerImageSection.pricing.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "PricingCell"),
                    let cards = cards {
                    let card = cards[cardIndex]
                    
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
                        ManaKit.sharedInstance.fetchTCGPlayerPricing(card: card)
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
                        
                        if let imageView = carouselView.itemView(at: cardIndex) as? UIImageView,
                            let cards = cards {
                            let card = cards[cardIndex]
                            showImage(ofCard: card, inImageView: imageView)
                        }
                    }
                    
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerImageSection.actions.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "ActionsCell"),
                    let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let ratingView = c.viewWithTag(100) as? CosmosView {
                        ratingView.rating = card.rating //Double(arc4random_uniform(5) + 1)
                        ratingView.didFinishTouchingCosmos = { rating in
                            self.ratingAction(rating: rating)
                        }
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
                if let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
                    if let label = c.textLabel {
                        if let text = card.manaCost {
                            label.attributedText = addSymbols(toText: "\(text) (CMC \(Int(card.cmc)))", withPointSize: label.font.pointSize)
                        } else {
                            label.text = " "
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.type.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let label = c.textLabel {
                        if let _ = card.type_ {
                            label.attributedText = composeType(of: card, pointSize: label.font.pointSize)
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
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
                    if let label = c.viewWithTag(100) as? UILabel {
                        if let text = card.text {
                            label.attributedText = addSymbols(toText: "\n\(text)\n", withPointSize: label.font.pointSize)
                        } else {
                            label.text = " "
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.originalText.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
                    if let label = c.viewWithTag(100) as? UILabel {
                        if let text = card.originalText {
                            label.attributedText = addSymbols(toText: "\n\(text)\n", withPointSize: label.font.pointSize)
                        } else {
                            label.text = " "
                        }
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.flavorText.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
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
                if let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
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
                if let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
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
                if let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
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
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
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
                        
                        label.attributedText = addSymbols(toText: contents, withPointSize: label.font.pointSize)//contents
                    }
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.legalities.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
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
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
                    if let label = c.viewWithTag(100) as? UILabel {
                        label.attributedText = composeOtherDetails(forCard: card)
                    }
                    
                    c.selectionStyle = .none
                    c.accessoryType = .none
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
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    if let names_ = card.names_ {
                        if let array = names_.allObjects as? [CMCard] {
                            count = array.filter({ $0.name != card.name}).count
                            
                        }
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
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let rulings_ = card.rulings_ {
                        count = rulings_.count
                    }
                }
                headerTitle?.append(": \(count)")
            case CardViewControllerDetailsSection.legalities.rawValue:
                headerTitle = CardViewControllerDetailsSection.legalities.description
                var count = 0
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let cardLegalities_ = card.cardLegalities_ {
                        count = cardLegalities_.count
                    }
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
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        var path: IndexPath?
        
        switch segmentedIndex {
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.artist.rawValue,
                 CardViewControllerDetailsSection.set.rawValue:
                path = indexPath
            case CardViewControllerDetailsSection.otherNames.rawValue:
                if let cards = cards {
                    let card = cards[cardIndex]
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
        switch segmentedIndex {
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.artist.rawValue:
                if let cards = cards  {
                    let card = cards[cardIndex]
                    
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
                }
            case CardViewControllerDetailsSection.set.rawValue:
                if let cards = cards  {
                    let card = cards[cardIndex]
                    
                    if let set = card.set {
                        performSegue(withIdentifier: "showSet", sender: set)
                    }
                }
            case CardViewControllerDetailsSection.otherNames.rawValue:
                if let cards = cards  {
                    let card = cards[cardIndex]
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
                }
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
        if let cards = cards {
            var photos = [ManaGuidePhoto]()
            
            for card in cards {
                photos.append(ManaGuidePhoto(card: card))
            }
            
            if let browser = IDMPhotoBrowser(photos: photos) {
                browser.setInitialPageIndex(UInt(index))

//                browser.useWhiteBackgroundColor = true
                browser.displayActionButton = true
                browser.displayArrowButton = true
                browser.displayCounterLabel = true
                browser.usePopAnimation = true
                browser.forceHideStatusBar = true
                browser.delegate = self
                
                browser.leftArrowImage = UIImage(bgIcon: .FAArrowLeft, orientation: .up, bgTextColor: UIColor.black, bgBackgroundColor: UIColor.clear, topIcon: .FAArrowLeft, topTextColor: UIColor.black, bgLarge: true, size: CGSize(width: 30, height: 30))
                browser.rightArrowImage = UIImage(bgIcon: .FAArrowRight, orientation: .up, bgTextColor: UIColor.black, bgBackgroundColor: UIColor.clear, topIcon: .FAArrowRight, topTextColor: UIColor.black, bgLarge: true, size: CGSize(width: 30, height: 30))
//                browser.leftArrowSelectedImage = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowLeftSelected.png"];
//                browser.rightArrowSelectedImage = [UIImage imageNamed:@"IDMPhotoBrowser_customArrowRightSelected.png"];
                browser.doneButtonImage = UIImage(bgIcon: .FAWindowClose, orientation: .up, bgTextColor: UIColor.black, bgBackgroundColor: UIColor.clear, topIcon: .FAWindowClose, topTextColor: UIColor.black, bgLarge: true, size: CGSize(width: 30, height: 30))
                
                present(browser, animated: true, completion: nil)
            }
        }
    }
}

// MARK: IDMPhotoBrowserDelegate
extension CardViewController : IDMPhotoBrowserDelegate {
//    func photoBrowser(_ photoBrowser: IDMPhotoBrowser,  didShowPhotoAt index: UInt) {
//        
//        // pre-download the next image
//        if let cards = cards {
//            if index < cards.count - 1 {
//                let card = cards[Int(index + 1)]
//
//                firstly {
//                    ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
//                }.catch { error in
//                    print("\(error)")
//                }
//            }
//        }
//    }
    
    func photoBrowser(_ photoBrowser: IDMPhotoBrowser, willDismissAtPageIndex index: UInt) {
        let i = Int(index)
        
        if i != cardIndex {
            movePhotoTo(index: i)
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.image.rawValue)], with: .none)
        }
    }
}
