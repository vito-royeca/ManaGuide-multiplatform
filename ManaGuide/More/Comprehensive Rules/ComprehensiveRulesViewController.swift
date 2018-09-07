//
//  ComprehensiveRulesViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import Font_Awesome_Swift
import ManaKit

class ComprehensiveRulesViewController: BaseViewController {
    // MARK: Variables
    let searchController = UISearchController(searchResultsController: nil)
    var viewModel: ComprehensiveRulesViewModel!

    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter"

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        tableView.keyboardDismissMode = .onDrag

        viewModel.performSearch()
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
                let cell = sender as? UITableViewCell,
                let indexPath = tableView.indexPath(for: cell) else {
                return
            }
            let rule = viewModel.object(forRowAt: indexPath)
            
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
}

// MARK: UITableViewDataSource
extension ComprehensiveRulesViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tableViewNumberOfRows(inSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.tableViewNumberOfSections()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DynamicHeightCell",
                                                 for: indexPath)
        guard let label = cell.viewWithTag(100) as? UILabel else {
            fatalError("No view with tag 100")
        }
        
        let rule = viewModel.object(forRowAt: indexPath)
        
        // Configure Cell
        if let children = rule.children {
            if children.allObjects.count > 0 {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                
            } else {
                if let _ = rule.parent {
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                    
                } else {
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }
            }
        }
        label.attributedText = viewModel.attributedTextFor(rule, withText: searchController.searchBar.text)
        
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.tableViewSectionIndexTitles()
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return viewModel.tableViewSectionForSectionIndexTitle(title: title, at: index)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.tableViewTitleForHeaderInSection(section: section)
    }
}

extension ComprehensiveRulesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let rule = viewModel.object(forRowAt: indexPath)
        
        guard let children = rule.children else {
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
        guard let text = searchController.searchBar.text else {
            return
        }
        
        viewModel.queryString = text
        viewModel.performSearch()
        tableView.reloadData()
    }
}

