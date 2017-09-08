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
import FontAwesome_swift
import ManaKit

enum CardViewControllerSegmentedIndex: Int {
    case image, details, discussion, lists
}

enum CardViewControllerImageSection: Int {
    case pricing, segmented, cards
}

enum CardViewControllerDetailsSection: Int {
    case information, printings, rulings, legalities
}

class CardViewController: BaseViewController {
    // MARK: Variables
    var cardIndex = 0
    var cards: [CMCard]?
    var variations: [CMCard]?
    var printings: [CMCard]?
    var cardsCollectionView: UICollectionView?
    var printingsCollectionView: UICollectionView?
    var segmentedIndex: CardViewControllerSegmentedIndex = .image
    var webViewSize: CGSize?
    
    // MARK: Constants
    let detailsSections = ["Information", "Printings", "Rulings", "Legalities"]
    let pricingSections = ["Low", "Mid", "High", "Foil", "Buy this card at TCGPlayer.com"]
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!

    // MARK: Actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        // TODO: fix this in iPad
//        showSettingsMenu(file: "Card")
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
        
        updateCardViews()
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
                    if let printingsCollectionView = printingsCollectionView,
                        let printings = printings {
                        if parentView == printingsCollectionView {
                            dest.cards = [printings[printingsCollectionView.indexPath(for: cell)!.item]]
                        }
                    }
                }
                
                dest.cardIndex = 0
            }
        }
    }
    
    // MARK: Custom methods
    func updateCardViews() {
        if let cards = cards {
            let card = cards[cardIndex]
            title = card.name
            
            FirebaseManager.sharedInstance.incrementCardViews(card.id!)
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
    
    func composeHTMLInformation(forCard card: CMCard) -> String {
        var html = try! String(contentsOfFile: "\(Bundle.main.bundlePath)/data/web/cardtext.html", encoding: String.Encoding.utf8)
        var css = try! String(contentsOfFile: "\(Bundle.main.bundlePath)/data/web/style.css", encoding: String.Encoding.utf8)
        
        let bundle = Bundle(for: ManaKit.self)
        if let bundleURL = bundle.resourceURL?.appendingPathComponent("ManaKit.bundle") {
            css = css.replacingOccurrences(of: "fonts/", with: "\(bundleURL.path)/fonts/")
            css = css.replacingOccurrences(of: "images/", with: "\(bundleURL.path)/images/")
            html = html.replacingOccurrences(of: "{{css}}", with: css)
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
        
        if let originalText = card.originalText {
            if card.text != originalText {
                html = html.replacingOccurrences(of: "{{originalText}}", with: replaceSymbols(inText: originalText))
            } else {
                html = html.replacingOccurrences(of: "{{originalText}}", with: "&mdash;")
            }
        } else {
            html = html.replacingOccurrences(of: "{{originalText}}", with: "&mdash;")
        }
        
        if let flavorText = card.flavor {
            html = html.replacingOccurrences(of: "{{flavorText}}", with:  replaceSymbols(inText: flavorText))
        } else {
            html = html.replacingOccurrences(of: "{{flavorText}}", with: "&mdash;")
        }
        
        if let oracleText = card.text {
            html = html.replacingOccurrences(of: "{{text}}", with: replaceSymbols(inText: oracleText))
        } else {
            html = html.replacingOccurrences(of: "{{text}}", with: "&nbsp;")
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
                html = html.replacingOccurrences(of: "{{colors}}", with: string.characters.count > 0 ? string : "&mdash;")
            } else {
                html = html.replacingOccurrences(of: "{{colors}}", with: "&mdash;")
            }
        } else {
            html = html.replacingOccurrences(of: "{{colors}}", with: "&mdash;")
        }
        
        if let colorIdentities_ = card.colorIdentities_ {
            if let s = colorIdentities_.allObjects as? [CMColor] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                html = html.replacingOccurrences(of: "{{colorIdentities}}", with: string.characters.count > 0 ? string : "&mdash;")
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
                html = html.replacingOccurrences(of: "{{subtypes}}", with: string.characters.count > 0 ? string : "&mdash;")
            } else {
                html = html.replacingOccurrences(of: "{{subtypes}}", with: "&mdash;")
            }
        } else {
            html = html.replacingOccurrences(of: "{{subtypes}}", with: "&mdash;")
        }
        
        if let supertypes_ = card.supertypes_ {
            if let s = supertypes_.allObjects as? [CMCardType] {
                let string = s.map({ $0.name! }).joined(separator: ", ")
                html = html.replacingOccurrences(of: "{{supertypes}}", with: string.characters.count > 0 ? string : "&mdash;")
            } else {
                html = html.replacingOccurrences(of: "{{supertypes}}", with: "&mdash;")
            }
        } else {
            html = html.replacingOccurrences(of: "{{supertypes}}", with: "&mdash;")
        }
        
        if let rarity = card.rarity_ {
            html = html.replacingOccurrences(of: "{{rarity}}", with: rarity.name!)
        } else {
            html = html.replacingOccurrences(of: "{{rarity}}", with: "&mdash;")
        }
        
        if let set = card.set {
            html = html.replacingOccurrences(of: "{{set}}", with: set.name!)
            html = html.replacingOccurrences(of: "{{setOnlineOnly}}", with: set.onlineOnly ? "Yes" : "No")
        } else {
            html = html.replacingOccurrences(of: "{{set}}", with: "&mdash;")
            html = html.replacingOccurrences(of: "{{setOnlineOnly}}", with: "&mdash;")
        }
        
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
        
        if let artist = card.artist_ {
            html = html.replacingOccurrences(of: "{{artist}}", with: artist.name!)
        } else {
            html = html.replacingOccurrences(of: "{{artist}}", with: "&mdash;")
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
            rows = 3
        case .details:
            switch section {
            case 0:
                rows = 2
            case CardViewControllerDetailsSection.rulings.rawValue + 1:
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let rulings_ = card.rulings_ {
                        rows = rulings_.allObjects.count >= 1 ? rulings_.allObjects.count : 1
                    }
                }
            case CardViewControllerDetailsSection.legalities.rawValue + 1:
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let cardLegalities_ = card.cardLegalities_ {
                        rows = cardLegalities_.allObjects.count >= 1 ? cardLegalities_.allObjects.count : 1
                    }
                }
            default:
                rows = 1
            }
        case .discussion:
            rows = 2
        case .lists:
            rows = 2
        }
        
        return rows
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var rows = 0
        
        switch segmentedIndex {
        case .image:
            rows = 1
        case .details:
            rows = detailsSections.count + 1
        case .discussion:
            rows = 1
        case .lists:
            rows = 1
        }
        
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        switch segmentedIndex {
        case .image:
            switch indexPath.row {
            case CardViewControllerImageSection.pricing.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "PricingCell"),
                    let cards = cards {
                    let card = cards[cardIndex]
                    // TODO: Fetch price from TCGPlayer
                    cell = c
                }
            case CardViewControllerImageSection.segmented.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell") {
                    cell = c
                }
            case CardViewControllerImageSection.cards.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "CardsCell") {
                    if let collectionView = c.viewWithTag(100) as? UICollectionView {
                        cardsCollectionView = collectionView
                        
                        if let bgImage = ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.grayPatterned) {
                            collectionView.backgroundColor = UIColor(patternImage: bgImage)
                        }
                        
                        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                            let width = tableView.frame.size.width
                            let height = tableView.frame.size.height - (CGFloat(44) * 2)// 2x CGFloat(44) for Pricing and Segmented cells
  
                            flowLayout.itemSize = CGSize(width: width * 0.74, height: height * 0.9)
                            flowLayout.sectionInset = UIEdgeInsets(top: height * 0.05, left: width * 0.13, bottom: height * 0.05, right: width * 0.13)
                            flowLayout.minimumInteritemSpacing = CGFloat(0)
                        }
                        
                        collectionView.dataSource = self
                        collectionView.delegate = self
                    }
                    cell = c
                }
            default:
                ()
            }
            cell!.detailTextLabel?.textColor = UIColor.black
            
        case .details:
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    if let c = tableView.dequeueReusableCell(withIdentifier: "PricingCell"),
                        let cards = cards {
                        let card = cards[cardIndex]
                        // TODO: Fetch price from TCGPlayer
                        cell = c
                    }
                case 1:
                    if let c = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell") {
                        cell = c
                    }
                default:
                    ()
                }
            case CardViewControllerDetailsSection.information.rawValue + 1:
                if let c = tableView.dequeueReusableCell(withIdentifier: "WebViewCell") {
                    if let webView = c.viewWithTag(100) as? UIWebView,
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
                    cell = c
                }
            case CardViewControllerDetailsSection.printings.rawValue + 1:
                if let c = tableView.dequeueReusableCell(withIdentifier: "ThumbnailsCell") {
                    if let collectionView = c.viewWithTag(100) as? UICollectionView,
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
                    
                    cell = c
                }
            case CardViewControllerDetailsSection.rulings.rawValue + 1:
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
                                if contents.characters.count > 0 {
                                    contents.append("\n\n")
                                }
                                contents.append(text)
                            }
                        } else {
                            contents = " "
                        }
                        
                        label.text = contents
                    }
                    
                    cell = c
                }
            case CardViewControllerDetailsSection.legalities.rawValue + 1:
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
                    
                    cell = c
                }
            default:
                ()
            }
            cell!.detailTextLabel?.textColor = UIColor.black
        case .discussion:
            switch indexPath.row {
            case 0:
                if let c = tableView.dequeueReusableCell(withIdentifier: "PricingCell"),
                    let cards = cards {
                    let card = cards[cardIndex]
                    // TODO: Fetch price from TCGPlayer
                    cell = c
                }
            case 1:
                if let c = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell") {
                    cell = c
                }
            default:
                ()
            }
        case .lists:
            switch indexPath.row {
            case 0:
                if let c = tableView.dequeueReusableCell(withIdentifier: "PricingCell"),
                    let cards = cards {
                    let card = cards[cardIndex]
                    // TODO: Fetch price from TCGPlayer
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
            case CardViewControllerDetailsSection.information.rawValue + 1:
                ()
            case CardViewControllerDetailsSection.rulings.rawValue + 1:
                headerTitle = detailsSections[CardViewControllerDetailsSection.rulings.rawValue]
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let rulings_ = card.rulings_ {
                        headerTitle?.append(": \(rulings_.count)")
                    }
                }
            case CardViewControllerDetailsSection.printings.rawValue + 1:
                headerTitle = detailsSections[CardViewControllerDetailsSection.printings.rawValue]
                
                if let printings = printings {
                    headerTitle?.append(": \(printings.count)")
                }
            case CardViewControllerDetailsSection.legalities.rawValue + 1:
                headerTitle = detailsSections[CardViewControllerDetailsSection.legalities.rawValue]
                
                if let cards = cards {
                    let card = cards[cardIndex]
                    
                    if let cardLegalities_ = card.cardLegalities_ {
                        headerTitle?.append(": \(cardLegalities_.count)")
                    }
                }
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
        case .image:
            switch indexPath.row {
            case 0:
                height = CGFloat(44)
            case CardViewControllerImageSection.cards.rawValue:
                height = tableView.frame.size.height - (CGFloat(44) * 2) // 2x CGFloat(44) for Pricing and Segmented cells
            default:
                height = UITableViewAutomaticDimension
            }
            
        case .details:
            switch indexPath.section {
            case 0:
                height = CGFloat(44)
            case CardViewControllerDetailsSection.information.rawValue + 1:
                if let webViewSize = webViewSize {
                    height = webViewSize.height
                }
            case CardViewControllerDetailsSection.printings.rawValue + 1:
                height = CGFloat(88)
            default:
                height = UITableViewAutomaticDimension
            }
        case .discussion:
            switch indexPath.row {
            case 0:
                height = CGFloat(44)
            default:
                height = UITableViewAutomaticDimension
            }
        case .lists:
            switch indexPath.row {
            case 0:
                height = CGFloat(44)
            default:
                height = UITableViewAutomaticDimension
            }
        }
        
