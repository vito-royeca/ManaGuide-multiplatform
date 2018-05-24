//
//  GlossaryViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 08/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import ManaKit

class GlossaryViewController: UIViewController {

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
        dataSource = getDataSource(nil)
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.backgroundColor = UIColor.white
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            definesPresentationContext = true
            tableView.tableHeaderView = searchController.searchBar
        }
        
        updateSections()
        tableView.reloadData()
    }

    // MARK: Custom methods
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        var request:NSFetchRequest<NSFetchRequestResult>?
        var ds: DATASource?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = NSFetchRequest(entityName: "CMGlossary")
            
            request!.sortDescriptors = [NSSortDescriptor(key: "termSection", ascending: true),
                                        NSSortDescriptor(key: "term", ascending: true)]
        }
        
        ds = DATASource(tableView: tableView, cellIdentifier: "DynamicHeightCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: "termSection", configuration: { cell, item, indexPath in
            if let glossary = item as? CMGlossary,
                let label = cell.viewWithTag(100) as? UILabel {
                
                let attributedString = NSMutableAttributedString(string: "")
                if let term = glossary.term {
                    attributedString.append(NSMutableAttributedString(string: term,
                                                                      attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)]))
                }
                if let definition = glossary.definition {
                    attributedString.append(NSMutableAttributedString(string: "\n\n\(definition)",
                        attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
                }
                label.attributedText = attributedString
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
            let glossaries = dataSource.all() as [CMGlossary]
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
            
            for glossary in glossaries {
                let prefix = String(glossary.term!.prefix(1))
                
                if !sectionIndexTitles.contains(prefix) {
                    sectionIndexTitles.append(prefix)
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
        var filteredGlossaries:[CMGlossary]?
        var request:NSFetchRequest<NSFetchRequestResult>?
        
        if let text = searchController.searchBar.text {
            let count = text.count
            let glossaries = dataSource!.all() as! [CMGlossary]
            
            if count > 0 {
                filteredGlossaries = glossaries.filter({
                    let termLower = $0.term!.lowercased()
                    let definitionLower = $0.definition!.lowercased()
                    let textLower = text.lowercased()
                    
                    if count == 1 {
                        return termLower.hasPrefix(textLower)
                    } else {
                        return definitionLower.range(of: textLower) != nil ||
                            termLower.hasPrefix(textLower)
                    }
                })
            } else {
                filteredGlossaries = nil
            }
            
        } else {
            filteredGlossaries = nil
        }
        
        if let filteredGlossaries = filteredGlossaries {
            request = NSFetchRequest(entityName: "CMGlossary")
            request!.predicate = NSPredicate(format: "term in %@", filteredGlossaries.map { $0.term })
            request!.sortDescriptors = [NSSortDescriptor(key: "termSection", ascending: true),
                                        NSSortDescriptor(key: "term", ascending: true)]
        }
        
        dataSource = getDataSource(request)
        tableView.reloadData()
    }
}

// MARK: UITableViewDelegate
extension GlossaryViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44)
    }
}

// MARK: DATASourceDelegate
extension GlossaryViewController : DATASourceDelegate {
    
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
extension GlossaryViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        doSearch()
    }
}

