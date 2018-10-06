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
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter"
        searchController.searchResultsUpdater = self
        definesPresentationContext = true

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        tableView.register(UINib(nibName: "DynamicHeightTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: DynamicHeightTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "EmptyTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: EmptyTableViewCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag

        viewModel.fetchData()
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
}

// MARK: UITableViewDataSource
extension ComprehensiveRulesViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.isEmpty() {
            return 1
        } else {
            return viewModel.numberOfRows(inSection: section)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.isEmpty() {
            return 1
        } else {
            return viewModel.numberOfSections()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if viewModel.isEmpty() {
            guard let c = tableView.dequeueReusableCell(withIdentifier: EmptyTableViewCell.reuseIdentifier) as? EmptyTableViewCell else {
                fatalError("\(EmptyTableViewCell.reuseIdentifier) is nil")
            }
            cell = c
            
        } else {
            guard let c = tableView.dequeueReusableCell(withIdentifier: DynamicHeightTableViewCell.reuseIdentifier) as? DynamicHeightTableViewCell else {
                fatalError("\(DynamicHeightTableViewCell.reuseIdentifier) is nil")
            }
            
            let rule = viewModel.object(forRowAt: indexPath)
            
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
        }
        
        return cell!
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if viewModel.isEmpty() {
            return nil
        } else {
            return viewModel.sectionIndexTitles()
        }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if viewModel.isEmpty() {
            return 0
        } else {
            return viewModel.sectionForSectionIndexTitle(title: title, at: index)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if viewModel.isEmpty() {
            return nil
        } else {
            return viewModel.titleForHeaderInSection(section: section)
        }
    }
}

extension ComprehensiveRulesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)
        
        if viewModel.isEmpty() {
            height = tableView.frame.size.height / 3
        } else {
            height = UITableViewAutomaticDimension
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
}

// MARK: UISearchResultsUpdating
extension ComprehensiveRulesViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }
        
        viewModel.queryString = text
        viewModel.fetchData()
        tableView.reloadData()
    }
}

