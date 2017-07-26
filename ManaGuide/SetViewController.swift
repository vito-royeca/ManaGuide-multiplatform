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

enum SetDisplayType {
    case list,
    _2x2,
    _4x4,
    setInfo
}

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
        tableView.register(ManaKit.sharedInstance.nibFromBundle("BrowserTableViewCell"), forCellReuseIdentifier: "SetInfoCell")
        
        updateDataDisplay()
    }

    // MARK: Custom methods
    func updateDataDisplay() {
        let defaults = defaultsValue()
        
//        if let setDisplayType = defaults["setDisplayType"] as? SetDisplayType {
//            switch setDisplayType {
//            case .list,
//                 ._2x2,
//                 ._4x4:
//                dataSource = getDataSource(nil)
//            case .setInfo:
//                tableView.dataSource = self
//                tableView.delegate = self
//                ()
//            }
//        }

        dataSource = getDataSource(nil)
        updateSections()
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
                
                UserDefaults.standard.set(setSectionName, forKey: "setSectionName")
                UserDefaults.standard.synchronize()
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
            
            let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
            request.predicate = NSPredicate(format: "set.code = %@", set!.code!)
            request.sortDescriptors = [NSSortDescriptor(key: setSectionName, ascending: setOrderBy),
                                        NSSortDescriptor(key: setSortBy, ascending: setOrderBy)]

            dataSource = getDataSource(request)
            updateSections()
            tableView.reloadData()
        }
    }
    
    func defaultsValue() -> [String: Any] {
        var values = [String: Any]()
        var setSectionName = "nameSection"
        var setSortBy = "name"
        var setOrderBy = true
        var setDisplayBy = "list"
        var setShow = "cards"
//        var setDisplayType:SetDisplayType = .list
        
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
//        values["setDisplayType"] = setDisplayType
        
        return values
    }

}

// MARK: UITableViewDataSource
//extension SetViewController : UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let defaults = defaultsValue()
//        let setDisplayBy = defaults["setDisplayBy"] as! NSNumber
//        let setShow = defaults["setShow"] as! NSNumber
//        var rows = 0
//        
//        switch setDisplayBy {
//        case 1:
//            ()
//        case 2:
//            ()
//        default:
//            ()
//        }
//            
//        return rows
//    }
//    
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "SetInfoCell")
//        
//        return cell!
//    }
//}

// MARK: UITableViewDelegate
extension SetViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kCardTableViewCellHeight
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
