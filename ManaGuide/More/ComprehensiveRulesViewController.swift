//
//  ComprehensiveRulesViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import Font_Awesome_Swift
import ManaKit

class ComprehensiveRulesViewController: BaseViewController {
    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var fetchedResultsController: NSFetchedResultsController<CMRule>?
    var request: NSFetchRequest<CMRule>?
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
        fetchedResultsController = getFetchedResultsController(with: request)
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
            guard let fetchedResultsController = fetchedResultsController,
                let dest = segue.destination as? ComprehensiveRulesViewController,
                let cell = sender as? UITableViewCell else {
                return
            }
            guard let indexPath = tableView.indexPath(for: cell) else {
                return
            }
            let r = fetchedResultsController.object(at: indexPath)
            
            
            let newRequest: NSFetchRequest<CMRule> = CMRule.fetchRequest()
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
//    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?, sectionName: String?) -> DATASource? {
//        let ds = DATASource(tableView: tableView,
//                            cellIdentifier: "DynamicHeightCell",
//                            fetchRequest: fetchRequest!,
//                            mainContext: ManaKit.sharedInstance.dataStack!.mainContext,
//                            sectionName: sectionName)
//        ds.delegate = self
//
//        return ds
//    }
    func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMRule>?) -> NSFetchedResultsController<CMRule> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var newRequest: NSFetchRequest<CMRule>?
        
        if let fetchRequest = fetchRequest {
            newRequest = fetchRequest
        } else {
            // Create a default fetchRequest
            newRequest = CMRule.fetchRequest()
            newRequest!.sortDescriptors = [NSSortDescriptor(key: "term", ascending: true)]
        }
        
        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: newRequest!,
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
            let sections = fetchedResultsController.sections,
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
                    
                    let count = sections.count
                    if count > 0 {
                        for i in 0...count - 1 {
                            if let sectionTitle = sections[i].indexTitle { //dataSource.titleForHeader(i) {
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
        
        var newRequest: NSFetchRequest<CMRule>?

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
            fetchedResultsController = getFetchedResultsController(with: newRequest)
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
        } else {
            fetchedResultsController = getFetchedResultsController(with: nil)
            if let rule = rule {
                if rule.term == "Glossary" {
                    updateSections()
                }
            }
        }
        
        tableView.reloadData()
        
    }
}

// MARK: UITableViewDataSource
extension ComprehensiveRulesViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let rules = fetchedResultsController.fetchedObjects else {
            return 0
        }
        
        return rules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("Unexpected indexPath: \(indexPath)")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell",
                                                 for: indexPath)
        guard let label = cell.viewWithTag(100) as? UILabel else {
            fatalError("No view with tag 100")
        }
        
        let r = fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
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
        
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
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

extension ComprehensiveRulesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("Unexpected indexPath: \(indexPath)")
        }
        let r = fetchedResultsController.object(at: indexPath)
        
        guard let children = r.children else {
            return nil
        }
        
        guard children.allObjects.count > 0 else {
            return nil
        }
        
        return indexPath
    }
}

// MARK: UISearchResultsUpdating
extension ComprehensiveRulesViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension ComprehensiveRulesViewController : NSFetchedResultsControllerDelegate {
    
}


