//
//  SetViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import Font_Awesome_Swift
import InAppSettingsKit
import ManaKit
import MBProgressHUD
import PromiseKit

enum SetViewControllerSegmentedIndex: Int {
    case cards
    case wiki
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .cards: return "Cards"
        case .wiki: return "Wiki"
        }
    }
    
    static var count: Int {
        return 2
    }
}

class SetViewController: BaseViewController {

    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var set: CMSet?
    var fetchedResultsController: NSFetchedResultsController<CMCard>?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()
    var collectionView: UICollectionView?
    var firstLoad = true
    
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        updateDataDisplay()
    }
    
    @IBAction func showRightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Set")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentSegmentedControl.setFAIcon(icon: .FADatabase, forSegmentAtIndex: 0)
        contentSegmentedControl.setFAIcon(icon: .FAWikipediaW, forSegmentAtIndex: 1)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                                  object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateData(_:)),
                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                               object: nil)
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter"
        definesPresentationContext = true
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }

        rightMenuButton.image = UIImage.init(icon: .FABars, size: CGSize(width: 30, height: 30), textColor: .white, backgroundColor: .clear)
        rightMenuButton.title = nil
        
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: CardTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "BrowserTableViewCell", bundle: nil), forCellReuseIdentifier: "SetInfoCell")
        tableView.keyboardDismissMode = .onDrag
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if firstLoad {
            firstLoad = false
            updateDataDisplay()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String] else {
                return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withCardIDs: cardIDs,
                                           withSortDescriptors: dict["sortDescriptors"] as? [NSSortDescriptor])
            
        } else if segue.identifier == "showCardModal" {
            guard let nav = segue.destination as? UINavigationController,
                let dest = nav.childViewControllers.first as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String] else {
                return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withCardIDs: cardIDs,
                                           withSortDescriptors: dict["sortDescriptors"] as? [NSSortDescriptor])
            
        } else if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let request = sender as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.request = request
            dest.title = "Search Results"
            dest.customSectionName = "nameSection"
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateDataDisplay()
    }
    
    // MARK: Custom methods
    func updateDataDisplay() {
        let searchGenerator = SearchRequestGenerator()
        
        guard let displayBy = searchGenerator.searchValue(for: .displayBy) as? String else {
            return
        }
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case SetViewControllerSegmentedIndex.cards.rawValue:
            if #available(iOS 11.0, *) {
                navigationItem.searchController?.searchBar.isHidden = false
                navigationItem.hidesSearchBarWhenScrolling = false
            } else {
                tableView.tableHeaderView = searchController.searchBar
            }
            
            switch displayBy {
            case "list":
                fetchedResultsController = getFetchedResultsController(with: nil)
                updateSections()
            case "grid":
                tableView.dataSource = self
            default:
                ()
            }
        case SetViewControllerSegmentedIndex.wiki.rawValue:
            if #available(iOS 11.0, *) {
                navigationItem.searchController?.searchBar.isHidden = true
                navigationItem.hidesSearchBarWhenScrolling = true
            } else {
                tableView.tableHeaderView = nil
            }
            
            tableView.dataSource = self
        default:
            ()
        }
        
        tableView.delegate = self
        tableView.reloadData()
    }

    func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMCard>?) -> NSFetchedResultsController<CMCard> {
        guard let set = set,
            let code = set.code else {
            fatalError("Set is nil")
        }
        
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMCard>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // create a default fetchRequest
            request = CMCard.fetchRequest()
            request!.predicate = NSPredicate(format: "set.code = %@", code)
            request!.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),
                                        NSSortDescriptor(key: "number", ascending: true),
                                        NSSortDescriptor(key: "mciNumber", ascending: true)]
        }
        
        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: request!,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        
        // Configure Fetched Results Controller
        frc.delegate = self
        
        // perform fetch
        do {
            try frc.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        return frc
    }

