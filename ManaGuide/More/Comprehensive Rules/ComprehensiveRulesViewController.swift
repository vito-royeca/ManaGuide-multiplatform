//
//  ComprehensiveRulesViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
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
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Filter"
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
    
    // MARK: Custom methods
    @objc func doSearch() {
        viewModel.queryString = searchController.searchBar.text ?? ""
        viewModel.fetchData()
        tableView.reloadData()
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
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

// MARK: UISearchResultsUpdating
extension ComprehensiveRulesViewController : UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        viewModel.searchCancelled = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.searchCancelled = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if viewModel.searchCancelled {
            searchBar.text = viewModel.queryString
        } else {
            viewModel.queryString = searchBar.text ?? ""
        }
    }
}
