//
//  ComprehensiveRulesModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

class ComprehensiveRulesViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    
    private var _sectionName: String?
    private var _sectionIndexTitles = [String]()
    private var _sectionTitles = [String]()
    private var _fetchedResultsController: NSFetchedResultsController<CMRule>?
    private var _rule: CMRule?
    
    // MARK: Settings
    private let sortDescriptors = [NSSortDescriptor(key: "termSection", ascending: true),
                                   NSSortDescriptor(key: "term", ascending: true)]
    
    // MARK: Overrides
    init(withRule rule: CMRule?) {
        super.init()
        
        _rule = rule
        guard let rule = _rule else {
            return
        }
        if rule.term == "Glossary" {
            _sectionName = "termSection"
        }
    }
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    func numberOfSections() -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return 0
        }
        
        return sections.count
    }
    
    func sectionIndexTitles() -> [String]? {
        return _sectionIndexTitles
    }
    
    func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        var sectionIndex = 0
        
        for i in 0..._sectionTitles.count - 1 {
            if _sectionTitles[i].hasPrefix(title) {
                sectionIndex = i
                break
            }
        }
        
        return sectionIndex
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections else {
                return nil
        }
        
        return sections[section].name
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> CMRule {
        guard let fetchedResultsController = _fetchedResultsController else {
            fatalError("fetchedResultsController is nil")
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    func fetchData() {
        let request: NSFetchRequest<CMRule>?
        let count = queryString.count
        
        if count > 0 {
            request = CMRule.fetchRequest()
            request!.sortDescriptors = [NSSortDescriptor(key: "termSection", ascending: true),
                                        NSSortDescriptor(key: "term", ascending: true)]
            
            if count == 1 {
                request!.predicate = NSPredicate(format: "term BEGINSWITH[cd] %@", queryString)
            } else if count > 1 {
                let predicates = [NSPredicate(format: "term CONTAINS[cd] %@", queryString),
                                  NSPredicate(format: "definition CONTAINS[cd] %@", queryString)]
                request!.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            }
            _fetchedResultsController = getFetchedResultsController(with: request)
        } else {
            _fetchedResultsController = getFetchedResultsController(with: nil)
        }
        
        if let rule = _rule {
            if rule.term == "Glossary" {
                updateSections()
            }
        }
    }
    
    private func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMRule>?) -> NSFetchedResultsController<CMRule> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMRule>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // Create a default fetchRequest
            request = CMRule.fetchRequest()
            request!.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            if let rule = _rule {
                request!.predicate = NSPredicate(format: "parent = %@", rule)
            } else {
                request!.predicate = NSPredicate(format: "parent = nil")
                
            }
        }
        
        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: request!,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: _sectionName,
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
    
    private func updateSections() {
        guard let fetchedResultsController = _fetchedResultsController,
            let sections = fetchedResultsController.sections,
            let rule = _rule else {
            return
        }
        
        _sectionIndexTitles = [String]()
        _sectionTitles = [String]()
        
        if rule.term == "Glossary" {
            if let children = rule.children {
                if let glossaries = children.allObjects as? [CMRule] {
                    _sectionIndexTitles = [String]()
                    _sectionTitles = [String]()
                    
                    for glossary in glossaries {
                        let prefix = String(glossary.term!.prefix(1))
                        
                        if !_sectionIndexTitles.contains(prefix) {
                            _sectionIndexTitles.append(prefix)
                        }
                    }
                    
                    let count = sections.count
                    if count > 0 {
                        for i in 0...count - 1 {
                            if let sectionTitle = sections[i].indexTitle {
                                _sectionTitles.append(sectionTitle)
                            }
                        }
                    }
                    
                    _sectionIndexTitles.sort()
                    _sectionTitles.sort()
                }
            }
        }
    }
    
    func attributedTextFor(_ rule: CMRule, withText text: String?) -> NSAttributedString {
        var attributedString = NSMutableAttributedString(string: "")
        let bigFontAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 17)]
        let bigBoldFontAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 17)]
        let smallFontAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 17)]
        
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
                    let tmp = NSMutableAttributedString(string: term, attributes: convertToOptionalNSAttributedStringKeyDictionary(bigBoldFontAttributes))
                    
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
    
    private func singleLineAttributedStringFor(_ rule: CMRule, withAttributes: [String: Any]) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: "")
        var dirty = false
        
        if let term = rule.term {
            attributedString.append(NSAttributedString(string: term, attributes: convertToOptionalNSAttributedStringKeyDictionary(withAttributes)))
            dirty = true
        }
        if let definition = rule.definition {
            if dirty {
                attributedString.append(NSAttributedString(string: ". ", attributes: convertToOptionalNSAttributedStringKeyDictionary(withAttributes)))
            }
            attributedString.append(NSAttributedString(string: definition, attributes: convertToOptionalNSAttributedStringKeyDictionary(withAttributes)))
        }
        
        return attributedString
    }
    
    private func highlight(attributedString: NSMutableAttributedString, withAttributes: [String: Any], fromText: String) {
        var newAttributes = [String: Any]()
        for (k,v) in withAttributes {
            newAttributes[k] = v
        }
        newAttributes[convertFromNSAttributedStringKey(NSAttributedString.Key.backgroundColor)] = UIColor.yellow
        
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
                                                   attributes: convertToOptionalNSAttributedStringKeyDictionary(newAttributes))
                
                attributedString.replaceCharacters(in: foundRange, with: highlight)
                searchRange.location = foundRange.location + 1 //foundRange.length
            } else {
                // no more substring to find
                break;
            }
        }
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension ComprehensiveRulesViewModel : NSFetchedResultsControllerDelegate {
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
