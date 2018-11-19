//
//  ArtistsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 19/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import ManaKit
import PromiseKit

class ArtistsViewController: BaseViewController {

    // MARK: Variables
    let searchController = UISearchController(searchResultsController: nil)
    var viewModel = ArtistsViewModel()
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        
        if viewModel.mode == .loading {
            fetchData()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any],
                let request = dict["request"] as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request,
                                             andTitle: dict["title"] as? String,
                                             andMode: .loading)
        }
    }
    
    // MARK: Custom methods
    @objc func doSearch() {
        viewModel.queryString = searchController.searchBar.text ?? ""
        viewModel.mode = .loading
        tableView.reloadData()
        fetchData()
    }
    
    func fetchData() {
        firstly {
            viewModel.fetchData()
        }.done {
            self.viewModel.mode = self.viewModel.isEmpty() ? .noResultsFound : .resultsFound
            self.tableView.reloadData()
        }.catch { error in
            self.viewModel.mode = .error
            self.tableView.reloadData()
        }
    }
}

// MARK: UITableViewDataSource
extension ArtistsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        
        if viewModel.mode == .resultsFound {
            let c = tableView.dequeueReusableCell(withIdentifier: "ArtistCell",
                                                  for: indexPath)
            // Configure Cell
            guard let label = c.textLabel else {
                fatalError("UILabel not found")
            }
            label.text = viewModel.object(forRowAt: indexPath).name
            cell = c
            
        } else {
            guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier) as? SearchModeTableViewCell else {
                fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
            }
            c.mode = .noResultsFound
            cell = c
        }
        
        return cell!
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.sectionIndexTitles()
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return viewModel.sectionForSectionIndexTitle(title: title, at: index)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeaderInSection(section: section)
    }
}

// MARK: UITableViewDelegate
extension ArtistsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.mode == .resultsFound {
            return UITableView.automaticDimension
        } else {
            return tableView.frame.size.height / 3
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let artist = viewModel.object(forRowAt: indexPath)
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "artist.name = %@ AND language.code = %@", artist.name!, "en")
        
        performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                            "title": artist.name!])
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
extension ArtistsViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

// MARK: UISearchResultsUpdating
extension ArtistsViewController : UISearchBarDelegate {
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