//    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
//        let searchGenerator = SearchRequestGenerator()
//
//        guard let set = set,
//            let code = set.code,
//            let sortBy = searchGenerator.searchValue(for: .sortBy) as? String,
//            let secondSortBy = searchGenerator.searchValue(for: .secondSortBy) as? String,
//            let orderBy = searchGenerator.searchValue(for: .orderBy) as? Bool,
//            let displayBy = searchGenerator.searchValue(for: .displayBy) as? String else {
//                return nil
//        }
//
//        var sectionName = searchGenerator.searchValue(for: .sectionName) as? String
//        var sortDescriptors: [NSSortDescriptor]?
//        var request:NSFetchRequest<NSFetchRequestResult>?
//        var ds: DATASource?
//
//        if sortBy == "numberOrder" {
//            sectionName = nil
//            sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: orderBy)]
//        } else {
//            sortDescriptors = [NSSortDescriptor(key: sectionName, ascending: orderBy),
//                               NSSortDescriptor(key: secondSortBy, ascending: orderBy)]
//        }
//
//        if let fetchRequest = fetchRequest {
//            request = fetchRequest
//            request!.sortDescriptors = sortDescriptors
//        } else {
//            request = CMCard.fetchRequest()
//            request!.sortDescriptors = sortDescriptors
//            request!.predicate = NSPredicate(format: "set.code = %@", code)
//        }
//
//        switch displayBy {
//        case "list":
//            ds = DATASource(tableView: tableView,
//                            cellIdentifier: "CardCell",
//                            fetchRequest: request!,
//                            mainContext: ManaKit.sharedInstance.dataStack!.mainContext,
//                            sectionName: sectionName)
//
//        case "grid":
//            guard let collectionView = collectionView else {
//                return nil
//            }
//
//            ds = DATASource(collectionView: collectionView,
//                            cellIdentifier: "CardImageCell",
//                            fetchRequest: request!,
//                            mainContext: ManaKit.sharedInstance.dataStack!.mainContext,
//                            sectionName: sectionName)
//
//        default:
//            ()
//        }
//
//        guard let d = ds else {
//            return nil
//        }
//        d.delegate = self
//        return d
//    }
    
    func updateSections() {
        guard let fetchedResultsController = fetchedResultsController,
            let cards = fetchedResultsController.fetchedObjects,
            let sections = fetchedResultsController.sections else {
            return
        }
        
        let searchGenerator = SearchRequestGenerator()
        let sectionName = searchGenerator.searchValue(for: .sectionName) as? String
        let sortBy = searchGenerator.searchValue(for: .sortBy) as? String
        let displayBy = searchGenerator.searchValue(for: .displayBy) as? String

        sectionIndexTitles = [String]()
        sectionTitles = [String]()
        
        if sortBy == "numberOrder" {
            return
        }
        
        switch sectionName {
        case "nameSection":
            for card in cards {
                if let nameSection = card.nameSection {
                    if !sectionIndexTitles.contains(nameSection) {
                        sectionIndexTitles.append(nameSection)
                    }
                }
            }
        case "typeSection":
            for card in cards {
                if let typeSection = card.typeSection {
                    let prefix = String(typeSection.prefix(1))
                    
                    if !sectionIndexTitles.contains(prefix) {
                        sectionIndexTitles.append(prefix)
                    }
                }
            }
        
        case "rarity_.name":
            for card in cards {
                if let rarity = card.rarity_ {
                    let prefix = String(rarity.name!.prefix(1))
                    
                    if !sectionIndexTitles.contains(prefix) {
                        sectionIndexTitles.append(prefix)
                    }
                }
            }
        case "artist_.name":
            for card in cards {
                if let artist = card.artist_ {
                    let prefix = String(artist.name!.prefix(1))
                    
                    if !sectionIndexTitles.contains(prefix) {
                        sectionIndexTitles.append(prefix)
                    }
                }
            }
//        case "legality.name"?:
//            let cardLegalities = dataSource.all() as [CMCardLegality]
//            for cardLegality in cardLegalities {
//                if let legality = cardLegality.legality {
//                    let prefix = String(legality.name!.prefix(1))
//
//                    if !sectionIndexTitles.contains(prefix) {
//                        sectionIndexTitles.append(prefix)
//                    }
//                }
//            }
        default:
            ()
        }
        
        let count = 0
//        switch displayBy {
//        case "list":
//            sections = dataSource.numberOfSections(in: tableView)
//        case "grid":
//            if let collectionView = collectionView {
//                sections = dataSource.numberOfSections(in: collectionView)
//            }
//        default:
//            ()
//        }
        
        if count > 0 {
            for i in 0...count - 1 {
                if let sectionTitle = sections[i].indexTitle {
                    sectionTitles.append(sectionTitle)
                }
            }
        }
        
        sectionIndexTitles.sort()
        sectionTitles.sort()
    }
    
    func updateData(_ notification: Notification) {
        let searchGenerator = SearchRequestGenerator()
        searchGenerator.syncValues(notification)

        updateDataDisplay()
    }
    
    func wikiURL(ofSet set: CMSet) -> URL? {
        var path = ""
        
        if let name = set.name,
            let code = set.code {
            
            if code == "LEA" {
                path = "Alpha"
            } else if code == "LEB" {
                path = "Beta"
            } else {
                path = name.replacingOccurrences(of: " and ", with: " & ")
                       .replacingOccurrences(of: " ", with: "_")
            }
        }
        
        return URL(string: "https://mtg.gamepedia.com/\(path)")
    }
    
    func doSearch() {
        let searchGenerator = SearchRequestGenerator()
        
        guard let set = set,
            let code = set.code,
            let sectionName = searchGenerator.searchValue(for: .sectionName) as? String,
            let secondSortBy = searchGenerator.searchValue(for: .secondSortBy) as? String,
            let orderBy = searchGenerator.searchValue(for: .orderBy) as? Bool,
            let displayBy = searchGenerator.searchValue(for: .displayBy) as? String else {
            return
        }
        
        var newRequest: NSFetchRequest<CMCard>?
        
        if let text = searchController.searchBar.text {
            if text.count > 0 {
                newRequest = CMCard.fetchRequest()
                
                newRequest!.sortDescriptors = [NSSortDescriptor(key: sectionName, ascending: orderBy),
                                               NSSortDescriptor(key: secondSortBy, ascending: orderBy)]
                
                if text.count == 1 {
                    newRequest!.predicate = NSPredicate(format: "set.code = %@ AND name BEGINSWITH[cd] %@", code, text)
                } else if text.count > 1 {
                    newRequest!.predicate = NSPredicate(format: "set.code = %@ AND (name CONTAINS[cd] %@ OR name CONTAINS[cd] %@)", code, text, text)
                }
                fetchedResultsController = getFetchedResultsController(with: newRequest)
                
            } else {
                fetchedResultsController = getFetchedResultsController(with: nil)
            }
        }
    
        updateSections()
        switch displayBy {
        case "list":
            tableView.reloadData()
        case "grid":
            collectionView?.reloadData()
        default:
            ()
        }
    }
}

