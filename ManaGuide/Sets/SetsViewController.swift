//
//  SetsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import Font_Awesome_Swift
import InAppSettingsKit
import ManaKit

class SetsViewController: BaseViewController {

    // MARK: Variables
    let searchController = UISearchController(searchResultsController: nil)
    var viewModel = SetsViewModel()
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Sets")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                                  object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateDataDisplay(_:)),
                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                               object: nil)
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
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
        
        rightMenuButton.image = UIImage.init(icon: .FABars, size: CGSize(width: 30, height: 30), textColor: .white, backgroundColor: .clear)
        rightMenuButton.title = nil
        
        viewModel.fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSet" {
            guard let dest = segue.destination as? SetViewController,
                let set = sender as? CMSet else {
                return
            }
            
            dest.viewModel = SetViewModel(withSet: set)
        }
    }

    // MARK: Custom methods
    @objc func updateDataDisplay(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        
        viewModel.updateSorting(with: userInfo)
        viewModel.fetchData()
        tableView.reloadData()
    }
    
    @objc func doSearch() {
        viewModel.queryString = searchController.searchBar.text ?? ""
        viewModel.fetchData()
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource
extension SetsViewController : UITableViewDataSource {
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
            guard let c = tableView.dequeueReusableCell(withIdentifier: SetsTableViewCell.reuseIdentifier,
                                                           for: indexPath) as? SetsTableViewCell else {
                fatalError("Unexpected indexPath: \(indexPath)")
            }
            
            c.set = viewModel.object(forRowAt: indexPath)
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
extension SetsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.isEmpty() {
            return tableView.frame.size.height / 3
        } else {
            return SetsTableViewCell.cellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let set = viewModel.object(forRowAt: indexPath)
        performSegue(withIdentifier: "showSet", sender: set)
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
extension SetsViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

// MARK: UISearchResultsUpdating
extension SetsViewController : UISearchBarDelegate {
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