//        print("Section: \(indexPath.section), Row: \(indexPath.row)")
        return height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44)
    }
}

// MARK: UICollectionViewDataSource
extension CardViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var items = 0
        
        switch segmentedIndex {
        case .image:
            if let cards = cards {
                items = cards.count
            }
            
        case .details:
            if let printings = printings {
                items = printings.count
            }
        case .discussion:
            ()
        case .lists:
            ()
        }

        return items
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell:UICollectionViewCell?
        
        switch segmentedIndex {
        case .image:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardItemCell", for: indexPath)
            
            if let cards = cards {
                let card = cards[indexPath.row]
                if let imageView = cell!.viewWithTag(100) as? UIImageView {
                    imageView.image = ManaKit.sharedInstance.cardImage(card)
                }
                
                if let ratingView = cell!.viewWithTag(200) as? CosmosView {
                    ratingView.settings.fillMode = .precise
                    ratingView.rating = card.rating
                    ratingView.isHidden = cardIndex != indexPath.row
                }
                if let viewedImage = cell!.viewWithTag(300) as? UIImageView {
                    let image = UIImage.fontAwesomeIcon(name: .eye, textColor: UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0), size: CGSize(width: 20, height: 20))
                    viewedImage.image = image
                    viewedImage.isHidden = cardIndex != indexPath.row
                }
                if let viewsLabel = cell!.viewWithTag(400) as? UILabel {
                    viewsLabel.text = "\(card.views)"
                    viewsLabel.isHidden = cardIndex != indexPath.row
                }
            }
        case .details:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailItemCell", for: indexPath)
            
            if let printings = printings,
                let thumbnailImage = cell!.viewWithTag(100) as? UIImageView,
                let setImage = cell!.viewWithTag(200) as? UIImageView {
                let printing = printings[indexPath.row]
                
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
        case .discussion:
            ()
        case .lists:
            ()
        }
        
        return cell!
    }
}

