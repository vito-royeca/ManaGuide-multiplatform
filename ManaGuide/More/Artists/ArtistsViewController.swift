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
        searchController.searchBar.placeholder = "Filter"
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
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
        if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any],
                let request = dict["request"] as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request, andTitle: dict["title"] as? String)
        }
    }
}

// MARK: UITableViewDataSource
extension ArtistsViewController : UITableViewDataSource {
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
            let c = tableView.dequeueReusableCell(withIdentifier: "ArtistCell",
                                                  for: indexPath)
            // Configure Cell
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
extension ArtistsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.isEmpty() {
            return tableView.frame.size.height / 3
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let artist = viewModel.object(forRowAt: indexPath)
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "artist_.name = %@", artist.name!)
        
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
        guard let text = searchController.searchBar.text else {
            return
        }
        
        viewModel.queryString = text
        viewModel.fetchData()
        tableView.reloadData()
    }
}



