//
//  SearchViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import FontAwesome_swift
import InAppSettingsKit
import ManaKit

class SearchViewController: BaseViewController {

    // MARK: Variables
    var dataSource: DATASource?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()
    var collectionView: UICollectionView?
    var request:NSFetchRequest<NSFetchRequestResult>?
    var customSectionName: String?
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusBar: UIView!
    @IBOutlet var statusLabel: UILabel!
    
    // MARK: Actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        if let searchBar = searchBar {
            searchBar.resignFirstResponder()
        }

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
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateData(_:)), name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object: nil)
        
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .gear, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        rightMenuButton.title = nil
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        
        // set statusBar's color to searchBar's background color
        if let imageView = searchBar.subviews.first?.subviews.first as? UIImageView {
            if let image = imageView.image {
                statusBar.backgroundColor = UIColor.init(patternImage: image)
            }
        }

        // we have a custom search result, so remove the searchBar and rightMenuButton
        if request != nil {
            tableView.viewWithTag(100)?.removeFromSuperview()
            tableView.tableHeaderView = nil
        }
        updateDataDisplay()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCard" {
            if let dest = segue.destination as? CardViewController,
                let dict = sender as? [String: Any] {
                
                dest.cardIndex = dict["cardIndex"] as! Int
                dest.cards = dict["cards"] as? [CMCard]
                dest.title = ""
            }
        } else if segue.identifier == "showCardModal" {
            if let nav = segue.destination as? UINavigationController {
                if let dest = nav.childViewControllers.first as? CardViewController,
                    let dict = sender as? [String: Any] {
                    dest.cardIndex = dict["cardIndex"] as! Int
                    dest.cards = dict["cards"] as? [CMCard]
                    dest.title = dest.cards?[dest.cardIndex].name
                }
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if tableView != nil { // check if we have already loaded
            updateDataDisplay()
        }
    }

    // MARK: Custom methods
    func updateDataDisplay() {
        let defaults = defaultsValue()
        let searchDisplayBy = defaults["searchDisplayBy"] as! String
        
        switch searchDisplayBy {
        case "list":
            dataSource = getDataSource(request != nil ? request : createSearchRequeat())
            updateSections()
        case "grid":
            tableView.dataSource = self
        default:
            ()
        }
        
        tableView.delegate = self
        tableView.reloadData()
    }
    
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        var request:NSFetchRequest<NSFetchRequestResult>?
        let defaults = defaultsValue()
        let searchSectionName = customSectionName != nil ? customSectionName : defaults["searchSectionName"] as? String
        let searchSecondSortBy = defaults["searchSecondSortBy"] as? String
        let searchOrderBy = defaults["searchOrderBy"] as! Bool
        let searchDisplayBy = defaults["searchDisplayBy"] as! String
        var ds: DATASource?

        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = NSFetchRequest(entityName: "CMCard")
            request!.predicate = NSPredicate(format: "name = nil")
            request!.sortDescriptors = [NSSortDescriptor(key: searchSectionName, ascending: searchOrderBy),
                                        NSSortDescriptor(key: searchSecondSortBy, ascending: searchOrderBy)]
        }

        switch searchDisplayBy {
        case "list":
            ds = DATASource(tableView: tableView, cellIdentifier: "CardCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: searchSectionName, configuration: { cell, item, indexPath in
                if let card = item as? CMCard,
                    let cardCell = cell as? CardTableViewCell {
                    
                    cardCell.card = card
                    cardCell.updateDataDisplay()
                } else if let cardLegality = item as? CMCardLegality,
                    let cardCell = cell as? CardTableViewCell {
                    
                    cardCell.card = cardLegality.card
                    cardCell.updateDataDisplay()
                }
            })
        case "grid":
            if let collectionView = collectionView {
                ds = DATASource(collectionView: collectionView, cellIdentifier: "CardImageCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: searchSectionName, configuration: { cell, item, indexPath in
                    if let card = item as? CMCard {
                        if let imageView = cell.viewWithTag(100) as? UIImageView {
                            imageView.image = ManaKit.sharedInstance.cardImage(card)
                            
                            // TODO: fix multiple image loading if scrolling fast
                            if imageView.image == ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.cardBack) {
                                ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                                    if error == nil {
                                        if c == self.dataSource!.object(indexPath) {
                                            if let image = image {
                                                UIView.transition(with: imageView,
                                                                  duration: 1.0,
                                                                  options: .transitionFlipFromLeft,
                                                                  animations: {
                                                                    imageView.image = image
                                                },
                                                                  completion: nil)
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    } else if let cardLegality = item as? CMCardLegality {
                        if let imageView = cell.viewWithTag(100) as? UIImageView {
                            imageView.image = ManaKit.sharedInstance.cardImage(cardLegality.card!)
                            
                            // TODO: fix multiple image loading if scrolling fast
                            if imageView.image == ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.cardBack) {
                                ManaKit.sharedInstance.downloadCardImage(cardLegality.card!, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                                    if error == nil {
                                        if let cl = self.dataSource!.object(indexPath) as? CMCardLegality,
                                            let image = image {
                                            
                                            if cl.card == c {
                                                UIView.transition(with: imageView,
                                                                  duration: 1.0,
                                                                  options: .transitionFlipFromLeft,
                                                                  animations: {
                                                                    imageView.image = image
                                                },
                                                                  completion: nil)
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    }
                })
            }
        default:
            ()
        }
        
        if let ds = ds {
            ds.delegate = self
            statusLabel.text = "\(ds.all().count) results"
            return ds
        }
        return nil
    }
    
    func updateSections() {
        if let dataSource = dataSource {
            let cards = dataSource.all() as [CMCard]
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
            
            let defaults = defaultsValue()
            let searchSectionName = customSectionName != nil ? customSectionName : defaults["searchSectionName"] as? String //defaults["searchSectionName"] as! String
            
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
                        let prefix = String(typeSection.characters.prefix(1))
                        
                        if !sectionIndexTitles.contains(prefix) {
                            sectionIndexTitles.append(prefix)
                        }
                    }
                }
            case "legality.name"?:
                let cardLegalities = dataSource.all() as [CMCardLegality]
                for cardLegality in cardLegalities {
                    if let legality = cardLegality.legality {
                        let prefix = String(legality.name!.characters.prefix(1))
                        
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
        if let userInfo = notification.userInfo as? [String: Any] {
            let defaults = defaultsValue()
            var searchSectionName = defaults["searchSectionName"] as! String
            var searchSortBy = defaults["searchSortBy"] as! String
            var searchSecondSortBy = defaults["searchSecondSortBy"] as! String
            var searchOrderBy = defaults["searchOrderBy"] as! Bool
            var searchDisplayBy = defaults["searchDisplayBy"] as! String
            
            if let value = userInfo["searchSortBy"] as? String {
                searchSortBy = value
                
                switch searchSortBy {
                case "name":
                    searchSectionName = "nameSection"
                    searchSecondSortBy = "name"
                case "typeSection":
                    searchSectionName = "typeSection"
                    searchSecondSortBy = "name"
                default:
                    ()
                }
            }
            
            if let value = userInfo["searchOrderBy"] as? Bool {
                searchOrderBy = value
            }
            
            if let value = userInfo["searchDisplayBy"] as? String {
                searchDisplayBy = value
            }
            
            UserDefaults.standard.set(searchSectionName, forKey: "searchSectionName")
            UserDefaults.standard.set(searchSortBy, forKey: "searchSortBy")
            UserDefaults.standard.set(searchSecondSortBy, forKey: "searchSecondSortBy")
            UserDefaults.standard.set(searchOrderBy, forKey: "searchOrderBy")
            UserDefaults.standard.set(searchDisplayBy, forKey: "searchDisplayBy")
            UserDefaults.standard.synchronize()
            
            updateDataDisplay()
        }
    }

    func defaultsValue() -> [String: Any] {
        var values = [String: Any]()
        
        // displayers
        if let value = UserDefaults.standard.value(forKey: "searchSectionName") as? String {
            values["searchSectionName"] = value
        } else {
            values["searchSectionName"] = "nameSection"
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchSortBy") as? String {
            values["searchSortBy"] = value
        } else {
            values["searchSortBy"] = "name"
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchSecondSortBy") as? String {
            values["searchSecondSortBy"] = value
        } else {
            values["searchSecondSortBy"] = "name"
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchOrderBy") as? Bool {
            values["searchOrderBy"] = value
        } else {
            values["searchOrderBy"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchDisplayBy") as? String {
            values["searchDisplayBy"] = value
        } else {
            values["searchDisplayBy"] = "list"
        }
        
        // keyword filters
        if let value = UserDefaults.standard.value(forKey: "searchKeywordName") as? Bool {
            values["searchKeywordName"] = value
        } else {
            values["searchKeywordName"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchKeywordText") as? Bool {
            values["searchKeywordText"] = value
        } else {
            values["searchKeywordText"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchKeywordFlavor") as? Bool {
            values["searchKeywordFlavor"] = value
        } else {
            values["searchKeywordFlavor"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchKeywordBoolean") as? String {
            values["searchKeywordBoolean"] = value
        } else {
            values["searchKeywordBoolean"] = "or"
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchKeywordNot") as? Bool {
            values["searchKeywordNot"] = value
        } else {
            values["searchKeywordNot"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchKeywordMatch") as? String {
            values["searchKeywordMatch"] = value
        } else {
            values["searchKeywordMatch"] = "contains"
        }

        // color filters
        if let value = UserDefaults.standard.value(forKey: "searchColorBlack") as? Bool {
            values["searchColorBlack"] = value
        } else {
            values["searchColorBlack"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorBlue") as? Bool {
            values["searchColorBlue"] = value
        } else {
            values["searchColorBlue"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorGreen") as? Bool {
            values["searchColorGreen"] = value
        } else {
            values["searchColorGreen"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorRed") as? Bool {
            values["searchColorRed"] = value
        } else {
            values["searchColorRed"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorWhite") as? Bool {
            values["searchColorWhite"] = value
        } else {
            values["searchColorWhite"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorColorless") as? Bool {
            values["searchColorColorless"] = value
        } else {
            values["searchColorColorless"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorBoolean") as? String {
            values["searchColorBoolean"] = value
        } else {
            values["searchColorBoolean"] = "or"
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorNot") as? Bool {
            values["searchColorNot"] = value
        } else {
            values["searchColorNot"] = false
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorMatch") as? String {
            values["searchColorMatch"] = value
        } else {
            values["searchColorMatch"] = "contains"
        }
        
        return values
    }
    
    func createSearchRequeat() -> NSFetchRequest<NSFetchRequestResult>? {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
        var predicate: NSPredicate?
        var subpredicates = [NSPredicate]()
        
        let defaults = defaultsValue()
        
        // displayers
        let searchSectionName = defaults["searchSectionName"] as! String
        let searchSecondSortBy = defaults["searchSecondSortBy"] as! String
        let searchOrderBy = defaults["searchOrderBy"] as! Bool
        
        // keyword filters
        let searchKeywordName = defaults["searchKeywordName"] as! Bool
        let searchKeywordText = defaults["searchKeywordText"] as! Bool
        let searchKeywordFlavor = defaults["searchKeywordFlavor"] as! Bool
        let searchKeywordBoolean = defaults["searchKeywordBoolean"] as! String
        let searchKeywordNot = defaults["searchKeywordNot"] as! Bool
        let searchKeywordMatch = defaults["searchKeywordMatch"] as! String
        
        // color filters
        let searchColorBlack = defaults["searchColorBlack"] as! Bool
        let searchColorBlue = defaults["searchColorBlue"] as! Bool
        let searchColorGreen = defaults["searchColorGreen"] as! Bool
        let searchColorRed = defaults["searchColorRed"] as! Bool
        let searchColorWhite = defaults["searchColorWhite"] as! Bool
        let searchColorColorless = defaults["searchColorColorless"] as! Bool
        let searchColorBoolean = defaults["searchColorBoolean"] as! String
        let searchColorNot = defaults["searchColorNot"] as! Bool
        let searchColorMatch = defaults["searchColorMatch"] as! String
        
        // process keyword filter
        if searchKeywordName {
            if let text = searchBar?.text {
                if searchKeywordMatch == "begins" {
                    subpredicates.append(NSPredicate(format: "name BEGINSWITH[cd] %@", text))
                } else if searchKeywordMatch == "contains" {
                    subpredicates.append(NSPredicate(format: "name CONTAINS[cd] %@", text))
                } else if searchKeywordMatch == "exact" {
                    subpredicates.append(NSPredicate(format: "name ==[c] %@", text))
                }
            }
        }
        if searchKeywordText {
            if let text = searchBar?.text {
                if searchKeywordMatch == "begins" {
                    subpredicates.append(NSPredicate(format: "text BEGINSWITH[cd] %@ OR originalText BEGINSWITH[cd] %@", text, text))
                } else if searchKeywordMatch == "contains" {
                    subpredicates.append(NSPredicate(format: "text CONTAINS[cd] %@ OR originalText CONTAINS[cd] %@", text, text))
                } else if searchKeywordMatch == "exact" {
                    subpredicates.append(NSPredicate(format: "text ==[c] %@ OR originalText ==[c] %@", text, text))
                }
            }
        }
        if searchKeywordFlavor {
            if let text = searchBar?.text {
                if searchKeywordMatch == "begins" {
                    subpredicates.append(NSPredicate(format: "flavor BEGINSWITH[cd] %@", text))
                } else if searchKeywordMatch == "contains" {
                    subpredicates.append(NSPredicate(format: "flavor CONTAINS[cd] %@", text))
                } else if searchKeywordMatch == "exact" {
                    subpredicates.append(NSPredicate(format: "flavor ==[c] %@", text))
                }
            }
        }
        if subpredicates.count > 0 {
            if searchKeywordBoolean == "and" {
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
            } else if searchKeywordBoolean == "or" {
                predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
            }
            if searchKeywordNot {
                predicate = NSCompoundPredicate(notPredicateWithSubpredicate: predicate!)
            }
        }
        
        // process color filter
        subpredicates = [NSPredicate]()
        
        if searchColorBlack {
            subpredicates.append(NSPredicate(format: "manaCost CONTAINS[cd] %@", "B"))
        }
        if searchColorBlue {
            subpredicates.append(NSPredicate(format: "manaCost CONTAINS[cd] %@", "U"))
        }
        if searchColorGreen {
            subpredicates.append(NSPredicate(format: "manaCost CONTAINS[cd] %@", "G"))
        }
        if searchColorRed {
            subpredicates.append(NSPredicate(format: "manaCost CONTAINS[cd] %@", "R"))
        }
        if searchColorWhite {
            subpredicates.append(NSPredicate(format: "manaCost CONTAINS[cd] %@", "W"))
        }
        if searchColorColorless {
            // TODO: double check X, Y, and Z manaCosts
            let array = ["{0}", "{1}", "{2}", "{3}", "{4}", "{5}",
                         "{6}", "{7}", "{8}", "{9}", "{10}", "{11}",
                         "{12}", "{13}", "{14}", "{15}", "{16}", "{17}",
                         "{18}", "{19}", "{20}", "{100}", "{1000000}",
                         "{X}", "{Y}", "{Z}", "{X}{X}", "{X}{Y}", "{X}{Y}{Z}"]
            subpredicates.append(NSPredicate(format: "manaCost IN %@", array))
        }
        if subpredicates.count > 0 {
            if searchColorBoolean == "and" {
                let colorPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
                if predicate == nil {
                    predicate = colorPredicate
                } else {
                    predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate!, colorPredicate])
                }
            } else if searchKeywordBoolean == "or" {
                let colorPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
                if predicate == nil {
                    predicate = colorPredicate
                } else {
                    predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate!, colorPredicate])
                }
            }
            if searchColorNot {
                predicate = NSCompoundPredicate(notPredicateWithSubpredicate: predicate!)
            }
        }

        // create a negative predicate, i.e. search for cards with nil name which results to zero
        if predicate == nil {
            predicate = NSPredicate(format: "name = nil")
        }
        
        print("\(predicate!)")
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: searchSectionName, ascending: searchOrderBy),
                                    NSSortDescriptor(key: searchSecondSortBy, ascending: searchOrderBy)]
        
        return request
    }
    
    func doSearch() {
        searchBar.resignFirstResponder()
        dataSource = getDataSource(createSearchRequeat())
        updateSections()
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource
extension SearchViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = 1
        
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaults = defaultsValue()
        let searchDisplayBy = defaults["searchDisplayBy"] as! String
        var cell: UITableViewCell?
        
        switch searchDisplayBy {
        case "grid":
            if let c = tableView.dequeueReusableCell(withIdentifier: "GridCell") {
                if let collectionView = c.viewWithTag(100) as? UICollectionView {
                    self.collectionView = collectionView
                    collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
                    collectionView.delegate = self
                    
                    if let bgImage = ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.grayPatterned) {
                        collectionView.backgroundColor = UIColor(patternImage: bgImage)
                    }
                    
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
                }
                cell = c
            }
        default:
            ()
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension SearchViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let defaults = defaultsValue()
        let searchDisplayBy = defaults["searchDisplayBy"] as! String
        var height = CGFloat(0)
        
        switch searchDisplayBy {
        case "list":
            height = kCardTableViewCellHeight
        case "grid":
            height = tableView.frame.size.height
//            if let searchBar = searchBar {
//                height -= searchBar.frame.size.height
//            }
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
                                                              "cards": cards])
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            performSegue(withIdentifier: "showCardModal", sender: ["cardIndex": cardIndex as Any,
                                                                   "cards": cards])
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let defaults = defaultsValue()
        let searchDisplayBy = defaults["searchDisplayBy"] as! String
        
        switch searchDisplayBy {
        case "grid":
            dataSource = getDataSource(request != nil ? request : createSearchRequeat())
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
        let defaults = defaultsValue()
        let searchOrderBy = defaults["searchOrderBy"] as! Bool
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
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            performSegue(withIdentifier: "showCard", sender: ["cardIndex": cardIndex as Any,
                                                              "cards": cards])
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            performSegue(withIdentifier: "showCardModal", sender: ["cardIndex": cardIndex as Any,
                                                                   "cards": cards])
        }
    }
}

// MARK: UISearchResultsUpdating
extension SearchViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        doSearch()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.characters.count == 0 {
            doSearch()
        }
    }
}

