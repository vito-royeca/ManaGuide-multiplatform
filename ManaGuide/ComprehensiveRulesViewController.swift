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
import RATreeView

class ComprehensiveRulesViewController: UIViewController {
    
    // MARK: Constants
    let data = ["Title", "Introduction", "Contents", "Glossary", "Credits"]
    
    // MARK: Variables
    var treeView: RATreeView?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var heightAdjustments = CGFloat(0)
        if let nc = navigationController {
            heightAdjustments = nc.navigationBar.frame.size.height
        }
        heightAdjustments += UIApplication.shared.statusBarFrame.height
        
        treeView = RATreeView(frame: CGRect(x: 0, y: heightAdjustments, width: view.frame.size.width, height: view.frame.size.height - heightAdjustments))
        treeView!.delegate = self
        treeView!.dataSource = self
        treeView!.register(UINib(nibName: "DynamicHeightTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        view.addSubview(treeView!)
        treeView!.reloadData()
    }
    
    func fetchRules(predicate: NSPredicate) -> [CMRule]? {
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMRule")
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "numberOrder", ascending: true)]
        
        return try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) as? [CMRule]
    }
    
    func expandButtonClicked(_ sender: Any) {
        print("\(sender)")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        treeView?.reloadData()
    }
}

// MARK: RAtreeViewDataSource
extension ComprehensiveRulesViewController : RATreeViewDataSource {
    /**
     *  Ask the data source to return the number of child items encompassed by a given item. (required)
     *
     *  @param treeView     The tree-view that sent the message.
     *  @param item         An item identifying a cell in tree view.
     *  @param treeNodeInfo Object including additional information about item.
     *
     *  @return The number of child items encompassed by item. If item is nil, this method should return the number of children for the top-level item.
     */
    func treeView(_ treeView: RATreeView, numberOfChildrenOfItem item: Any?) -> Int {
        var count = 0
        
        if let item = item as? String {
            switch item {
            case data[2]: // Contents
                let predicate = NSPredicate(format: "parent = nil AND NOT (number IN %@)", [data[0], data[1], data[4]])
                if let rules = fetchRules(predicate: predicate) {
                    count = rules.count
                }
                
            case data[3]: // Glossary
                count = 0
            default:
                count = 1
            }
        } else if let item = item as? CMRule {
            if let children = item.children {
                count = children.allObjects.count
            }
        } else {
            count = data.count
        }
        
        return count
    }
    
    /**
     *  Asks the data source for a cell to insert for a specified item. (required)
     *
     *  @param treeView     A tree-view object requesting the cell.
     *  @param item         An item identifying a cell in tree view.
     *
     *  @return An object inheriting from UITableViewCell that the tree view can use for the specified row. An assertion is raised if you return nil.
     */
    func treeView(_ treeView: RATreeView, cellForItem item: Any?) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if let c = treeView.dequeueReusableCell(withIdentifier: "Cell") as? DynamicHeightTableViewCell {
            var image: UIImage?
            var text: String?
            var level = 0
            
            c.accessoryType = .none
            if let item = item {
                level = self.treeView(treeView, indentationLevelForRowForItem: item)
            }
            
            if let item = item as? String {
                text = item
                
                if text == data[3] { // Glossary
                    c.accessoryType = .disclosureIndicator
                } else {
                    image = UIImage.init(icon: .FAPlusSquare, size: CGSize(width: 30, height: 30), textColor: .white, backgroundColor: .clear)
                }
                
            } else if let item = item as? CMRule {
                if let children = item.children {
                    var tabs = ""
                    for _ in 0...level - 1 {
                        tabs.append("\t")
                    }
                    
                    if item.number == data[0] ||
                        item.number == data[1] ||
                        item.number == data[4] {
                        text = "\(tabs)\(item.text!)"
                    } else {
                        text = "\(tabs)\(item.number!). \(item.text!)"
                        
                        if children.count > 0 {
                            image = UIImage.init(icon: .FAPlusSquare, size: CGSize(width: 30, height: 30), textColor: .white, backgroundColor: .clear)
                        }
                    }
                }
            }
            
            c.delegate = self
            c.item = item
            c.updateDataDisplay(text: text!, image: image)
            c.selectionStyle = .none
            
            cell = c
        }
        
