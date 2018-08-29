//
//  SetsViewController.swift
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

class SetsViewController: BaseViewController {

    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var fetchedResultsController: NSFetchedResultsController<CMSet>?
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
            guard let dest = segue.destination as? SetViewController,
                let set = sender as? CMSet else {
                return
            }
            
            dest.set = set
            dest.title = set.name
        }
    }

    // MARK: Custom methods
    func updateDataDisplay() {
        fetchedResultsController = getFetchedResultsController(with: nil)
        updateSections()
        tableView.reloadData()
    }
    
    func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMSet>?) -> NSFetchedResultsController<CMSet> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMSet>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // Create a default fetchRequest
            request = CMSet.fetchRequest()
            request!.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
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
    
    func updateSections() {
        guard let fetchedResultsController = fetchedResultsController,
            let sets = fetchedResultsController.fetchedObjects,
            let sections = fetchedResultsController.sections else {
                return
        }
        
        
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
        
        let count = sections.count
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
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        
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
        guard let text = searchController.searchBar.text else {
            return
        }
        
        var newRequest: NSFetchRequest<CMSet>?
        let defaults = defaultsValue()
        let setsSectionName = defaults["setsSectionName"] as! String
        let setsSecondSortBy = defaults["setsSecondSortBy"] as! String
        let setsOrderBy = defaults["setsOrderBy"] as! Bool
        
        if text.count > 0 {
            newRequest = CMSet.fetchRequest()
            
            newRequest!.sortDescriptors = [NSSortDescriptor(key: setsSectionName, ascending: setsOrderBy),
                                        NSSortDescriptor(key: setsSecondSortBy, ascending: setsOrderBy)]
            
            if text.count == 1 {
                newRequest!.predicate = NSPredicate(format: "name BEGINSWITH[cd] %@", text)
            } else if text.count > 1 {
                newRequest!.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR code CONTAINS[cd] %@", text, text)
            }
            fetchedResultsController = getFetchedResultsController(with: newRequest)
            updateSections()
            tableView.reloadData()
            
        } else {
            fetchedResultsController = getFetchedResultsController(with: nil)
            updateSections()
            tableView.reloadData()
        }
    }
}

// MARK: UITableViewDataSource
extension SetsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let sets = fetchedResultsController.fetchedObjects else {
                return 0
        }
        
        return sets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("Unexpected indexPath: \(indexPath)")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "SetCell",
                                                 for: indexPath)
        let set = fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
        guard let label100 = cell.contentView.viewWithTag(100) as? UILabel,
            let label200 = cell.contentView.viewWithTag(200) as? UILabel,
            let label300 = cell.contentView.viewWithTag(300) as? UILabel,
            let label400 = cell.contentView.viewWithTag(400) as? UILabel,
            let label500 = cell.contentView.viewWithTag(500) as? UILabel else {
            fatalError("UILabel not found")
        }
        
        label100.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
        label100.textColor = UIColor.black
        label200.text = set.name
        label200.adjustsFontSizeToFitWidth = true
        label300.text = set.code
        label300.adjustsFontSizeToFitWidth = true
        label400.text = set.releaseDate
        label400.adjustsFontSizeToFitWidth = true
        label500.text = "\(set.cards!.allObjects.count) cards"
        label500.adjustsFontSizeToFitWidth = true
        
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
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

// MARK: UITableViewDelegate
extension SetsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let fetchedResultsController = fetchedResultsController else {
            return
        }
        
        let set = fetchedResultsController.object(at: indexPath)
        performSegue(withIdentifier: "showSet", sender: set)
    }
}

// MARK: UISearchResultsUpdating
extension SetsViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension SetsViewController : NSFetchedResultsControllerDelegate {
    
}

