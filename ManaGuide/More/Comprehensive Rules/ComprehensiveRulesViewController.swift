//
//  ComprehensiveRulesViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class ComprehensiveRulesViewController: BaseSearchViewController {
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.register(UINib(nibName: "DynamicHeightTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: DynamicHeightTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRule" {
            guard let dest = segue.destination as? ComprehensiveRulesViewController,
                let rule = sender as? CMRule else {
                return
            }
            
            dest.viewModel = ComprehensiveRulesViewModel(withRule: rule)
            
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
            dest.title = string
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if viewModel.mode == .resultsFound {
            guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell,
                let viewModel = viewModel as? ComprehensiveRulesViewModel,
                let rule = viewModel.object(forRowAt: indexPath) as? CMRule else {
                    fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
            }
            
            // Configure Cell
            if let children = rule.children {
                if children.allObjects.count > 0 {
                    c.accessoryType = .disclosureIndicator
                    c.selectionStyle = .default
                    
                } else {
                    if let _ = rule.parent {
                        c.accessoryType = .none
                        c.selectionStyle = .none
                        
                    } else {
                        c.accessoryType = .disclosureIndicator
                        c.selectionStyle = .default
                    }
                }
            }
            c.dynamicLabel.attributedText = viewModel.attributedTextFor(rule,
                                                                        withText: searchController.searchBar.text)
            cell = c

        } else {
            guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier) as? SearchModeTableViewCell else {
                fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
            }
            cell = c
        }
        
        return cell!
    }
}

extension ComprehensiveRulesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)
        
        if viewModel.isEmpty() {
            height = tableView.frame.size.height / 3
        } else {
            height = UITableView.automaticDimension
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rule = viewModel.object(forRowAt: indexPath)
        performSegue(withIdentifier: "showRule", sender: rule)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if viewModel.isEmpty() {
            return nil
        } else {
            guard let rule = viewModel.object(forRowAt: indexPath) as? CMRule else {
                return nil
            }
            
            guard let children = rule.children else {
                return nil
            }
            
            guard children.allObjects.count > 0 else {
                return nil
            }
            
            return indexPath
        }
    }
}
