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
import Font_Awesome_Swift
import iCarousel
import ManaKit

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
    case ratingAndViews
    
    static var count: Int {
        return 3
    }
}

enum CardViewControllerDetailsSection : Int {
    case manaCost
    case type
    case originalText
    case oracleText
    case flavorText
    case artist
    case set
    case printings
    case rulings
    case legalities
    case details
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .manaCost: return "Mana Cost"
        case .type: return "Type"
        case .originalText: return "Original Text"
        case .oracleText: return "Oracle Text"
        case .flavorText: return "Flavor Text"
        case .artist: return "Artist"
        case .set: return "Set"
        case .printings: return "Printings"
        case .rulings: return "Rulings"
        case .legalities: return "Legalities"
        case .details: return "Details"
        }
    }
    
    static var count: Int {
        return 11
    }
}

class CardViewController: BaseViewController {
    // MARK: Variables
    var cardIndex = 0
    var cards: [CMCard]?
    var variations: [CMCard]?
    var printings: [CMCard]?
    var printingsCollectionView: UICollectionView?
    var segmentedIndex: CardViewControllerSegmentedIndex = .image
    var webViewSize: CGSize?
    var cardViewIncremented = false
    
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        segmentedIndex = CardViewControllerSegmentedIndex(rawValue: sender.selectedSegmentIndex)!
        
        if segmentedIndex == .image {
            webViewSize = nil
        } else if segmentedIndex == .details {
            if !cardViewIncremented {
                cardViewIncremented = true
                incrementCardViews()
            }
        }
        
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
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
            if let dest = segue.destination as? CardViewController,
                let cell = sender as? UICollectionViewCell {
                
                var parentView = cell.superview
                while parentView is UICollectionView != true {
                    parentView = parentView?.superview
                }
                
                if let parentView = parentView {
                    if let printingsCollectionView = printingsCollectionView,
                        let printings = printings {
                        if parentView == printingsCollectionView {
                            dest.cards = [printings[printingsCollectionView.indexPath(for: cell)!.item]]
                        }
                    }
                }
                
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
    
    func replaceSymbols(inText text: String) -> String {
        var newText = text
        newText = newText.replacingOccurrences(of: "\n", with:"<br/> ")
        newText = newText.replacingOccurrences(of: "(", with:"(<i>")
        newText = newText.replacingOccurrences(of:")", with:"</i>)")
        
        for (_,v) in Symbols {
            if let imgLink = ManaKit.sharedInstance.symbolHTML(name: v) {
                newText = newText.replacingOccurrences(of: v, with: imgLink)
            }
        }
        
        return newText
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
    
    func composeHTMLInformation(forCard card: CMCard) -> String {
        var html = try! String(contentsOfFile: "\(Bundle.main.bundlePath)/data/web/cardtext.html", encoding: String.Encoding.utf8)
        var css = try! String(contentsOfFile: "\(Bundle.main.bundlePath)/data/web/style.css", encoding: String.Encoding.utf8)
        
        let bundle = Bundle(for: ManaKit.self)
        if let bundleURL = bundle.resourceURL?.appendingPathComponent("ManaKit.bundle") {
            css = css.replacingOccurrences(of: "fonts/", with: "\(bundleURL.path)/fonts/")
            css = css.replacingOccurrences(of: "images/", with: "\(bundleURL.path)/images/")
            html = html.replacingOccurrences(of: "{{css}}", with: css)
            html = html.replacingOccurrences(of: "{{keyruneCss}}", with: "\(bundleURL.path)/css/keyrune.min.css")
        }
        
        html = html.replacingOccurrences(of: "{{cmc}}", with: String(format: card.cmc == floor(card.cmc) ? "%.0f" : "%.1f", card.cmc))
        
        if let colors_ = card.colors_ {
            if let s = colors_.allObjects as? [CMColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                html = html.replacingOccurrences(of: "{{colors}}", with: string.count > 0 ? string : "&mdash;")
            } else {
                html = html.replacingOccurrences(of: "{{colors}}", with: "&mdash;")
            }
        } else {
            html = html.replacingOccurrences(of: "{{colors}}", with: "&mdash;")
        }
        
        if let colorIdentities_ = card.colorIdentities_ {
            if let s = colorIdentities_.allObjects as? [CMColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                html = html.replacingOccurrences(of: "{{colorIdentities}}", with: string.count > 0 ? string : "&mdash;")
            } else {
                html = html.replacingOccurrences(of: "{{colorIdentities}}", with: "&mdash;")
            }
        } else {
            html = html.replacingOccurrences(of: "{{subtypes}}", with: "&mdash;")
        }
        
        if let originalType = card.originalType {
            html = html.replacingOccurrences(of: "{{originalType}}", with: originalType)
        } else {
            html = html.replacingOccurrences(of: "{{originalType}}", with: "&mdash;")
        }

        if let subtypes_ = card.subtypes_ {
            if let s = subtypes_.allObjects as? [CMCardType] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                html = html.replacingOccurrences(of: "{{subtypes}}", with: string.count > 0 ? string : "&mdash;")
            } else {
                html = html.replacingOccurrences(of: "{{subtypes}}", with: "&mdash;")
            }
        } else {
            html = html.replacingOccurrences(of: "{{subtypes}}", with: "&mdash;")
        }
        
        if let supertypes_ = card.supertypes_ {
            if let s = supertypes_.allObjects as? [CMCardType] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                html = html.replacingOccurrences(of: "{{supertypes}}", with: string.count > 0 ? string : "&mdash;")
            } else {
                html = html.replacingOccurrences(of: "{{supertypes}}", with: "&mdash;")
            }
        } else {
            html = html.replacingOccurrences(of: "{{supertypes}}", with: "&mdash;")
        }
        
        if let rarity = card.rarity_ {
            let keyruneRarity = (rarity.name! == "Mythic Rare" || rarity.name! == "Special") ? "mythic" : rarity.name!.lowercased()
            html = html.replacingOccurrences(of: "{{rarity}}", with: rarity.name!)
            html = html.replacingOccurrences(of: "{{setRarity}}", with: keyruneRarity)
        } else {
            html = html.replacingOccurrences(of: "{{rarity}}", with: "&mdash;")
        }
        
        if let set = card.set {
            html = html.replacingOccurrences(of: "{{setOnlineOnly}}", with: set.onlineOnly ? "Yes" : "No")
        } else {
            html = html.replacingOccurrences(of: "{{setOnlineOnly}}", with: "&mdash;")
        }
        
        html = html.replacingOccurrences(of: "{{reserved}}", with: card.reserved ? "Yes" : "No")
        
        if let releaseDate = card.releaseDate ?? card.set!.releaseDate {
            html = html.replacingOccurrences(of: "{{releaseDate}}", with: releaseDate)
        } else {
            html = html.replacingOccurrences(of: "{{releaseDate}}", with: "&mdash;")
        }
        
        if let source = card.source {
            html = html.replacingOccurrences(of: "{{source}}", with: source)
        } else {
            html = html.replacingOccurrences(of: "{{source}}", with: "&mdash;")
        }
        
        if let number = card.number ?? card.mciNumber {
            html = html.replacingOccurrences(of: "{{number}}", with: number)
        } else {
            html = html.replacingOccurrences(of: "{{number}}", with: "&mdash;")
        }
        
        return html
    }
    