// MARK: UITableViewDataSource
extension SetViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let cards = fetchedResultsController.fetchedObjects else {
                return 0
        }
        
        return cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchGenerator = SearchRequestGenerator()
        let displayBy = searchGenerator.searchValue(for: .displayBy) as? String
        var cell: UITableViewCell?
        
        switch contentSegmentedControl.selectedSegmentIndex {
        case SetViewControllerSegmentedIndex.cards.rawValue:
            switch displayBy {
            case "list":
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardTableViewCell.reuseIdentifier) as? CardTableViewCell,
                    let fetchedResultsController = fetchedResultsController else {
                    fatalError("Unexpected indexPath: \(indexPath)")
                }
                let card = fetchedResultsController.object(at: indexPath)
                c.card = card
                
                cell = c

            case "grid":
                guard let c = tableView.dequeueReusableCell(withIdentifier: "GridCell") else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                guard let collectionView = c.viewWithTag(100) as? UICollectionView else {
                    return UITableViewCell(frame: CGRect.zero)
                }
                
                self.collectionView = collectionView
                collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
                collectionView.dataSource = self
                collectionView.delegate = self
                
                if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    let width = tableView.frame.size.width
                    let height = tableView.frame.size.height - kCardTableViewCellHeight - CGFloat(44)
                    
                    flowLayout.itemSize = cardSize(inFrame: CGSize(width: width, height: height))
                    flowLayout.minimumInteritemSpacing = CGFloat(0)
                    flowLayout.minimumLineSpacing = CGFloat(10)
                    flowLayout.headerReferenceSize = CGSize(width: width, height: 22)
                    flowLayout.sectionHeadersPinToVisibleBounds = true
                }
                
                cell = c
                
            default:
                ()
            }
        case SetViewControllerSegmentedIndex.wiki.rawValue:
            guard let set = set,
                let c = tableView.dequeueReusableCell(withIdentifier: "SetInfoCell") as? BrowserTableViewCell,
                let url = wikiURL(ofSet: set) else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0)
            c.webView.delegate = self
            c.webView.loadRequest(request)
            cell = c
            
        default:
            ()
        }
        
        return cell!
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let searchGenerator = SearchRequestGenerator()
        var sectionIndex = 0
        
        guard let orderBy = searchGenerator.searchValue(for: .orderBy) as? Bool else {
            return sectionIndex
        }
        
        for i in 0...sectionTitles.count - 1 {
            if sectionTitles[i].hasPrefix(title) {
                if orderBy {
                    sectionIndex = i
                } else {
                    sectionIndex = (sectionTitles.count - 1) - i
                }
                break
            }
        }
        
        return sectionIndex
    }
}

