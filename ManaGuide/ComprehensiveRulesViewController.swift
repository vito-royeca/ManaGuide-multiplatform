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
    
    // MARK: Variables
    var dataSource: DATASource?
    var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
    var currentRule: CMRule?
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dataSource = getDataSource(fetchRequest)
        tableView.reloadData()
        
        if let currentRule = currentRule {
            var string = ""
            if let number = currentRule.number {
                string.append("\(number)")
            }
            if let text = currentRule.text {
                if string.count > 0 {
                    string.append(". ")
                }
                string.append(text)
            }
            title = string
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRule" {
            if let dest = segue.destination as? ComprehensiveRulesViewController,
                let cell = sender as? UITableViewCell {
                
                if let indexPath = tableView.indexPath(for: cell) {
                    if let rule = dataSource!.object(indexPath) as? CMRule {
                        fetchRequest = NSFetchRequest(entityName: "CMRule")
                        fetchRequest!.sortDescriptors = [NSSortDescriptor(key: "numberOrder", ascending: true)]
                        fetchRequest!.predicate = NSPredicate(format: "parent = %@", rule)
                        currentRule = rule
                    }
                }
                
                dest.fetchRequest = fetchRequest
                dest.currentRule = currentRule
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
            request!.sortDescriptors = [NSSortDescriptor(key: "numberOrder", ascending: true)]
            request!.predicate = NSPredicate(format: "parent = nil")
        }
        
        ds = DATASource(tableView: tableView, cellIdentifier: "DynamicHeightCell", fetchRequest: request!, mainContext: ManaKit.sharedInstance.dataStack!.mainContext, sectionName: nil, configuration: { cell, item, indexPath in
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
                            if let number = rule.number {
                                attributedString.append(NSMutableAttributedString(string: number,
                                    attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)]))
                            }
                            if let text = rule.text {
                                attributedString.append(NSMutableAttributedString(string: "\n\n\(text)",
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
        
        return ds
    }
    
    func textFor(rule: CMRule) -> String {
        var string = ""
        if let number = rule.number {
            string.append("\(number)")
        }
        if let text = rule.text {
            if string.count > 0 {
                string.append(". ")
            }
            string.append(text)
        }
        
        return string
    }
}

// MARK: UITableViewDelegate
extension ComprehensiveRulesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let rule = dataSource!.object(indexPath) as? CMRule {
            if let children = rule.children {
                if children.allObjects.count > 0 {
                    return indexPath
                } else {
                    if rule.parent == nil {
                        performSegue(withIdentifier: "showGlossary", sender: nil)
                    }
                }
            }
        }

        return nil
    }
}