    func showImage(ofCard card: CMCard, inImageView imageView: UIImageView) {
        if let image = ManaKit.sharedInstance.cardImage(card) {
            imageView.image = image
        } else {
            imageView.image = ManaKit.sharedInstance.cardBack(card)
            
            ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: Error?) in
                
                if error == nil {
                    if c.id == card.id {
                        UIView.transition(with: imageView,
                                          duration: 1.0,
                                          options: .transitionCrossDissolve,
                                          animations: {
                                            imageView.image = image
                        },
                                          completion: nil)
                    }
                }
            })
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
                    
                    ManaKit.sharedInstance.fetchTCGPlayerPricing(card: card, completion: {(cardPricing: CMCardPricing?, error: Error?) in
                        if let cardPricing = cardPricing {
                            
                            if card.id == cardPricing.card?.id {
                                if let label = c.viewWithTag(100) as? UILabel {
                                    label.text = cardPricing.low > 0 ? String(format: "$%.2f", cardPricing.low) : "NA"
                                }
                                if let label = c.viewWithTag(200) as? UILabel {
                                    label.text = cardPricing.average > 0 ? String(format: "$%.2f", cardPricing.average) : "NA"
                                }
                                if let label = c.viewWithTag(300) as? UILabel {
                                    label.text = cardPricing.high > 0 ? String(format: "$%.2f", cardPricing.high) : "NA"
                                }
                                if let label = c.viewWithTag(400) as? UILabel {
                                    label.text = cardPricing.foil > 0 ? String(format: "$%.2f", cardPricing.foil) : "NA"
                                }
                            }
                        }
                    })
                    
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
            case CardViewControllerImageSection.ratingAndViews.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "RatingAndViewsCell"),
                    let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let ratingView = c.viewWithTag(100) as? CosmosView {
                        ratingView.rating = Double(arc4random_uniform(5) + 1); //card.rating
                    }
                    if let label = c.viewWithTag(200) as? UILabel {
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
            case CardViewControllerDetailsSection.printings.rawValue:
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
            case CardViewControllerDetailsSection.details.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "WebViewCell") {
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
            case CardViewControllerDetailsSection.originalText.rawValue:
                headerTitle = CardViewControllerDetailsSection.originalText.description
            case CardViewControllerDetailsSection.oracleText.rawValue:
                headerTitle = CardViewControllerDetailsSection.oracleText.description
            case CardViewControllerDetailsSection.flavorText.rawValue:
                headerTitle = CardViewControllerDetailsSection.flavorText.description
            case CardViewControllerDetailsSection.artist.rawValue:
                headerTitle = CardViewControllerDetailsSection.artist.description
            case CardViewControllerDetailsSection.set.rawValue:
                headerTitle = CardViewControllerDetailsSection.set.description
            case CardViewControllerDetailsSection.printings.rawValue:
                headerTitle = CardViewControllerDetailsSection.printings.description
                
                if let printings = printings {
                    headerTitle?.append(": \(printings.count)")
                }
            case CardViewControllerDetailsSection.rulings.rawValue:
                headerTitle = CardViewControllerDetailsSection.rulings.description
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let rulings_ = card.rulings_ {
                        headerTitle?.append(": \(rulings_.count)")
                    }
                }
            
            case CardViewControllerDetailsSection.legalities.rawValue:
                headerTitle = CardViewControllerDetailsSection.legalities.description
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let cardLegalities_ = card.cardLegalities_ {
                        headerTitle?.append(": \(cardLegalities_.count)")
                    }
                }
            case CardViewControllerDetailsSection.details.rawValue:
                headerTitle = CardViewControllerDetailsSection.details.description
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
            case CardViewControllerDetailsSection.printings.rawValue:
                if let collectionView = cell.viewWithTag(100) as? UICollectionView,
                    let cards = cards  {
                    let card = cards[cardIndex]
                    
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        let width = CGFloat(100)
                        let height = CGFloat(72)
                        flowLayout.itemSize = CGSize(width: width, height: height)
                        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                    }
                    
                    collectionView.dataSource = self
                    collectionView.delegate = self
                    
                    printingsCollectionView = collectionView
                    
                    if let printings_ = card.printings_ {
                        let array = printings_.allObjects as! [CMSet]
                        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
                        request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: true),
                                                   NSSortDescriptor(key: "number", ascending: true),
                                                   NSSortDescriptor(key: "mciNumber", ascending: true)]
                        request.predicate = NSPredicate(format: "name = %@ AND set.code IN %@", card.name!, array.map({$0.code}))
                        
                        printings = try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request) as? [CMCard]
                    }
                    collectionView.reloadData()
                }
            case CardViewControllerDetailsSection.details.rawValue:
                if let webView = cell.viewWithTag(100) as? UIWebView,
                    let cards = cards {
                    
                    if webViewSize == nil {
                        let card = cards[cardIndex]
                        let html = composeHTMLInformation(forCard: card)
                        
                        webView.delegate = self
                        webView.scrollView.isScrollEnabled = false
                        webView.scrollView.bounces = false
                        webView.loadHTMLString(html, baseURL: URL(fileURLWithPath: "\(Bundle.main.bundlePath)/data/web"))
                    }
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
            case CardViewControllerImageSection.ratingAndViews.rawValue:
                height = 44
            default:
                ()
            }
            
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.printings.rawValue:
                height = CGFloat(88)
            case CardViewControllerDetailsSection.details.rawValue:
                if let webViewSize = webViewSize {
                    height = webViewSize.height
                } else {
                    height = CGFloat(88)
                }
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
        switch segmentedIndex {
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.artist.rawValue,
                 CardViewControllerDetailsSection.set.rawValue:
                return indexPath
                
            default:
                return nil
            }
        default:
            return nil
        }
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
        
        if let printings = printings {
            items = printings.count
        }

        return items
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailItemCell", for: indexPath)
            
        if let printings = printings,
            let thumbnailImage = cell.viewWithTag(100) as? UIImageView,
            let setImage = cell.viewWithTag(200) as? UILabel {
            let printing = printings[indexPath.row]
            
            if let croppedImage = ManaKit.sharedInstance.croppedImage(printing) {
                thumbnailImage.image = croppedImage
            } else {
                thumbnailImage.image = ManaKit.sharedInstance.imageFromFramework(imageName: .cropBack)
                
                ManaKit.sharedInstance.downloadCardImage(printing, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: Error?) in
                    if error == nil {
                        if c.id == printing.id {
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
            
            setImage.layer.cornerRadius = setImage.frame.height / 2
            setImage.text = ManaKit.sharedInstance.keyruneUnicode(forSet: printing.set!)
            setImage.textColor = ManaKit.sharedInstance.keyruneColor(forRarity: printing.rarity_!)
        }
        
        return cell
    }
}

// UICollectionViewDelegate
extension CardViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == printingsCollectionView {
            if let thumbnailImage = cell.viewWithTag(100) as? UIImageView {
                thumbnailImage.layer.cornerRadius = 10
                thumbnailImage.layer.masksToBounds = true
            }
        }
    }
}

// MARK: UIWebViewDelegate
extension CardViewController : UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webViewSize = webView.scrollView.contentSize
        tableView.reloadData()
    }
}

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
        }
        
        if let imageView = imageView,
            let cards = cards {
            let card = cards[index]
            showImage(ofCard: card, inImageView: imageView)
        }
        
        return imageView!
    }
}

extension CardViewController : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        cardIndex = carousel.currentItemIndex
        cardViewIncremented = false
        
        if let cards = cards {
            let card = cards[cardIndex]
            title = card.name
        }
        
        if segmentedIndex == .image {
            tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerImageSection.pricing.rawValue),
                                      IndexPath(row: 0, section: CardViewControllerImageSection.ratingAndViews.rawValue)], with: .automatic)
        }
    }
}