// MARK: UITableViewDelegate
extension SetViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)

        switch contentSegmentedControl.selectedSegmentIndex {
        case SetViewControllerSegmentedIndex.cards.rawValue:
            let searchGenerator = SearchRequestGenerator()
            guard let displayBy = searchGenerator.searchValue(for: .displayBy) as? String else {
                return height
            }
            
            switch displayBy {
            case "list":
                height = kCardTableViewCellHeight
            case "grid":
                height = tableView.frame.size.height
            default:
                ()
            }
        case SetViewControllerSegmentedIndex.wiki.rawValue:
            height = tableView.frame.size.height
        default:
            ()
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch contentSegmentedControl.selectedSegmentIndex {
        case SetViewControllerSegmentedIndex.cards.rawValue:
            guard let fetchedResultsController = fetchedResultsController,
                let cards = fetchedResultsController.fetchedObjects else {
                return
            }
            
            let card = fetchedResultsController.object(at: indexPath)
            let cardIndex = cards.index(of: card)
            let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            let sender = ["cardIndex": cardIndex as Any,
                          "cardIDs": cards.map({ $0.id })]
            performSegue(withIdentifier: identifier, sender: sender)
        default:
            ()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch contentSegmentedControl.selectedSegmentIndex {
        case SetViewControllerSegmentedIndex.cards.rawValue:
            let searchGenerator = SearchRequestGenerator()
            guard let displayBy = searchGenerator.searchValue(for: .displayBy) as? String else {
                return
            }
            
            switch displayBy {
            case "grid":
                fetchedResultsController = getFetchedResultsController(with: nil)
                updateSections()
            default:
                ()
            }
        default:
            ()
        }
    }
}