// UICollectionViewDelegate
extension CardViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == printingsCollectionView {
            if let thumbnailImage = cell.viewWithTag(100) as? UIImageView {
                thumbnailImage.layer.cornerRadius = thumbnailImage.frame.height / 6
                thumbnailImage.layer.masksToBounds = true
            }
        }
    }
}

// MARK: UIWebViewDelegate
extension CardViewController : UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webViewSize = webView.scrollView.contentSize
//        tableView.reloadRows(at: [IndexPath(row: 0, section: CardViewControllerDetailsSection.information.rawValue + 1)], with: .none)
        tableView.reloadData()
    }
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
                let indexPath = IndexPath(item: closestCellIndex, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                
                // update the pricing cell and download the image
                cardIndex = closestCellIndex
                webViewSize = nil
                if let cell = collectionView.cellForItem(at: indexPath) {
                    if let imageView = cell.viewWithTag(100) as? UIImageView,
                        let cards = cards {
                        
                        if imageView.image == ManaKit.sharedInstance.imageFromFramework(imageName: .cardBack) {
                            ManaKit.sharedInstance.downloadCardImage(cards[cardIndex], cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                                
                                if error == nil {
                                    let card = cards[self.cardIndex]
                                    
                                    if c == card {
                                        UIView.transition(with: imageView,
                                                          duration: 1.0,
                                                          options: .transitionFlipFromLeft,
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
                collectionView.reloadData()
                updateCardViews()
                
                // TODO: fetch pricing at TCGPlayer
                // ...
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

