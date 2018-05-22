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

enum CardViewControllerDetailsSection : Int {
    case information
    case originalText
    case oracleText
    case flavorText
    case artist
    case set
    case printings
    case rulings
    case legalities
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .information: return "Information"
        case .originalText: return "Original Text"
        case .oracleText: return "Oracle Text"
        case .flavorText: return "Flavor Text"
        case .artist: return "Artist"
        case .set: return "Set"
        case .printings: return "Printings"
        case .rulings: return "Rulings"
        case .legalities: return "Legalities"
        }
    }
    
    static var count: Int {
        return 9
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
        contentSegmentedControl.setFAIcon(icon: .FAInfoCircle, forSegmentAtIndex: 1)
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kCardViewUpdatedNotification), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateCardViews(_:)), name: NSNotification.Name(rawValue: kCardViewUpdatedNotification), object: nil)
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
            title = card.name
            
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
        
        var nameHeader: String?
        if let releaseDate = card.set!.releaseDate {
            let isModern = ManaKit.sharedInstance.isModern(card)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            if let m15Date = formatter.date(from: "2014-07-18"),
                let setReleaseDate = formatter.date(from: releaseDate) {
                
                if setReleaseDate.compare(m15Date) == .orderedSame ||
                    setReleaseDate.compare(m15Date) == .orderedDescending {
                    nameHeader = "cardNameMagic2015"
                    
                } else {
                    nameHeader = isModern ? "cardNameEightEdition" : "cardNamePreEightEdition"
                }
            }
        }

        if let nameHeader = nameHeader {
            html = html.replacingOccurrences(of: "{{nameHeader}}", with: nameHeader)
        } else {
            html = html.replacingOccurrences(of: "{{nameHeader}}", with: "&nbsp;")
        }
        
        if let name = card.name {
            html = html.replacingOccurrences(of: "{{name}}", with: name)
        } else {
            html = html.replacingOccurrences(of: "{{name}}", with: "&nbsp;")
        }
        
        if let manaCost = card.manaCost {
            html = html.replacingOccurrences(of: "{{manaCost}}", with: replaceSymbols(inText: manaCost))
        } else {
            html = html.replacingOccurrences(of: "{{manaCost}}", with: "&mdash;")
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
        
        if let power = card.power {
            html = html.replacingOccurrences(of: "{{power}}", with: power)
        } else {
            html = html.replacingOccurrences(of: "{{power}}", with: "&mdash;")
        }
        
        if let toughness = card.toughness {
            html = html.replacingOccurrences(of: "{{toughness}}", with: toughness)
        } else {
            html = html.replacingOccurrences(of: "{{toughness}}", with: "&mdash;")
        }

        if let originalType = card.originalType {
            html = html.replacingOccurrences(of: "{{originalType}}", with: originalType)
        } else {
            html = html.replacingOccurrences(of: "{{originalType}}", with: "&mdash;")
        }

        if let type_ = card.type_ {
            html = html.replacingOccurrences(of: "{{type}}", with: type_.name!)
        } else {
            html = html.replacingOccurrences(of: "{{type}}", with: "&mdash;")
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
            sections = 1
        case .details:
            sections = CardViewControllerDetailsSection.count
        }
        
        return sections
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        switch segmentedIndex {
        case .image:
            if let c = tableView.dequeueReusableCell(withIdentifier: "CarouselCell") {
                if let carouselView = c.viewWithTag(100) as? iCarousel {
                    carouselView.dataSource = self
                    carouselView.delegate = self
                    carouselView.type = .coverFlow2
                    carouselView.isPagingEnabled = true
                    carouselView.currentItemIndex = cardIndex
                    
                    if let carouselItemView = carouselView.itemView(at: cardIndex) as? CarouselItemView,
                        let cards = cards {
                        
                        let card = cards[cardIndex]
                        carouselItemView.card = card
                        carouselItemView.showCardViews()
                    }
                }
                c.selectionStyle = .none
                c.accessoryType = .none
                cell = c
            }
            
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.information.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "WebViewCell") {
                    c.selectionStyle = .none
                    c.accessoryType = .none
                    cell = c
                }
            case CardViewControllerDetailsSection.originalText.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
                    if let label = c.viewWithTag(100) as? UILabel{
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
            case CardViewControllerDetailsSection.information.rawValue:
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
            height = tableView.frame.size.height
        case .details:
            switch indexPath.section {
            case CardViewControllerDetailsSection.information.rawValue:
                if let webViewSize = webViewSize {
                    height = webViewSize.height
                } else {
                    height = CGFloat(88)
                }
            case CardViewControllerDetailsSection.printings.rawValue:
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
//        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
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
        var cardView: UIView?
        
        //reuse view if available, otherwise create a new view
        if let cards = cards {
            if let carouselItemView = view as? CarouselItemView {
                carouselItemView.card = cards[index]
                carouselItemView.showCard()
                cardView = carouselItemView
                
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CarouselItemViewController")
                let height = tableView.frame.size.height
                
                vc.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width-40, height: height)
                if let carouselItemView = vc.view as? CarouselItemView {
                    carouselItemView.labelWidthConstraint.constant = carouselItemView.frame.size.width / 4
                    carouselItemView.priceWidthConstraint.constant = carouselItemView.frame.size.width / 4
                    carouselItemView.card = cards[index]
                    carouselItemView.showCard()
                    cardView = carouselItemView
                }
            }
        }
        
        return cardView!
    }
}

extension CardViewController : iCarouselDelegate {
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        cardIndex = carousel.currentItemIndex
        cardViewIncremented = false
    }
}