// UICollectionViewDelegate
extension SetViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let cards = fetchedResultsController.fetchedObjects else {
                return 0
        }
        
        return cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardImageCell", for: indexPath)
        
        guard let imageView = cell.viewWithTag(100) as? UIImageView,
            let fetchedResultsController = fetchedResultsController else {
            fatalError("Unexpected indexPath: \(indexPath)")
        }
        let card = fetchedResultsController.object(at: indexPath)
        
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
                                  options: .transitionFlipFromRight,
                                  animations: animations,
                                  completion: nil)
            }.catch { error in
                print("\(error)")
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let v = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier:"Header", for: indexPath)
        
        if kind == UICollectionElementKindSectionHeader {
            v.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
            
            if v.subviews.count == 0 {
                let label = UILabel(frame: CGRect(x: 20, y: 0, width: collectionView.frame.size.width - 20, height: 22))
                label.tag = 100
                v.addSubview(label)
            }
            
            let searchGenerator = SearchRequestGenerator()
            
            guard let lab = v.viewWithTag(100) as? UILabel,
                let orderBy = searchGenerator.searchValue(for: .orderBy) as? Bool else {
                return v
            }
            
            var sectionTitle: String?
            
            if orderBy {
                sectionTitle = sectionTitles[indexPath.section]
            } else {
                sectionTitle = sectionTitles[sectionTitles.count - 1 - indexPath.section]
            }
            
            lab.text = sectionTitle
        }
        
        return v
    }
}

// UICollectionViewDelegate
extension SetViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let fetchedResultsController = fetchedResultsController,
            let cards = fetchedResultsController.fetchedObjects else {
                return
        }
        
        let card = fetchedResultsController.object(at: indexPath)
        let cardIndex = cards.index(of: card)
        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
        let sender = ["cardIndex": cardIndex as Any,
                      "cardIDs": cards.map({ $0.id })]
        performSegue(withIdentifier: identifier, sender: sender)
    }
}

// MARK: UIWebViewDelegate
extension SetViewController : UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url,
            let host = url.host else {
            return false
        }
        
        var willLoad = false
        
        if host.contains("gamepedia.com") {
            willLoad = true
        } else if host.contains("magiccards.info") ||
            host.contains("scryfall.com") {
            
            // Show the card instead opening the link!!!
            let urlComponents = URLComponents(string: url.absoluteString)
            let queryItems = urlComponents?.queryItems
            let q = queryItems?.filter({$0.name == "q"}).first
            
            if let value = q?.value {
                let r = value.index(value.startIndex, offsetBy: 1)
                let cardName = value.substring(from: r).replacingOccurrences(of: "+", with: " ")
                               .replacingOccurrences(of: "\"", with: "")
                
                let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                request.predicate = NSPredicate(format: "name = %@", cardName)
                request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                            NSSortDescriptor(key: "name", ascending: true)]
                
                let results = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
                if results.count == 1 {
                    if let card = results.first {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            performSegue(withIdentifier: "showCard", sender: ["cardIndex": 0 as Any,
                                                                              "cardIDs": [card.id!]])
                        } else if UIDevice.current.userInterfaceIdiom == .pad {
                            performSegue(withIdentifier: "showCardModal", sender: ["cardIndex": 0 as Any,
                                                                                   "cardIDs": [card.id!]])
                        }
                    }
                } else if results.count > 1 {
                    performSegue(withIdentifier: "showSearch", sender: request)
                } else {
                    let alertVC = UIAlertController(title: "Card Not found", message: "The card: \(cardName) was not found in the database", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertVC.addAction(okAction)
                    present(alertVC, animated: true, completion: nil)
                }
            }
        }
        
        return willLoad
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        MBProgressHUD.showAdded(to: webView, animated: true)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        MBProgressHUD.hide(for: webView, animated: true)
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BrowserTableViewCell else {
            return
        }
        
        cell.backButton.isEnabled = webView.canGoBack
        cell.forwardButton.isEnabled = webView.canGoForward
        cell.refreshButton.isEnabled = true
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        MBProgressHUD.hide(for: webView, animated: true)
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BrowserTableViewCell else {
            return
        }
        
        cell.backButton.isEnabled = webView.canGoBack
        cell.forwardButton.isEnabled = webView.canGoForward
        cell.refreshButton.isEnabled = true
        
        var html = "<html><body><center>"
        html.append(error.localizedDescription)
        html.append("</center></body></html>")
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: UISearchResultsUpdating
extension SetViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension SetViewController : NSFetchedResultsControllerDelegate {
    
}
