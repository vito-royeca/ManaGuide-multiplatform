//
//  ArtistsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 19/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import ManaKit

class ArtistsViewController: UIViewController {

    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var dataSource: DATASource?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        
        tableView.keyboardDismissMode = .onDrag
        
        dataSource = getDataSource(nil)
        updateSections()
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearch" {
            if let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any] {
                
                dest.request = dict["request"] as? NSFetchRequest<NSFetchRequestResult>
                dest.title = dict["title"] as? String
            }
        }
    }
    
    // MARK: Custom methods
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        var request:NSFetchRequest<NSFetchRequestResult>?
        var ds: DATASource?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = NSFetchRequest(entityName: "CMArtist")
            
            request!.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                        NSSortDescriptor(key: "lastName", ascending: true),
                                        NSSortDescriptor(key: "firstName", ascending: true)]
        }
        
        ds = DATASource(tableView: tableView, cellIdentifier: "Cell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: "nameSection", configuration: { cell, item, indexPath in
            if let artist = item as? CMArtist {
                cell.textLabel?.text = artist.name
            }
        })
        
        if let ds = ds {
            ds.delegate = self
            return ds
        }
        return nil
    }
    
    func updateSections() {
        if let dataSource = dataSource {
            let artists = dataSource.all() as [CMArtist]
            let letters = CharacterSet.letters
            
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
            
            for artist in artists {
                let names = artist.name!.components(separatedBy: " ")
                
                if let lastName = names.last {
                    var prefix = String(lastName.prefix(1))
                    if prefix.rangeOfCharacter(from: letters) == nil {
                        prefix = "#"
                    }
                    prefix = prefix.uppercased().folding(options: .diacriticInsensitive, locale: .current)
                    
                    if !sectionIndexTitles.contains(prefix) {
                        sectionIndexTitles.append(prefix)
                    }
                }
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

    func doSearch() {
        var newRequest:NSFetchRequest<NSFetchRequestResult>?
        
        if let text = searchController.searchBar.text {
            if text.count > 0 {
                newRequest = NSFetchRequest(entityName: "CMArtist")
                
                newRequest!.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                               NSSortDescriptor(key: "lastName", ascending: true),
                                               NSSortDescriptor(key: "firstName", ascending: true)]
                
                if text.count == 1 {
                    newRequest!.predicate = NSPredicate(format: "firstName BEGINSWITH[cd] %@ OR lastName BEGINSWITH[cd] %@", text, text)
                } else if text.count > 1 {
                    newRequest!.predicate = NSPredicate(format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", text, text)
                }
                dataSource = getDataSource(newRequest)
                tableView.reloadData()
                
            } else {
                dataSource = getDataSource(nil)
                tableView.reloadData()
            }
        }
    }
}

// MARK: UITableViewDelegate
extension ArtistsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let artist = dataSource!.object(indexPath) as? CMArtist {
            let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
            let predicate = NSPredicate(format: "artist_.name = %@", artist.name!)
            
            request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                       NSSortDescriptor(key: "name", ascending: true),
                                       NSSortDescriptor(key: "set.releaseDate", ascending: true)]
            request.predicate = predicate
            
            performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                                "title": artist.name!])
        }
    }
}

// MARK: DATASourceDelegate
extension ArtistsViewController : DATASourceDelegate {
    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
    func sectionIndexTitlesForDataSource(_ dataSource: DATASource, tableView: UITableView) -> [String] {
        return sectionIndexTitles
    }
    
    // tell table which section corresponds to section title/index (e.g. "B",1))
    func dataSource(_ dataSource: DATASource, tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        var sectionIndex = 0
        
        for i in 0...sectionTitles.count - 1 {
            if sectionTitles[i].hasPrefix(title) {
                sectionIndex = i
                break
            }
        }
        
        return sectionIndex
    }
}

// MARK: UISearchResultsUpdating
extension ArtistsViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}




