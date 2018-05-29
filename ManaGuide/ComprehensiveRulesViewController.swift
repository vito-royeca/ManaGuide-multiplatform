//
//  ComprehensiveRulesViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import Font_Awesome_Swift
import ManaKit

class ComprehensiveRulesViewController: UIViewController {
    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var dataSource: DATASource?
    var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
    var currentRule: CMRule?
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
        searchController.searchBar.tintColor = UIColor(red:0.41, green:0.12, blue:0.00, alpha:1.0) // maroon
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            definesPresentationContext = true
            tableView.tableHeaderView = searchController.searchBar
        }
        
        dataSource = getDataSource(fetchRequest)
        updateSections()
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRule" {
            if let dest = segue.destination as? ComprehensiveRulesViewController,
                let cell = sender as? UITableViewCell {
                
                if let indexPath = tableView.indexPath(for: cell) {
                    if let rule = dataSource!.object(indexPath) as? CMRule {
                        fetchRequest = NSFetchRequest(entityName: "CMRule")
                        fetchRequest!.sortDescriptors = [NSSortDescriptor(key: "term", ascending: true)]
                        fetchRequest!.predicate = NSPredicate(format: "parent = %@", rule)
                        currentRule = rule
                    }
                }
                
                dest.fetchRequest = fetchRequest
                dest.currentRule = currentRule
                if let currentRule = currentRule {
                    var string = ""
                    if let term = currentRule.term {
                        string.append("\(term)")
                    }
                    if let definition = currentRule.definition {
                        if string.count > 0 {
                            string.append(". ")
                        }
                        string.append(definition)
                    }
                    dest.title = string
                }
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
            request = NSFetchRequest(entityName: "CMRule")
            request!.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            request!.predicate = NSPredicate(format: "parent = nil")
        }
        
        ds = DATASource(tableView: tableView, cellIdentifier: "DynamicHeightCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: "termSection", configuration: { cell, item, indexPath in
            if let rule = item as? CMRule,
                let label = cell.viewWithTag(100) as? UILabel {
                if let children = rule.children {
                    if children.allObjects.count > 0 {
                        label.text = self.textFor(rule: rule)
                        cell.accessoryType = .disclosureIndicator
                        cell.selectionStyle = .default
                        
                    } else {
                        if let _ = rule.parent {
                            let attributedString = NSMutableAttributedString(string: "")
                            if let term = rule.term {
                                attributedString.append(NSMutableAttributedString(string: term,
                                    attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)]))
                            }
                            if let definition = rule.definition {
                                attributedString.append(NSMutableAttributedString(string: "\n\n\(definition)",
                                    attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
                            }
                        
                            label.attributedText = attributedString
                            cell.accessoryType = .none
                            cell.selectionStyle = .none
                            
                        } else {
                            label.text = self.textFor(rule: rule)
                            cell.accessoryType = .disclosureIndicator
                            cell.selectionStyle = .default
                        }
                    }
                }
            }
        })
        
        if let ds = ds {
            ds.delegate = self
            return ds
        }

        return ds
    }
    
    func updateSections() {
        if let dataSource = dataSource,
            let currentRule = currentRule {
            if currentRule.term == "Glossary" {
                if let children = currentRule.children {
                    if let glossaries = children.allObjects as? [CMRule] {
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
                        
                        sectionIndexTitles.sort()
                        sectionTitles.sort()
                    }
                }
            }
        }
    }

    func textFor(rule: CMRule) -> String {
        var string = ""
        if let term = rule.term {
            string.append("\(term)")
        }
        if let definition = rule.definition {
            if string.count > 0 {
                string.append(". ")
            }
            string.append(definition)
        }
        
        return string
    }
    
    func doSearch() {
        var request:NSFetchRequest<NSFetchRequestResult>?

        if let text = searchController.searchBar.text {
            
            
            if text.count > 0 {
                request = NSFetchRequest(entityName: "CMRule")
                
                request!.sortDescriptors = [NSSortDescriptor(key: "termSection", ascending: true),
                                            NSSortDescriptor(key: "term", ascending: true)]
                
                if text.count == 1 {
                    request!.predicate = NSPredicate(format: "term BEGINSWITH[cd] %@", text)
                } else if text.count > 1 {
                    let predicates = [NSPredicate(format: "term CONTAINS[cd] %@", text),
                                      NSPredicate(format: "definition CONTAINS[cd] %@", text)]
                    request!.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                }
            }
        }
        
        dataSource = getDataSource(request)
        tableView.reloadData()
    }
}

// MARK: UITableViewDelegate
extension ComprehensiveRulesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let rule = dataSource!.object(indexPath) as? CMRule {
            if let children = rule.children {
                if children.allObjects.count > 0 {
                    return indexPath
                }
            }
        }
        
        return nil
    }
}

// MARK: DATASourceDelegate
extension ComprehensiveRulesViewController : DATASourceDelegate {
    
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
extension ComprehensiveRulesViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        doSearch()
    }
}

