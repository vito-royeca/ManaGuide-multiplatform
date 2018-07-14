//
//  SearchViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import Font_Awesome_Swift
import InAppSettingsKit
import MBProgressHUD
import ManaKit
import PromiseKit

class SearchViewController: BaseViewController {

    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var dataSource: DATASource?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()
    var collectionView: UICollectionView?
    var request: NSFetchRequest<NSFetchRequestResult>?
    var customSectionName: String?
    var firstLoad = true
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var statusLabel: UILabel!
    
    // MARK: Actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        if request != nil {
            showSettingsMenu(file: "SearchResults")
        } else {
            showSettingsMenu(file: "Search")
        }
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                                  object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateData(_:)),
                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                               object: nil)
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Keyword"
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        rightMenuButton.image = UIImage.init(icon: .FABars,
                                             size: CGSize(width: 30, height: 30),
                                             textColor: .white,
                                             backgroundColor: .clear)
        rightMenuButton.title = nil
        
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        tableView.keyboardDismissMode = .onDrag
        statusLabel.text = " Loading..."
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    
        if title == "Favorites" {
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name(rawValue: kFavoriteToggleNotification),
                                                      object:nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.updateFavorites(_:)),
                                                   name: NSNotification.Name(rawValue: kFavoriteToggleNotification),
                                                   object: nil)
        } else if title == "Rated Cards" {
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification),
                                                      object:nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.updateRatedCards(_:)),
                                                   name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification),
                                                   object: nil)
        }
        
        if firstLoad {
            if title == "Favorites" {
                updateFavorites(Notification(name: NSNotification.Name(rawValue: kFavoriteToggleNotification)))
            } else if title == "Rated Cards" {
                updateRatedCards(Notification(name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification)))
            }
            updateDataDisplay()
            
            firstLoad = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kFavoriteToggleNotification),
                                                  object:nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kCardRatingUpdatedNotification),
                                                  object:nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dict = sender as? [String: Any] else {
            return
        }
        
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController,
                let cardIndex = dict["cardIndex"] as? Int,
                let cardMIDs = dict["cardMIDs"] as? [NSManagedObjectID] else {
                return
            }
            
            dest.cardIndex = cardIndex
            dest.cardMIDs = cardMIDs
            
        } else if segue.identifier == "showCardModal" {
            guard let nav = segue.destination as? UINavigationController,
                let dest = nav.childViewControllers.first as? CardViewController,
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
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if tableView != nil { // check if we have already loaded
            updateDataDisplay()
        }
    }

    // MARK: Custom methods
    func updateDataDisplay() {
        let searchGenerator = SearchRequestGenerator()
        
        guard let searchDisplayBy = searchGenerator.defaultValue(for: "searchDisplayBy") as? String else {
            return
        }
        
        switch searchDisplayBy {
        case "list":
            dataSource = getDataSource(request != nil ? request : searchGenerator.createSearchRequest(query: searchController.searchBar.text, oldRequest: nil))
            updateSections()
            statusLabel.text = "  \(dataSource!.all().count) items"
            statusLabel.isHidden = false
        case "grid":
            tableView.dataSource = self
            statusLabel.text = "  0 items"
            statusLabel.isHidden = true
        default:
            ()
        }
        
        tableView.delegate = self
        tableView.reloadData()
    }
    
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        let searchGenerator = SearchRequestGenerator()
        var request:NSFetchRequest<NSFetchRequestResult>?
        
        let searchSectionName = customSectionName != nil ? customSectionName : searchGenerator.defaultValue(for: "searchSectionName") as? String
        let searchSecondSortBy = searchGenerator.defaultValue(for: "searchSecondSortBy") as? String
        let searchOrderBy = searchGenerator.defaultValue(for: "searchOrderBy") as! Bool
        let searchDisplayBy = searchGenerator.defaultValue(for: "searchDisplayBy") as! String
        var ds: DATASource?

        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = CMCard.fetchRequest()
            request!.predicate = NSPredicate(format: "name = nil")
            request!.sortDescriptors = [NSSortDescriptor(key: searchSectionName, ascending: searchOrderBy),
                                        NSSortDescriptor(key: searchSecondSortBy, ascending: searchOrderBy),
                                        NSSortDescriptor(key: "set.releaseDate", ascending: true)]
        }

        switch searchDisplayBy {
        case "list":
            ds = DATASource(tableView: tableView,
                            cellIdentifier: "CardCell",
                            fetchRequest: request!,
                            mainContext: ManaKit.sharedInstance.dataStack!.mainContext,
                            sectionName: searchSectionName)

        case "grid":
            guard let collectionView = collectionView else {
                return nil
            }

            ds = DATASource(collectionView: collectionView,
                            cellIdentifier: "CardImageCell",
                            fetchRequest: request!,
                            mainContext: ManaKit.sharedInstance.dataStack!.mainContext,
                            sectionName: searchSectionName)

        default:
            ()
        }
        
        if let ds = ds {
            ds.delegate = self
            return ds
        }
        return nil
    }
    
    func updateSections() {
        if let dataSource = dataSource {
            let cards = dataSource.all() as [CMCard]
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
            
            let searchGenerator = SearchRequestGenerator()
            let searchSectionName = customSectionName != nil ? customSectionName : searchGenerator.defaultValue(for: "searchSectionName") as? String
            
            switch searchSectionName {
            case "nameSection"?:
                for card in cards {
                    if let nameSection = card.nameSection {
                        if !sectionIndexTitles.contains(nameSection) {
                            sectionIndexTitles.append(nameSection)
                        }
                    }
                }
            case "typeSection"?:
                for card in cards {
                    if let typeSection = card.typeSection {
                        let prefix = String(typeSection.prefix(1))
                        
                        if !sectionIndexTitles.contains(prefix) {
                            sectionIndexTitles.append(prefix)
                        }
                    }
                }
            case "legality.name"?:
                let cardLegalities = dataSource.all() as [CMCardLegality]
                for cardLegality in cardLegalities {
                    if let legality = cardLegality.legality {
                        let prefix = String(legality.name!.prefix(1))
                        
                        if !sectionIndexTitles.contains(prefix) {
                            sectionIndexTitles.append(prefix)
                        }
                    }
                }
            default:
                ()
            }
            
            let sections = dataSource.numberOfSections(in: tableView)
            if sections > 0 {
                for i in 0...sections - 1 {
                    if let sectionTitle = dataSource.titleForHeader(i) {
                        sectionTitles.append(sectionTitle)
                    }
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

    func updateFavorites(_ notification: Notification) {
        request = CMCard.fetchRequest()
        let mids = FirebaseManager.sharedInstance.favoriteMIDs
        let cards = FirebaseManager.sharedInstance.cards(withMIDs: mids)

        request!.predicate = NSPredicate(format: "id IN %@", cards.map({ $0.id }))
        request!.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                   NSSortDescriptor(key: "name", ascending: true),
                                   NSSortDescriptor(key: "set.releaseDate", ascending: true)]
        updateDataDisplay()
    }
    
    func updateRatedCards(_ notification: Notification) {
        request = CMCard.fetchRequest()
        let mids = FirebaseManager.sharedInstance.ratedCardMIDs
        let cards = FirebaseManager.sharedInstance.cards(withMIDs: mids)
        
        request!.predicate = NSPredicate(format: "id IN %@", cards.map({ $0.id }))
        request!.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                    NSSortDescriptor(key: "name", ascending: true),
                                    NSSortDescriptor(key: "set.releaseDate", ascending: true)]
        updateDataDisplay()
    }
    
    func doSearch() {
        let searchGenerator = SearchRequestGenerator()
        let text = searchController.searchBar.text
        dataSource = getDataSource(searchGenerator.createSearchRequest(query: text, oldRequest: request))
        updateSections()
    
        
        if let searchDisplayBy = searchGenerator.defaultValue(for: "searchDisplayBy") as? String {
            switch searchDisplayBy {
            case "list":
                tableView.reloadData()
            case "grid":
                collectionView?.reloadData()
            default:
                ()
            }
        }
        
        self.statusLabel.text = "  \(self.dataSource!.all().count) items"
    }
}

// MARK: UITableViewDataSource
extension SearchViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = 1
        
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchGenerator = SearchRequestGenerator()
        let searchDisplayBy = searchGenerator.defaultValue(for: "searchDisplayBy") as! String
        var cell: UITableViewCell?
        
        switch searchDisplayBy {
        case "grid":
            guard let c = tableView.dequeueReusableCell(withIdentifier: "GridCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            guard let collectionView = c.viewWithTag(100) as? UICollectionView else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            
            self.collectionView = collectionView
            collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
            collectionView.delegate = self
            
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let width = tableView.frame.size.width
                var height = tableView.frame.size.height - kCardTableViewCellHeight
                if let tableHeaderView = tableView.tableHeaderView {
                    height -= tableHeaderView.frame.size.height
                }

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
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension SearchViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let searchGenerator = SearchRequestGenerator()
        let searchDisplayBy = searchGenerator.defaultValue(for: "searchDisplayBy") as! String
        var height = CGFloat(0)
        
        switch searchDisplayBy {
        case "list":
            height = kCardTableViewCellHeight
        case "grid":
            height = tableView.frame.size.height
        default:
            ()
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var card: CMCard?
        var cards = [CMCard]()
        var cardIndex = 0
        
        if let c = dataSource!.object(indexPath) as? CMCard {
            card = c
            cards = dataSource!.all()
            cardIndex = cards.index(of: card!)!
        } else if let c = dataSource!.object(indexPath) as? CMCardLegality {
            card = c.card
            let cardLegalities = dataSource!.all() as! [CMCardLegality]
            
            for cardLegality in cardLegalities {
                cards.append(cardLegality.card!)
            }
            cardIndex = cardLegalities.index(of: c)!
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            performSegue(withIdentifier: "showCard", sender: ["cardIndex": cardIndex as Any,
                                                              "cardMIDs": cards.map({ $0.objectID })])
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            performSegue(withIdentifier: "showCardModal", sender: ["cardIndex": cardIndex as Any,
                                                                   "cardMIDs": cards.map({ $0.objectID })])
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let searchGenerator = SearchRequestGenerator()
        let searchDisplayBy = searchGenerator.defaultValue(for: "searchDisplayBy") as! String
        
        switch searchDisplayBy {
        case "grid":
            dataSource = getDataSource(request != nil ? request : searchGenerator.createSearchRequest(query: searchController.searchBar.text, oldRequest: request))
            updateSections()
        default:
            ()
        }
    }
}

// MARK: DATASourceDelegate
extension SearchViewController : DATASourceDelegate {
    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
    func sectionIndexTitlesForDataSource(_ dataSource: DATASource, tableView: UITableView) -> [String] {
        return sectionIndexTitles
    }
    
    // tell table which section corresponds to section title/index (e.g. "B",1))
    func dataSource(_ dataSource: DATASource, tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        let searchGenerator = SearchRequestGenerator()
        let searchOrderBy = searchGenerator.defaultValue(for: "searchOrderBy") as! Bool
        var sectionIndex = 0
        
        for i in 0...sectionTitles.count - 1 {
            if sectionTitles[i].hasPrefix(title) {
                
                if customSectionName != nil {
                    sectionIndex = i
                } else {
                    if searchOrderBy {
                        sectionIndex = i
                    } else {
                        sectionIndex = (sectionTitles.count - 1) - i
                    }
                }
                break
            }
        }
        
        return sectionIndex
    }
    
    func dataSource(_ dataSource: DATASource, collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: IndexPath, withTitle title: Any?) -> UICollectionReusableView? {
        var v: UICollectionReusableView?
        
        if kind == UICollectionElementKindSectionHeader {
            v = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier:"Header", for: indexPath)
            v!.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
            
            if v!.subviews.count == 0 {
                let label = UILabel(frame: CGRect(x: 20, y: 0, width: collectionView.frame.size.width - 20, height: 22))
                label.tag = 100
                v!.addSubview(label)
            }
            
            if let lab = v!.viewWithTag(100) as? UILabel {
                lab.text = sectionTitles[indexPath.section]
            }
        }
        
        return v
    }
    
    func dataSource(_ dataSource: DATASource, configureTableViewCell cell: UITableViewCell, withItem item: NSManagedObject, atIndexPath indexPath: IndexPath) {
        guard let cardCell = cell as? CardTableViewCell else {
            return
        }
        
        if let card = item as? CMCard {
            cardCell.cardMID = card.objectID
            cardCell.updateDataDisplay()
        } else if let cardLegality = item as? CMCardLegality {
            cardCell.cardMID = cardLegality.card?.objectID
            cardCell.updateDataDisplay()
        }
    }
    
    func dataSource(_ dataSource: DATASource, configureCollectionViewCell cell: UICollectionViewCell, withItem item: NSManagedObject, atIndexPath indexPath: IndexPath) {
        var c: CMCard?
        
        if let item = item as? CMCard {
            c = item
        } else if let item = item as? CMCardLegality {
            c = item.card
        }
        
        guard let card = c,
            let imageView = cell.viewWithTag(100) as? UIImageView else {
                return
        }
        
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
    }
}

// UICollectionViewDelegate
extension SearchViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var card: CMCard?
        var cards = [CMCard]()
        var cardIndex = 0
        
        if let c = dataSource!.object(indexPath) as? CMCard {
            card = c
            cards = dataSource!.all()
            cardIndex = cards.index(of: card!)!
        } else if let c = dataSource!.object(indexPath) as? CMCardLegality {
            card = c.card
            let cardLegalities = dataSource!.all() as! [CMCardLegality]
            
            for cardLegality in cardLegalities {
                cards.append(cardLegality.card!)
            }
            cardIndex = cardLegalities.index(of: c)!
        }
        
        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
        let sender = ["cardIndex": cardIndex as Any,
                      "cardMIDs": cards.map({ $0.objectID })]
        performSegue(withIdentifier: identifier, sender: sender)
    }
}

// MARK: UISearchResultsUpdating
extension SearchViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

