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

let kNotificationCardIndexChanged = "kNotificationCardIndexChanged"

enum CardViewControllerSegmentedIndex: Int {
    case card, details, pricing
}

enum CardViewControllerCardSection: Int {
    case summary, segmented, cards
}

enum CardViewControllerDetailsSection: Int {
    case text, artist, printings, source, rulings, legalities
}

enum CardViewControllerPricingSection: Int {
    case summary, segmented
}

class CardViewController: BaseViewController {
    // MARK: Variables
    var cardIndex = 0
    var cards: [CMCard]?
    var variations: [CMCard]?
    var printings: [CMCard]?
    var cardsCollectionView: UICollectionView?
    var printingsCollectionView: UICollectionView?
    var segmentedIndex: CardViewControllerSegmentedIndex = .card
    var webViewSize: CGSize?
    
    // MARK: Constants
    let detailsSections = ["Text", "Artist", "Printings", "Source", "Rulings", "Legalities"]
    
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
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kNotificationCardImageDownloaded), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showCardImage(_:)), name: NSNotification.Name(rawValue: kNotificationCardImageDownloaded), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let cardsCollectionView = cardsCollectionView {
            cardsCollectionView.scrollToItem(at: IndexPath(item: cardIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let cards = cards {
            NotificationCenter.default.post(name: Notification.Name(rawValue: kNotificationCardIndexChanged), object: nil, userInfo: ["card": cards[cardIndex]])
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
            rows = detailsSections.count + 1
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
            case CardViewControllerCardSection.summary.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "CardCell") as? CardTableViewCell,
                    let cards = cards {
                    c.card = cards[cardIndex]
                    c.updateDataDisplay()
                    cell = c
                }
            case CardViewControllerCardSection.segmented.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell") {
                    cell = c
                }
            case CardViewControllerCardSection.cards.rawValue:
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
            case CardViewControllerDetailsSection.text.rawValue + 1:
                if let c = tableView.dequeueReusableCell(withIdentifier: "WebViewCell") {
                    if let webView = c.viewWithTag(100) as? UIWebView,
                        let cards = cards {
                        
                        if webViewSize == nil {
                            let card = cards[cardIndex]
                            var html = try! String(contentsOfFile: "\(Bundle.main.bundlePath)/data/web/cardtext.html", encoding: String.Encoding.utf8)
                            var css = try! String(contentsOfFile: "\(Bundle.main.bundlePath)/data/web/style.css", encoding: String.Encoding.utf8)
                            
                            let bundle = Bundle(for: ManaKit.self)
                            if let bundleURL = bundle.resourceURL?.appendingPathComponent("ManaKit.bundle") {
                                css = css.replacingOccurrences(of: "fonts/", with: "\(bundleURL.path)/fonts/")
                                css = css.replacingOccurrences(of: "images/", with: "\(bundleURL.path)/images/")
                                html = html.replacingOccurrences(of: "{{css}}", with: css)
                            }
                            
                            if let oracleText = card.text {
                                html = html.replacingOccurrences(of: "{{oracleText}}", with: replaceSymbols(inText: oracleText))
                            } else {
                                html = html.replacingOccurrences(of: "{{oracleText}}", with: "")
                            }
                            if let originalText = card.originalText {
                                if card.text != originalText {
                                    html = html.replacingOccurrences(of: "{{originalTextTitle}}", with: "Original")
                                    html = html.replacingOccurrences(of: "{{originalText}}", with: replaceSymbols(inText: originalText))
                                } else {
                                    html = html.replacingOccurrences(of: "{{originalTextTitle}}", with: "")
                                    html = html.replacingOccurrences(of: "{{originalText}}", with: "")
                                }
                            } else {
                                html = html.replacingOccurrences(of: "{{originalTextTitle}}", with: "")
                                html = html.replacingOccurrences(of: "{{originalText}}", with: "")
                            }
                            if let flavorText = card.flavor {
                                html = html.replacingOccurrences(of: "{{flavorTextTitle}}", with: "Flavor")
                                html = html.replacingOccurrences(of: "{{flavorText}}", with:  replaceSymbols(inText: flavorText))
                            } else {
                                html = html.replacingOccurrences(of: "{{flavorTextTitle}}", with: "")
                                html = html.replacingOccurrences(of: "{{flavorText}}", with: "")
                            }
                            
                            webView.delegate = self
                            webView.scrollView.isScrollEnabled = false
                            webView.scrollView.bounces = false
                            webView.loadHTMLString(html, baseURL: URL(fileURLWithPath: "\(Bundle.main.bundlePath)/data/web"))
                        }
                    }
                    cell = c
                }
            case CardViewControllerDetailsSection.artist.rawValue + 1:
                if let c = tableView.dequeueReusableCell(withIdentifier: "BasicCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
                    if let artist_ = card.artist_ {
                        c.textLabel?.text = artist_.name
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
            case CardViewControllerDetailsSection.source.rawValue + 1:
                if let c = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell"),
                    let cards = cards {
                    
                    let card = cards[cardIndex]
                    if let label = c.viewWithTag(100) as? UILabel {
                        label.text = card.source != nil ? card.source : " "
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
        
        case .pricing:
            switch indexPath.row {
            case CardViewControllerPricingSection.summary.rawValue:
                if let c = tableView.dequeueReusableCell(withIdentifier: "CardCell") as? CardTableViewCell,
                    let cards = cards {
                    c.card = cards[cardIndex]
                    c.updateDataDisplay()
                    cell = c
                }
            case CardViewControllerPricingSection.segmented.rawValue:
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
        case .card:
            switch indexPath.row {
            case CardViewControllerCardSection.summary.rawValue:
                height = kCardTableViewCellHeight
            case CardViewControllerCardSection.segmented.rawValue:
                height = UITableViewAutomaticDimension
            case CardViewControllerCardSection.cards.rawValue:
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
                    height = UITableViewAutomaticDimension
                default:
                    ()
                }
            case CardViewControllerDetailsSection.text.rawValue + 1:
                if let webViewSize = webViewSize {
                    height = webViewSize.height
                }
            case CardViewControllerDetailsSection.printings.rawValue + 1:
                height = CGFloat(88)
            default:
                height = UITableViewAutomaticDimension
            }
            
        case .pricing:
            switch indexPath.row {
            case CardViewControllerPricingSection.summary.rawValue:
                height = kCardTableViewCellHeight
            case CardViewControllerPricingSection.segmented.rawValue:
                height = UITableViewAutomaticDimension
            default:
                ()
            }
        }
        
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
        case .card:
            if let cards = cards {
                items = cards.count
            }
            
        case .details:
            if let printings = printings {
                items = printings.count
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
            
        case .pricing:
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
                collectionView.scrollToItem(at: IndexPath(row: closestCellIndex, section: 0), at: .centeredHorizontally, animated: false)
                
                // update the first table row cell
                cardIndex = closestCellIndex
                webViewSize = nil
                tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
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

