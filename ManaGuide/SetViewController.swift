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
        
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .gear, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        rightMenuButton.title = nil
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"), forCellReuseIdentifier: "CardCell")
        tableView.register(UINib(nibName: "BrowserTableViewCell", bundle: nil), forCellReuseIdentifier: "SetInfoCell")
        
        updateDataDisplay()
    }

    // MARK: Custom methods
    func updateDataDisplay() {
        let defaults = defaultsValue()
//        let setSectionName = defaults["setSectionName"] as! String
//        let setSortBy = defaults["setSortBy"] as! String
//        let setOrderBy = defaults["setOrderBy"] as! Bool
//        let setDisplayBy = defaults["setDisplayBy"] as! String
        let setShow = defaults["setShow"] as! String
        
        if setShow == "cards" {
            dataSource = getDataSource(nil)
            updateSections()
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
        let setSortBy = defaults["setSortBy"] as! String
        let setOrderBy = defaults["setOrderBy"] as! Bool
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = NSFetchRequest(entityName: "CMCard")
            
            request!.sortDescriptors = [NSSortDescriptor(key: setSectionName, ascending: setOrderBy),
                                        NSSortDescriptor(key: setSortBy, ascending: setOrderBy)]
            request!.predicate = NSPredicate(format: "set.code = %@", set!.code!)
        }
        
        let dataSource = DATASource(tableView: tableView, cellIdentifier: "CardCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: setSectionName, configuration: { cell, item, indexPath in
            if let card = item as? CMCard,
                let cardCell = cell as? CardTableViewCell {
                
                cardCell.card = card
                cardCell.updateDataDisplay()
            }
        })
    
        dataSource.delegate = self
        return dataSource
    }
    
    func updateSections() {
        if let dataSource = dataSource {
            let cards = dataSource.all() as [CMCard]
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
            
            let defaults = defaultsValue()
            let setSectionName = defaults["setSectionName"] as! String
            
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
            
            for i in 0...dataSource.numberOfSections(in: tableView) - 1 {
                if let sectionTitle = dataSource.titleForHeader(i) {
                    sectionTitles.append(sectionTitle)
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
            var setOrderBy = defaults["setOrderBy"] as! Bool
            var setDisplayBy = defaults["setDisplayBy"] as! String
            var setShow = defaults["setShow"] as! String
            
            if let value = userInfo["setSortBy"] as? String {
                setSortBy = value
                
                switch setSortBy {
                case "name":
                    setSectionName = "nameSection"
                case "mciNumber":
                    setSectionName = "numberSection"
                case "typeSection":
                    setSectionName = "typeSection"
                case "artist_.name":
                    setSectionName = "artist_.name"
                default:
                    ()
                }
            }
            
            if let value = userInfo["setOrderBy"] as? Bool {
                setOrderBy = value
            }
            
            // TODO: implement these
            if let value = userInfo["setDisplayBy"] as? String {
                setDisplayBy = value
            }
            
            if let value = userInfo["setShow"] as? String {
                setShow = value
            }
            
            UserDefaults.standard.set(setSectionName, forKey: "setSectionName")
            UserDefaults.standard.set(setSortBy, forKey: "setSortBy")
            UserDefaults.standard.set(setOrderBy, forKey: "setOrderBy")
            UserDefaults.standard.set(setDisplayBy, forKey: "setDisplayBy")
            UserDefaults.standard.set(setShow, forKey: "setShow")
            UserDefaults.standard.synchronize()
            
            updateDataDisplay()
        }
    }
    
    func defaultsValue() -> [String: Any] {
        var values = [String: Any]()
        var setSectionName = "nameSection"
        var setSortBy = "name"
        var setOrderBy = true
        var setDisplayBy = "list"
        var setShow = "cards"
        
        if let value = UserDefaults.standard.value(forKey: "setSectionName") as? String {
            setSectionName = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "setSortBy") as? String {
            setSortBy = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "setOrderBy") as? Bool {
            setOrderBy = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "setDisplayBy") as? String {
            setDisplayBy = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "setShow") as? String {
            setShow = value
        }
        
        values["setSectionName"] = setSectionName
        values["setSortBy"] = setSortBy
        values["setOrderBy"] = setOrderBy
        values["setDisplayBy"] = setDisplayBy
        values["setShow"] = setShow
        
        return values
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
        
        return URL(string: "http://mtg.gamepedia.com/\(path)")
    }

}

// MARK: UITableViewDataSource
extension SetViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let defaults = defaultsValue()
        let setShow = defaults["setShow"] as! String
        var rows = 0
        
        switch setShow {
        case "setInfo":
            rows = 1
        default:
            ()
        }
            
        return rows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaults = defaultsValue()
        let setShow = defaults["setShow"] as! String
        var cell: UITableViewCell?
        
        switch setShow {
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
        let setShow = defaults["setShow"] as! String
        var height = CGFloat(0)
        
        switch setShow {
        case "cards":
            height = kCardTableViewCellHeight
        case "setInfo":
            height = tableView.frame.size.height
        default:
            ()
        }
        
        return height
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