        return cell!
    }
    
    
    /**
     *  Ask the data source to return the child item at the specified index of a given item. (required)
     *
     *  @param treeView The tree-view object requesting child of the item at the specified index.
     *  @param index    The index of the child item from item to return.
     *  @param item     An item identifying a cell in tree view.
     *
     *  @return The child item at index of a item. If item is nil, returns the appropriate child item of the root object.
     */
    func treeView(_ treeView: RATreeView, child index: Int, ofItem item: Any?) -> Any {
        var child: Any?
        
        if let item = item as? String {
            switch item {
            case data[0]: // Title
                let predicate = NSPredicate(format: "number = %@", data[0])
                if let rules = fetchRules(predicate: predicate) {
                    child = rules.first
                }
                
            case data[1]: // Introduction
                let predicate = NSPredicate(format: "number = %@", data[1])
                if let rules = fetchRules(predicate: predicate) {
                    child = rules.first
                }
                
            case data[2]: // Contents
                let predicate = NSPredicate(format: "parent = nil AND NOT (number IN %@)", [data[0], data[1], data[4]])
                if let rules = fetchRules(predicate: predicate) {
                    child = rules[index]
                }
                
            case data[3]: // Glossary
                ()
            case data[4]: // Credits
                let predicate = NSPredicate(format: "number = %@", data[4])
                if let rules = fetchRules(predicate: predicate) {
                    child = rules.first
                }
                
            default:
                child = item
            }
        } else if let item = item as? CMRule {
            if let children = item.children {
                let sortedChildren = children.allObjects.sorted(by: {(a: Any, b: Any) -> Bool in
                    if let a2 = a as? CMRule,
                        let b2 = b as? CMRule {
                        return a2.numberOrder < b2.numberOrder
                    }
                    
                    return false
                })
                child = sortedChildren[index]
            }
        } else {
            child = data[index]
        }
        
        
        return child!
    }
}

// MARK: RATreeViewDelegate
extension ComprehensiveRulesViewController : RATreeViewDelegate {
    func treeView(_ treeView: RATreeView, heightForRowForItem item: Any) -> CGFloat {
        var height = CGFloat(0)
        
        if let _ = item as? String {
            height = CGFloat(44)
        } else if let _ = item as? CMRule {
            height = UITableViewAutomaticDimension
        }
        
        return height
    }
    
    func treeView(_ treeView: RATreeView, estimatedHeightForRowForItem item: Any) -> CGFloat {
        return CGFloat(44)
    }
    
    func treeView(_ treeView: RATreeView, indentationLevelForRowForItem item: Any) -> Int {
        var level = 0
        
        if let item = item as? CMRule {
            var rule: CMRule?
            
            rule = item
            while rule != nil {
                rule = rule!.parent
                level += 1
            }
        }
        
        return level
    }

    public func treeView(_ treeView: RATreeView, didSelectRowForItem item: Any) {
        if let item = item as? String {
            if item == data[3] { // Glossary
                performSegue(withIdentifier: "showGlossary", sender: nil)
            }
        }
    }
    
    func treeView(_ treeView: RATreeView, didCollapseRowForItem item: Any) {
        if let cell = treeView.cell(forItem: item) as? DynamicHeightTableViewCell {
            if let item = item as? String {
                if item == data[3] {
                    cell.updateDataDisplay(text: item, image: nil)
                } else {
                    cell.updateButton(expanded: false)
                }
            } else if let item = item as? CMRule {
                if let children = item.children {
                    if children.allObjects.count > 0 {
                        cell.updateButton(expanded: false)
                    }
                }
            }
        }
    }
    
    func treeView(_ treeView: RATreeView, didExpandRowForItem item: Any) {
        if let cell = treeView.cell(forItem: item) as? DynamicHeightTableViewCell {
            if let item = item as? String {
                if item == data[3] {
                    cell.updateDataDisplay(text: item, image: nil)
                } else {
                    cell.updateButton(expanded: true)
                }
            } else if let item = item as? CMRule {
                if let children = item.children {
                    if children.allObjects.count > 0 {
                        cell.updateButton(expanded: true)
                    }
                }
            }
        }

        // update the children
//        if let item = item as? CMRule {
//            if let children = item.children {
//                let sortedChildren = children.allObjects.sorted(by: {(a: Any, b: Any) -> Bool in
//                    if let a2 = a as? CMRule,
//                        let b2 = b as? CMRule {
//                        return a2.numberOrder < b2.numberOrder
//                    }
//                    
//                    return false
//                })
//                
//                for child in sortedChildren {
//                    if let cell = treeView.cell(forItem: child) as? DynamicHeightTableViewCell {
//                        cell.updateButton(expanded: cell.isExpanded)
//                    }
//                }
//            }
//        }
    }
}

// MARK: 
extension ComprehensiveRulesViewController: DynamicHeightTableViewCellDelegate {
    func expandButtonClicked(_ cell: DynamicHeightTableViewCell, withItem item: Any?) {
        if let treeView = treeView,
            let item = item {
            
            let expanded = cell.expanded
            
            if expanded {
                treeView.collapseRow(forItem: item)
            } else {
                treeView.expandRow(forItem: item)
            }

            // TODO: fix if Glossary should not have a button image
            cell.updateButton(expanded: !expanded)
        }
    }
}

