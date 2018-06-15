//
//  SetsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import Font_Awesome_Swift
import InAppSettingsKit
import ManaKit

class SetsViewController: BaseViewController {

    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var dataSource: DATASource?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Sets")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateData(_:)), name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object: nil)
        
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

        tableView.keyboardDismissMode = .onDrag
        
        updateDataDisplay()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSet" {
            if let dest = segue.destination as? SetViewController,
                let set = sender as? CMSet {
                
                dest.set = set
                dest.title = set.name
            }
        }
    }

    // MARK: Custom methods
    func updateDataDisplay() {
        dataSource = getDataSource(nil)
        updateSections()
        tableView.reloadData()
    }
    
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        var request:NSFetchRequest<NSFetchRequestResult>?
        let defaults = defaultsValue()
        let setsSectionName = defaults["setsSectionName"] as! String
        let setsSecondSortBy = defaults["setsSecondSortBy"] as! String
        let setsOrderBy = defaults["setsOrderBy"] as! Bool
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = NSFetchRequest(entityName: "CMSet")
            request!.sortDescriptors = [NSSortDescriptor(key: setsSectionName, ascending: setsOrderBy),
                                        NSSortDescriptor(key: setsSecondSortBy, ascending: setsOrderBy)]
        }
        
        let ds = DATASource(tableView: tableView, cellIdentifier: "SetCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: setsSectionName, configuration: { cell, item, indexPath in
            if let set = item as? CMSet {
                if let label = cell.contentView.viewWithTag(100) as? UILabel {
                    label.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
                    label.textColor = UIColor.black
                }
                if let label = cell.contentView.viewWithTag(200) as? UILabel {
                    label.text = set.name
                    label.adjustsFontSizeToFitWidth = true
                }
                if let label = cell.contentView.viewWithTag(300) as? UILabel {
                    label.text = set.code
                    label.adjustsFontSizeToFitWidth = true
                }
                if let label = cell.contentView.viewWithTag(400) as? UILabel {
                    label.text = set.releaseDate
                    label.adjustsFontSizeToFitWidth = true
                }
                if let label = cell.contentView.viewWithTag(500) as? UILabel {
                    label.text = "\(set.cards!.allObjects.count) cards"
                    label.adjustsFontSizeToFitWidth = true
                }
            }
        })
        
        ds.delegate = self
        return ds
    }

    func updateSections() {
        if let dataSource = dataSource {
            let sets = dataSource.all() as [CMSet]
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
            
            let defaults = defaultsValue()
            let setsSectionName = defaults["setsSectionName"] as! String
            
            switch setsSectionName {
            case "nameSection":
                for set in sets {
                    if let nameSection = set.nameSection {
                        if !sectionIndexTitles.contains(nameSection) {
                            sectionIndexTitles.append(nameSection)
                        }
                    }
                }
                
            case "typeSection":
                for set in sets {
                    if let type_ = set.type_ {
                        let prefix = String(type_.name!.prefix(1)).uppercased()
                    
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
            var setsSectionName = defaults["setsSectionName"] as! String
            var setsSortBy = defaults["setsSortBy"] as! String
            var setsSecondSortBy = defaults["setsSecondSortBy"] as! String
            var setsOrderBy = defaults["setsOrderBy"] as! Bool
            
            if let value = userInfo["setsSortBy"] as? String {
                setsSortBy = value
                
                switch setsSortBy {
                case "releaseDate":
                    setsSectionName = "yearSection"
                    setsSecondSortBy = "releaseDate"
                case "name":
                    setsSectionName = "nameSection"
                    setsSecondSortBy = "name"
                case "type_.name":
                    setsSectionName = "typeSection"
                    setsSecondSortBy = "name"
                default:
                    ()
                }
            }
            
            if let value = userInfo["setsOrderBy"] as? Bool {
                setsOrderBy = value
            }
            
            UserDefaults.standard.set(setsSectionName, forKey: "setsSectionName")
            UserDefaults.standard.set(setsSortBy, forKey: "setsSortBy")
            UserDefaults.standard.set(setsSecondSortBy, forKey: "setsSecondSortBy")
            UserDefaults.standard.set(setsOrderBy, forKey: "setsOrderBy")
            UserDefaults.standard.synchronize()
            
            updateDataDisplay()
        }
    }
    
    func defaultsValue() -> [String: Any] {
        var values = [String: Any]()
        
        if let value = UserDefaults.standard.value(forKey: "setsSectionName") as? String {
            values["setsSectionName"] = value
        } else {
            values["setsSectionName"] = "yearSection"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setsSortBy") as? String {
            values["setsSortBy"] = value
        } else {
            values["setsSortBy"] = "releaseDate"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setsSecondSortBy") as? String {
            values["setsSecondSortBy"] = value
        } else {
            values["setsSecondSortBy"] = "releaseDate"
        }
        
        if let value = UserDefaults.standard.value(forKey: "setsOrderBy") as? Bool {
            values["setsOrderBy"] = value
        } else {
            values["setsOrderBy"] = false
        }

        return values
    }
    
    func doSearch() {
        var newRequest:NSFetchRequest<NSFetchRequestResult>?
        let defaults = defaultsValue()
        let setsSectionName = defaults["setsSectionName"] as! String
        let setsSecondSortBy = defaults["setsSecondSortBy"] as! String
        let setsOrderBy = defaults["setsOrderBy"] as! Bool
        
        if let text = searchController.searchBar.text {
            if text.count > 0 {
                newRequest = NSFetchRequest(entityName: "CMSet")
                
                newRequest!.sortDescriptors = [NSSortDescriptor(key: setsSectionName, ascending: setsOrderBy),
                                            NSSortDescriptor(key: setsSecondSortBy, ascending: setsOrderBy)]
                
                if text.count == 1 {
                    newRequest!.predicate = NSPredicate(format: "name BEGINSWITH[cd] %@", text)
                } else if text.count > 1 {
                    newRequest!.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR code CONTAINS[cd] %@", text, text)
                }
                dataSource = getDataSource(newRequest)
                updateSections()
                tableView.reloadData()
                
            } else {
                dataSource = getDataSource(nil)
                updateSections()
                tableView.reloadData()
            }
        }
    }
}

// MARK: UITableViewDelegate
extension SetsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let set = dataSource!.object(indexPath)
        performSegue(withIdentifier: "showSet", sender: set)
    }
}

// MARK: DATASourceDelegate
extension SetsViewController : DATASourceDelegate {
    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
    func sectionIndexTitlesForDataSource(_ dataSource: DATASource, tableView: UITableView) -> [String] {
        return sectionIndexTitles
    }
    
    // tell table which section corresponds to section title/index (e.g. "B",1))
    func dataSource(_ dataSource: DATASource, tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        let defaults = defaultsValue()
        let setsOrderBy = defaults["setsOrderBy"] as! Bool
        var sectionIndex = 0
        
        for i in 0...sectionTitles.count - 1 {
            if sectionTitles[i].hasPrefix(title) {
                if setsOrderBy {
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

// MARK: UISearchResultsUpdating
extension SetsViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}


