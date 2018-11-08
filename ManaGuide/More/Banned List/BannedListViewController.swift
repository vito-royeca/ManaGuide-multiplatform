//
//  BannedListViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import ManaKit

class BannedListViewController: BaseViewController {

    // MARK: Variables
    let searchController = UISearchController(searchResultsController: nil)
    var viewModel = BannedListViewModel()

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
        
        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
        
        viewModel.fetchData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBanned" {
            guard let dest = segue.destination as? BannedViewController,
                let dict = sender as? [String: Any],
                let format = dict["format"] as? CMCardFormat else {
                return
            }
            
            dest.bannedViewModel = BannedViewModel(withFormat: format)
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
extension BannedListViewController : UITableViewDataSource {
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
            guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier) as? SearchModeTableViewCell else {
                fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
            }
            c.mode = .noResultsFound
            cell = c
            
        } else {
            let c = tableView.dequeueReusableCell(withIdentifier: "BannedCell",
                                                  for: indexPath)
            
            guard let label = c.textLabel else {
                fatalError("UILabel not found")
            }
            label.text = viewModel.object(forRowAt: indexPath).name
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

// MARK: UITableViewDelegate
extension BannedListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.isEmpty() {
            return tableView.frame.size.height / 3
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let format = viewModel.object(forRowAt: indexPath)
        performSegue(withIdentifier: "showBanned", sender: ["format": format])
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if viewModel.isEmpty() {
            return nil
        } else {
            return indexPath
        }
    }
}

// MARK: UISearchResultsUpdating
extension BannedListViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

// MARK: UISearchResultsUpdating
extension BannedListViewController : UISearchBarDelegate {
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
