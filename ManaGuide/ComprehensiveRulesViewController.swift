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
    var request: NSFetchRequest<NSFetchRequestResult>?
    var rule: CMRule?
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
        definesPresentationContext = true

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        if request == nil {
            request = NSFetchRequest(entityName: "CMRule")
            request!.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            request!.predicate = NSPredicate(format: "parent = nil")
        }
        dataSource = getDataSource(request)
        updateSections()
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRule" {
            if let dest = segue.destination as? ComprehensiveRulesViewController,
                let cell = sender as? UITableViewCell {
                
                if let indexPath = tableView.indexPath(for: cell) {
                    if let r = dataSource!.object(indexPath) as? CMRule {
                        let newRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMRule")
                        newRequest.sortDescriptors = [NSSortDescriptor(key: "term", ascending: true)]
                        newRequest.predicate = NSPredicate(format: "parent = %@", r)
                        
                        dest.request = newRequest
                        dest.rule = r
                        var string = ""
                        if let term = r.term {
                            string.append("\(term)")
                        }
                        if let definition = r.definition {
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
    }
    
    // MARK: Custom methods
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        var ds: DATASource?

        ds = DATASource(tableView: tableView, cellIdentifier: "DynamicHeightCell", fetchRequest: fetchRequest!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: "termSection", configuration: { cell, item, indexPath in
            if let r = item as? CMRule,
                let label = cell.viewWithTag(100) as? UILabel {
                if let children = r.children {
                    if children.allObjects.count > 0 {
                        label.text = self.textFor(rule: r)
                        cell.accessoryType = .disclosureIndicator
                        cell.selectionStyle = .default
                        
                    } else {
                        if let _ = r.parent {
                            let attributedString = NSMutableAttributedString(string: "")
                            if let term = r.term {
                                attributedString.append(NSMutableAttributedString(string: term,
                                    attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)]))
                            }
                            if let definition = r.definition {
                                attributedString.append(NSMutableAttributedString(string: "\n\n\(definition)",
                                    attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]))
                            }
                        
                            label.attributedText = attributedString
                            cell.accessoryType = .none
                            cell.selectionStyle = .none
                            
                        } else {
                            label.text = self.textFor(rule: r)
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
            let rule = rule {
            
            if rule.term == "Glossary" {
                if let children = rule.children {
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
        var newRequest:NSFetchRequest<NSFetchRequestResult>?

        if let text = searchController.searchBar.text {
            if text.count > 0 {
                newRequest = NSFetchRequest(entityName: "CMRule")
                
                newRequest!.sortDescriptors = [NSSortDescriptor(key: "termSection", ascending: true),
                                            NSSortDescriptor(key: "term", ascending: true)]
                
                if text.count == 1 {
                    newRequest!.predicate = NSPredicate(format: "term BEGINSWITH[cd] %@", text)
                } else if text.count > 1 {
                    let predicates = [NSPredicate(format: "term CONTAINS[cd] %@", text),
                                      NSPredicate(format: "definition CONTAINS[cd] %@", text)]
                    newRequest!.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                }
                dataSource = getDataSource(newRequest)
                tableView.reloadData()
                
            } else {
                dataSource = getDataSource(request)
                tableView.reloadData()
            }
        }
    }
}

// MARK: UITableViewDelegate
extension ComprehensiveRulesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let r = dataSource!.object(indexPath) as? CMRule {
            if let children = r.children {
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

