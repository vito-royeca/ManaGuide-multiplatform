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

    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        searchBar.resignFirstResponder()
        showSettingsMenu(file: "Search")
    }
    
    @IBAction func searchAction(_ sender: UIButton) {
        doSearch()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.updateData(_:)), name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kNotificationCardIndexChanged), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchViewController.scrollToCard(_:)), name: NSNotification.Name(rawValue: kNotificationCardIndexChanged), object: nil)
        
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .gear, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        rightMenuButton.title = nil
        searchButton.setImage(UIImage.fontAwesomeIcon(name: .play, textColor: UIColor.white, size: CGSize(width: 30, height: 30)), for: .normal)
        searchButton.setTitle(nil, for: .normal)
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        
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
            dataSource = getDataSource(createSearchRequeat())
            updateSections()
        case "2x2",
             "4x4":
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
        let searchSectionName = defaults["searchSectionName"] as! String
        let searchSortBy = defaults["searchSortBy"] as! String
        let searchOrderBy = defaults["searchOrderBy"] as! Bool
        let searchDisplayBy = defaults["searchDisplayBy"] as! String
        var ds: DATASource?

        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = NSFetchRequest(entityName: "CMCard")
            request!.sortDescriptors = [NSSortDescriptor(key: searchSectionName, ascending: searchOrderBy),
                                        NSSortDescriptor(key: searchSortBy, ascending: searchOrderBy)]
        }

        switch searchDisplayBy {
        case "list":
            ds = DATASource(tableView: tableView, cellIdentifier: "CardCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: searchSectionName, configuration: { cell, item, indexPath in
                if let card = item as? CMCard,
                    let cardCell = cell as? CardTableViewCell {
                    
                    cardCell.card = card
                    cardCell.updateDataDisplay()
                }
            })
        case "2x2",
             "4x4":
            if let collectionView = collectionView {
                ds = DATASource(collectionView: collectionView, cellIdentifier: "CardImageCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: searchSectionName, configuration: { cell, item, indexPath in
                    if let card = item as? CMCard {
                        if let imageView = cell.viewWithTag(100) as? UIImageView {
                            imageView.image = ManaKit.sharedInstance.cardImage(card)
                            
                            // TODO: fix multiple image loading if scrolling fast
                            if imageView.image == ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.cardBack) {
                                ManaKit.sharedInstance.downloadCardImage(card, cropImage: true, completion: { (c: CMCard, image: UIImage?, croppedImage: UIImage?, error: NSError?) in
                                    if error == nil {
                                        if card == self.dataSource!.object(indexPath) {
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
                    }
                })
            }
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
            
            let defaults = defaultsValue()
            let searchSectionName = defaults["searchSectionName"] as! String
            
            switch searchSectionName {
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
                        let prefix = String(typeSection.characters.prefix(1))
                        
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
            var searchOrderBy = defaults["searchOrderBy"] as! Bool
            var searchDisplayBy = defaults["searchDisplayBy"] as! String
            
            if let value = userInfo["searchSortBy"] as? String {
                searchSortBy = value
                
                switch searchSortBy {
                case "name":
                    searchSectionName = "nameSection"
                case "typeSection":
                    searchSectionName = "typeSection"
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
            UserDefaults.standard.set(searchOrderBy, forKey: "searchOrderBy")
            UserDefaults.standard.set(searchDisplayBy, forKey: "searchDisplayBy")
            UserDefaults.standard.synchronize()
            
            updateDataDisplay()
        }
    }

    func scrollToCard(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let card = userInfo["card"] as? CMCard,
                let dataSource = dataSource {
                let defaults = defaultsValue()
                let searchDisplayBy = defaults["searchDisplayBy"] as! String
                
                switch searchDisplayBy {
                case "list":
                    for i in 0...dataSource.numberOfSections(in: tableView) - 1{
                        for j in 0...tableView.numberOfRows(inSection: i) - 1 {
                            let indexPath = IndexPath(row: j, section: i)
                            
                            if  let visible = tableView.indexPathsForVisibleRows?.contains(indexPath) {
                                if !visible {
                                    if dataSource.object(indexPath) == card {
                                        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                                    }
                                }
                            }
                        }
                    }
                case "2x2",
                     "4x4":
                    if let collectionView = collectionView {
                        for i in 0...dataSource.numberOfSections(in: collectionView) - 1{
                            for j in 0...collectionView.numberOfItems(inSection: i) - 1 {
                                let indexPath = IndexPath(row: j, section: i)
                                
                                if  !collectionView.indexPathsForVisibleItems.contains(indexPath) {
                                    if dataSource.object(indexPath) == card {
                                        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                                    }
                                }
                            }
                        }
                    }
                default:
                    ()
                }
            }
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
        
        // filters
        // keyword
        if let value = UserDefaults.standard.value(forKey: "searchKeywordName") as? Bool {
            values["searchKeywordName"] = value
        } else {
            values["searchKeywordName"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchKeywordText") as? Bool {
            values["searchKeywordText"] = value
        } else {
            values["searchKeywordText"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchKeywordFlavor") as? Bool {
            values["searchKeywordFlavor"] = value
        } else {
            values["searchKeywordFlavor"] = true
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
        
        // color
        if let value = UserDefaults.standard.value(forKey: "searchColorBlack") as? Bool {
            values["searchColorBlack"] = value
        } else {
            values["searchColorBlack"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorBlue") as? Bool {
            values["searchColorBlue"] = value
        } else {
            values["searchColorBlue"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorGreen") as? Bool {
            values["searchColorGreen"] = value
        } else {
            values["searchColorGreen"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorRed") as? Bool {
            values["searchColorRed"] = value
        } else {
            values["searchColorRed"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorWhite") as? Bool {
            values["searchColorWhite"] = value
        } else {
            values["searchColorWhite"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorColorless") as? Bool {
            values["searchColorColorless"] = value
        } else {
            values["searchColorColorless"] = true
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
        
        return values
    }
    
    func createSearchRequeat() -> NSFetchRequest<NSFetchRequestResult>? {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
        var predicate: NSPredicate?
        var subpredicates = [NSPredicate]()
        
        let defaults = defaultsValue()
        
        // displayers
        let searchSectionName = defaults["searchSectionName"] as! String
        let searchSortBy = defaults["searchSortBy"] as! String
        let searchOrderBy = defaults["searchOrderBy"] as! Bool
        
        // keyword filters
        let searchKeywordName = defaults["searchKeywordName"] as! Bool
        let searchKeywordText = defaults["searchKeywordText"] as! Bool
        let searchKeywordFlavor = defaults["searchKeywordFlavor"] as! Bool
        let searchKeywordBoolean = defaults["searchKeywordBoolean"] as! String
        let searchKeywordNot = defaults["searchKeywordNot"] as! Bool

        // color filters
        let searchColorBlack = defaults["searchColorBlack"] as! Bool
        let searchColorBlue = defaults["searchColorBlue"] as! Bool
        let searchColorGreen = defaults["searchColorGreen"] as! Bool
        let searchColorRed = defaults["searchColorRed"] as! Bool
        let searchColorWhite = defaults["searchColorWhite"] as! Bool
        let searchColorColorless = defaults["searchColorColorless"] as! Bool
        let searchColorBoolean = defaults["searchColorBoolean"] as! String
        let searchColorNot = defaults["searchColorNot"] as! Bool
        
        
        // process keyword filter
        if searchKeywordName {
            if let text = searchBar?.text {
                // if only 1 letter, search beginning letter else search containg letters
                if text.characters.count == 1 {
                    subpredicates.append(NSPredicate(format: "name BEGINSWITH[cd] %@", text))
                } else if text.characters.count > 1  {
                    subpredicates.append(NSPredicate(format: "name CONTAINS[cd] %@", text))
                }
            }
        }
        if searchKeywordText {
            if let text = searchBar?.text {
                // if only 1 letter, search beginning letter else search containg letters
                if text.characters.count == 1 {
                    subpredicates.append(NSPredicate(format: "text BEGINSWITH[cd] %@ OR originalText BEGINSWITH[cd] %@", text, text))
                } else if text.characters.count > 1 {
                    subpredicates.append(NSPredicate(format: "text CONTAINS[cd] %@ OR originalText CONTAINS[cd] %@", text, text))
                }
            }
        }
        if searchKeywordFlavor {
            if let text = searchBar?.text {
                // if only 1 letter, search beginning letter else search containg letters
                if text.characters.count == 1 {
                    subpredicates.append(NSPredicate(format: "flavor BEGINSWITH[cd] %@", text))
                } else if text.characters.count > 1 {
                    subpredicates.append(NSPredicate(format: "flavor CONTAINS[cd] %@", text))
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
        
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: searchSectionName, ascending: searchOrderBy),
                                    NSSortDescriptor(key: searchSortBy, ascending: searchOrderBy)]
        
        return request
    }
    
    func doSearch() {
        searchBar.resignFirstResponder()
        dataSource = getDataSource(createSearchRequeat())
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
        case "2x2",
             "4x4":
            if let c = tableView.dequeueReusableCell(withIdentifier: "GridCell") {
                if let collectionView = c.viewWithTag(100) as? UICollectionView {
                    self.collectionView = collectionView
                    collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
                    collectionView.delegate = self
                    
                    if let bgImage = ManaKit.sharedInstance.imageFromFramework(imageName: ImageName.grayPatterned) {
                        collectionView.backgroundColor = UIColor(patternImage: bgImage)
                    }
                    
                    if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                        var width = tableView.frame.size.width
                        var height = tableView.frame.size.height - kCardTableViewCellHeight - CGFloat(44)
                        
                        if searchDisplayBy == "2x2" {
                            width = width / 2
                            height = height / 2
                        } else if searchDisplayBy == "4x4" {
                            width = width / 4
                            height = height / 4
                        }
                        
                        flowLayout.itemSize = CGSize(width: width, height: height)
                        flowLayout.minimumInteritemSpacing = CGFloat(0)
                        flowLayout.minimumLineSpacing = CGFloat(5)
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
        case "2x2",
             "4x4":
            height = tableView.frame.size.height - searchBar.frame.size.height
        default:
            ()
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = dataSource!.object(indexPath)
        let cards = dataSource!.all()
        let cardIndex = cards.index(of: card!)
        
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
        case "2x2",
             "4x4":
            dataSource = getDataSource(createSearchRequeat())
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
                if searchOrderBy {
                    sectionIndex = i
                } else {
                    sectionIndex = (sectionTitles.count - 1) - i
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
        let card = dataSource!.object(indexPath)
        let cards = dataSource!.all()
        let cardIndex = cards.index(of: card!)
        
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

