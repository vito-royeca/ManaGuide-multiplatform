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

class ComprehensiveRulesViewController: BaseViewController {
    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var dataSource: DATASource?
    var request: NSFetchRequest<NSFetchRequestResult>?
    var rule: CMRule?
    var sectionName: String?
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
        
        if request == nil {
            request = CMRule.fetchRequest()
            request!.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            request!.predicate = NSPredicate(format: "parent = nil")
        }
        dataSource = getDataSource(request, sectionName: sectionName)
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
            guard let dest = segue.destination as? ComprehensiveRulesViewController,
                let cell = sender as? UITableViewCell else {
                return
            }
            guard let indexPath = tableView.indexPath(for: cell) else {
                return
            }
            guard let r = dataSource!.object(indexPath) as? CMRule else {
                return
            }
            
            let newRequest = CMRule.fetchRequest()
            newRequest.sortDescriptors = [NSSortDescriptor(key: "term", ascending: true)]
            newRequest.predicate = NSPredicate(format: "parent = %@", r)
            
            dest.request = newRequest
            dest.rule = r
            if r.term == "Glossary" {
                dest.sectionName = "termSection"
            }
            
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
    
    // MARK: Custom methods
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?, sectionName: String?) -> DATASource? {
        var ds: DATASource?

        ds = DATASource(tableView: tableView, cellIdentifier: "DynamicHeightCell", fetchRequest: fetchRequest!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: sectionName, configuration: { cell, item, indexPath in
            guard let r = item as? CMRule,
                let label = cell.viewWithTag(100) as? UILabel else {
                return
            }
            
            if let children = r.children {
                if children.allObjects.count > 0 {
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                    
                } else {
                    if let _ = r.parent {
                        cell.accessoryType = .none
                        cell.selectionStyle = .none
                        
                    } else {
                        cell.accessoryType = .disclosureIndicator
                        cell.selectionStyle = .default
                    }
                }
            }
            
            label.attributedText = self.attributedTextFor(r)
        })
        
        guard let d = ds else {
            return nil
        }
        d.delegate = self
        return d
    }
    
    func updateSections() {
        guard let dataSource = dataSource,
            let rule = rule else {
            return
        }
        
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

    func attributedTextFor(_ rule: CMRule) -> NSAttributedString {
        var attributedString = NSMutableAttributedString(string: "")
        let text = searchController.searchBar.text
        let bigFontAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]
        let bigBoldFontAttributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)]
        let smallFontAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]
        
        guard let children = rule.children else {
            return attributedString
        }
        
        if children.allObjects.count > 0 {
            attributedString = singleLineAttributedStringFor(rule, withAttributes: bigFontAttributes)
            
            if let text = text {
                if text.count > 0 {
                    highlight(attributedString: attributedString, withAttributes: bigFontAttributes, fromText: text)
                }
            }
            
        } else {
            if let _ = rule.parent {
                if let term = rule.term {
                    let tmp = NSMutableAttributedString(string: term, attributes: bigBoldFontAttributes)
                    
                    if let text = text {
                        if text.count > 0 {
                            highlight(attributedString: tmp, withAttributes: bigBoldFontAttributes, fromText: text)
                        }
                    }
                    attributedString.append(tmp)
                }

                if let definition = rule.definition {
                    let tmp = NSMutableAttributedString(symbol: "\n\n\(definition)", pointSize: CGFloat(17))
                    
                    if let text = text {
                        if text.count > 0 {
                            highlight(attributedString: tmp, withAttributes: smallFontAttributes, fromText: text)
                        }
                    }
                    attributedString.append(tmp)
                }
                
            } else {
                attributedString = singleLineAttributedStringFor(rule, withAttributes: bigBoldFontAttributes)
                
                if let text = text {
                    if text.count > 0 {
                        highlight(attributedString: attributedString, withAttributes: bigBoldFontAttributes, fromText: text)
                    }
                }
            }
        }
        
        return attributedString
    }
    
    func singleLineAttributedStringFor(_ rule: CMRule, withAttributes: [String: Any]) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: "")
        var dirty = false
        
        if let term = rule.term {
            attributedString.append(NSAttributedString(string: term, attributes: withAttributes))
            dirty = true
        }
        if let definition = rule.definition {
            if dirty {
                attributedString.append(NSAttributedString(string: ". ", attributes: withAttributes))
            }
            attributedString.append(NSAttributedString(string: definition, attributes: withAttributes))
        }
        
        return attributedString
    }
    
    func highlight(attributedString: NSMutableAttributedString, withAttributes: [String: Any], fromText: String) {
        var newAttributes = [String: Any]()
        for (k,v) in withAttributes {
            newAttributes[k] = v
        }
        newAttributes[NSBackgroundColorAttributeName] = UIColor.yellow
        
        let string = attributedString.mutableString
        
        var searchRange = NSMakeRange(0, string.length)
        var foundRange = NSMakeRange(0, 0)
        
        while (searchRange.location < string.length) {
            searchRange.length = string.length - searchRange.location
            foundRange = string.range(of: fromText, options: String.CompareOptions.caseInsensitive, range: searchRange)
            
            if foundRange.location != NSNotFound {
                // found an occurrence of the substring! do stuff here
                let origText = string.substring(with: foundRange)
                let highlight = NSAttributedString(string: origText,
                                                   attributes: newAttributes)
                
                attributedString.replaceCharacters(in: foundRange, with: highlight)
                searchRange.location = foundRange.location + 1 //foundRange.length
            } else {
                // no more substring to find
                break;
            }
        }
    }
    
    func doSearch() {
        guard let text = searchController.searchBar.text else {
            return
        }
        
        var newRequest:NSFetchRequest<NSFetchRequestResult>?

        if text.count > 0 {
            newRequest = CMRule.fetchRequest()
            
            newRequest!.sortDescriptors = [NSSortDescriptor(key: "termSection", ascending: true),
                                        NSSortDescriptor(key: "term", ascending: true)]
            
            if text.count == 1 {
                newRequest!.predicate = NSPredicate(format: "term BEGINSWITH[cd] %@", text)
            } else if text.count > 1 {
                let predicates = [NSPredicate(format: "term CONTAINS[cd] %@", text),
                                  NSPredicate(format: "definition CONTAINS[cd] %@", text)]
                newRequest!.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            }
            dataSource = getDataSource(newRequest, sectionName: nil)
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
        } else {
            dataSource = getDataSource(request, sectionName: nil)
            if let rule = rule {
                if rule.term == "Glossary" {
                    updateSections()
                }
            }
        }
        
        tableView.reloadData()
        
    }
}

// MARK: UITableViewDelegate
extension ComprehensiveRulesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let r = dataSource!.object(indexPath) as? CMRule else {
            return nil
        }
        
        guard let children = r.children else {
            return nil
        }
        
        guard children.allObjects.count > 0 else {
            return nil
        }
        
        return indexPath
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
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

