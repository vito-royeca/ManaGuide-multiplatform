//
//  SetViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import FontAwesome_swift
import InAppSettingsKit
import ManaKit
import MBProgressHUD

class SetViewController: BaseViewController {

    // MARK: Variables
    var set:CMSet?
    var dataSource: DATASource?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()
    var collectionView: UICollectionView?
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    @IBAction func showRightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Set")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetViewController.updateData(_:)), name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kNotificationSwipedToCard), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetViewController.scrollToCard(_:)), name: NSNotification.Name(rawValue: kNotificationSwipedToCard), object: nil)
        
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .gear, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        rightMenuButton.title = nil
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        tableView.register(UINib(nibName: "BrowserTableViewCell", bundle: nil), forCellReuseIdentifier: "SetInfoCell")
        
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
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateDataDisplay()
    }
    
    // MARK: Custom methods
    func updateDataDisplay() {
        let defaults = defaultsValue()
        let setDisplayBy = defaults["setDisplayBy"] as! String
        let setShow = defaults["setShow"] as! String
        
        if setShow == "cards" {
            switch setDisplayBy {
            case "list":
                dataSource = getDataSource(nil)
                updateSections()
            case "2x2",
                 "4x4":
                tableView.dataSource = self
            default:
                ()
            }
        } else {
            tableView.dataSource = self
        }

        tableView.delegate = self
        tableView.reloadData()
    }
    
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        var request:NSFetchRequest<NSFetchRequestResult>?
        let defaults = defaultsValue()
        let setSectionName = defaults["setSectionName"] as! String
        let setSecondSortBy = defaults["setSecondSortBy"] as! String
        let setOrderBy = defaults["setOrderBy"] as! Bool
        let setDisplayBy = defaults["setDisplayBy"] as! String
        var ds: DATASource?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = NSFetchRequest(entityName: "CMCard")
            
            request!.sortDescriptors = [NSSortDescriptor(key: setSectionName, ascending: setOrderBy),
                                        NSSortDescriptor(key: setSecondSortBy, ascending: setOrderBy)]
            request!.predicate = NSPredicate(format: "set.code = %@", set!.code!)
        }
        
        switch setDisplayBy {
        case "list":
            ds = DATASource(tableView: tableView, cellIdentifier: "CardCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: setSectionName == "numberSection" ? nil : setSectionName, configuration: { cell, item, indexPath in
                if let card = item as? CMCard,
                    let cardCell = cell as? CardTableViewCell {
                    
                    cardCell.card = card
                    cardCell.updateDataDisplay()
                }
            })
        case "2x2",
             "4x4":
            if let collectionView = collectionView {
                ds = DATASource(collectionView: collectionView, cellIdentifier: "CardImageCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: setSectionName == "numberSection" ? nil : setSectionName, configuration: { cell, item, indexPath in
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
            let setSectionName = defaults["setSectionName"] as! String
            let setDisplayBy = defaults["setDisplayBy"] as! String
            let setShow = defaults["setShow"] as! String
            
            switch setSectionName {
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
            case "rarity_.name":
                for card in cards {
                    if let rarity = card.rarity_ {
                        let prefix = String(rarity.name!.characters.prefix(1))
                        
                        if !sectionIndexTitles.contains(prefix) {
                            sectionIndexTitles.append(prefix)
                        }
                    }
                }
            case "artist_.name":
                for card in cards {
                    if let artist = card.artist_ {
                        let prefix = String(artist.name!.characters.prefix(1))
                        
                        if !sectionIndexTitles.contains(prefix) {
                            sectionIndexTitles.append(prefix)
                        }
                    }
                }
            default:
                ()
            }
            
            
            var sections = 0
            if setShow == "cards" {
                switch setDisplayBy {
                case "list":
                    sections = dataSource.numberOfSections(in: tableView)
                case "2x2",
                     "4x4":
                    if let collectionView = collectionView {
                        sections = dataSource.numberOfSections(in: collectionView)
                    }
                default:
                    ()
                }
            }
            
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
            var setSectionName = defaults["setSectionName"] as! String
            var setSortBy = defaults["setSortBy"] as! String
            var setSecondSortBy = defaults["setSecondSortBy"] as! String
            var setOrderBy = defaults["setOrderBy"] as! Bool
            var setDisplayBy = defaults["setDisplayBy"] as! String
            var setShow = defaults["setShow"] as! String
            
            if let value = userInfo["setSortBy"] as? String {
                setSortBy = value
                
                switch setSortBy {
                case "name":
                    setSectionName = "nameSection"
                    setSecondSortBy = "name"
                case "mciNumber":
                    setSectionName = "numberSection"
                    setSecondSortBy = "name"
                case "typeSection":
                    setSectionName = "typeSection"
                    setSecondSortBy = "name"
                case "rarity_.name":
                    setSectionName = "rarity_.name"
                    setSecondSortBy = "name"
                case "artist_.name":
                    setSectionName = "artist_.name"
                    setSecondSortBy = "name"
                default:
                    ()
                }
            }
            
            if let value = userInfo["setOrderBy"] as? Bool {
                setOrderBy = value
            }
            
            if let value = userInfo["setDisplayBy"] as? String {
                setDisplayBy = value
            }
            
            if let value = userInfo["setShow"] as? String {
                setShow = value
            }
            
            UserDefaults.standard.set(setSectionName, forKey: "setSectionName")
            UserDefaults.standard.set(setSortBy, forKey: "setSortBy")
            UserDefaults.standard.set(setSecondSortBy, forKey: "setSecondSortBy")
            UserDefaults.standard.set(setOrderBy, forKey: "setOrderBy")
            UserDefaults.standard.set(setDisplayBy, forKey: "setDisplayBy")
            UserDefaults.standard.set(setShow, forKey: "setShow")
            UserDefaults.standard.synchronize()
            
            updateDataDisplay()
        }
    }
    
    func defaultsValue() -> [String: Any] {
        var values = [String: Any]()
        
        if let value = UserDefaults.standard.value(forKey: "setSectionName") as? String {
            values["setSectionName"] = value
        } else {
            values["setSectionName"] = "nameSection"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setSortBy") as? String {
            values["setSortBy"] = value
        } else {
            values["setSortBy"] = "name"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setSecondSortBy") as? String {
            values["setSecondSortBy"] = value
        } else {
            values["setSecondSortBy"] = "name"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setOrderBy") as? Bool {
            values["setOrderBy"] = value
        } else {
            values["setOrderBy"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "setDisplayBy") as? String {
            values["setDisplayBy"] = value
        } else {
            values["setDisplayBy"] = "list"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setShow") as? String {
            values["setShow"] = value
        } else {
            values["setShow"] = "cards"
        }
        
        return values
    }
    
    func scrollToCard(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let card = userInfo["card"] as? CMCard,
                let dataSource = dataSource {
                let defaults = defaultsValue()
                let setDisplayBy = defaults["setDisplayBy"] as! String
                let setShow = defaults["setShow"] as! String
                
                if setShow == "cards" {
                    switch setDisplayBy {
                    case "list":
                        for i in 0...dataSource.numberOfSections(in: tableView) - 1{
                            for j in 0...tableView.numberOfRows(inSection: i) - 1 {
                                let indexPath = IndexPath(row: j, section: i)
                                if dataSource.object(indexPath) == card {
                                    tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                                }
                            }
                        }
                    case "2x2",
                         "4x4":
                        if let collectionView = collectionView {
                            for i in 0...dataSource.numberOfSections(in: collectionView) - 1{
                                for j in 0...collectionView.numberOfItems(inSection: i) - 1 {
                                    let indexPath = IndexPath(row: j, section: i)
                                    if dataSource.object(indexPath) == card {
                                        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
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
                path = name.replacingOccurrences(of: " ", with: "_")
            }
        }
        
        return URL(string: "https://mtg.gamepedia.com/\(path)")
    }
}

// MARK: UITableViewDataSource
extension SetViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = 1
        
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaults = defaultsValue()
        let setDisplayBy = defaults["setDisplayBy"] as! String
        let setShow = defaults["setShow"] as! String
        var cell: UITableViewCell?
        
        switch setShow {
        case "cards":
            switch setDisplayBy {
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
                            
                            if setDisplayBy == "2x2" {
                                width = width / 2
                                height = height / 2
                            } else if setDisplayBy == "4x4" {
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
        case "setInfo":
            if let c = tableView.dequeueReusableCell(withIdentifier: "SetInfoCell") as? BrowserTableViewCell,
                let set = set {
                c.webView.delegate = self
                let request = URLRequest(url: wikiURL(ofSet: set)!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0)
                c.webView.loadRequest(request)
                cell = c
            }
        default:
            ()
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension SetViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let defaults = defaultsValue()
        let setDisplayBy = defaults["setDisplayBy"] as! String
        let setShow = defaults["setShow"] as! String
        var height = CGFloat(0)
        
        switch setShow {
        case "cards":
            switch setDisplayBy {
            case "list":
                height = kCardTableViewCellHeight
            case "2x2":
                height = tableView.frame.size.height
            case "4x4":
                height = tableView.frame.size.height
            default:
                ()
            }
        case "setInfo":
            height = tableView.frame.size.height
        default:
            ()
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let defaults = defaultsValue()
        let setShow = defaults["setShow"] as! String
        
        switch setShow {
        case "cards":
            let card = dataSource!.object(indexPath)
            let cards = dataSource!.all()
            let cardIndex = cards.index(of: card!)
            
            performSegue(withIdentifier: "showCard", sender: ["cardIndex": cardIndex as Any,
                                                              "cards": cards])
        default:
            ()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let defaults = defaultsValue()
        let setDisplayBy = defaults["setDisplayBy"] as! String
        let setShow = defaults["setShow"] as! String

        if setShow == "cards" {
            switch setDisplayBy {
            case "2x2",
                 "4x4":
                dataSource = getDataSource(nil)
                updateSections()
            default:
                ()
            }
        }
    }
}

// MARK: DATASourceDelegate
extension SetViewController : DATASourceDelegate {
    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
    func sectionIndexTitlesForDataSource(_ dataSource: DATASource, tableView: UITableView) -> [String] {
        return sectionIndexTitles
    }
    
    // tell table which section corresponds to section title/index (e.g. "B",1))
    func dataSource(_ dataSource: DATASource, tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        let defaults = defaultsValue()
        let setOrderBy = defaults["setOrderBy"] as! Bool
        var sectionIndex = 0
        
        for i in 0...sectionTitles.count - 1 {
            if sectionTitles[i].hasPrefix(title) {
                if setOrderBy {
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
                let defaults = defaultsValue()
                let setOrderBy = defaults["setOrderBy"] as! Bool
                var sectionTitle: String?
                
                if setOrderBy {
                    sectionTitle = sectionTitles[indexPath.section]
                } else {
                    sectionTitle = sectionTitles[sectionTitles.count - 1 - indexPath.section]
                }
                
                lab.text = sectionTitle
            }
        }
        
        return v
    }
}

// UICollectionViewDelegate
extension SetViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = dataSource!.object(indexPath)
        let cards = dataSource!.all()
        let cardIndex = cards.index(of: card!)
        
        performSegue(withIdentifier: "showCard", sender: ["cardIndex": cardIndex as Any,
                                                          "cards": cards])
    }
}

// MARK: UIWebViewDelegate
extension SetViewController : UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        var willLoad = false
        if let url = request.url {
            if let host = url.host {
                if host.hasPrefix("mtg.gamepedia.com") {
                    willLoad = true
                } else if host.hasPrefix("www.magiccards.info") {
                    // TODO: show the card instead of jumping to link!!!
                    let urlComponents = URLComponents(string: url.absoluteString)
                    let queryItems = urlComponents?.queryItems
                    let q = queryItems?.filter({$0.name == "q"}).first
                    if let value = q?.value {
                        let r = value.index(value.startIndex, offsetBy: 1)
                        let cardName = value.substring(from: r).replacingOccurrences(of: "+", with: " ")
                        
                        print("\(cardName)")
                    }
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
        
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BrowserTableViewCell {
            cell.backButton.isEnabled = webView.canGoBack
            cell.forwardButton.isEnabled = webView.canGoForward
            cell.refreshButton.isEnabled = true
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        MBProgressHUD.hide(for: webView, animated: true)
        
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BrowserTableViewCell {
            cell.backButton.isEnabled = webView.canGoBack
            cell.forwardButton.isEnabled = webView.canGoForward
            cell.refreshButton.isEnabled = true
        }
        
        var html = "<html><body><center>"
        html.append(error.localizedDescription)
        html.append("</center></body></html>")
        webView.loadHTMLString(html, baseURL: nil)
    }
}
