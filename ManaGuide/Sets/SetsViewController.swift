//
//  SetsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import FontAwesome_swift
import InAppSettingsKit
import ManaKit
import PromiseKit

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
        
        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
        
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .bars,
                                                        style: .solid,
                                                        textColor: LookAndFeel.GlobalTintColor,
                                                        size: CGSize(width: 30, height: 30)) //UIImage.init(icon: .FABars, size: CGSize(width: 30, height: 30), textColor: .white, backgroundColor: .clear)
        rightMenuButton.title = nil
        title = "Sets"
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
        if segue.identifier == "showSet" {
            guard let dest = segue.destination as? SetViewController,
            let dict = sender as? [String: Any],
            let set = dict["set"] as? CMSet,
            let languageCode = dict["languageCode"] as? String else {
                return
            }
            
            dest.viewModel = SetViewModel(withSet: set, languageCode: languageCode)
        }
    }

    // MARK: Custom methods
    @objc func updateDataDisplay(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        
        viewModel.updateSorting(with: userInfo)
        fetchData()
    }
    
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
extension SetsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if viewModel.mode == .resultsFound {
            guard let c = tableView.dequeueReusableCell(withIdentifier: SetsTableViewCell.reuseIdentifier,
                                                        for: indexPath) as? SetsTableViewCell else {
                                                            fatalError("Unexpected indexPath: \(indexPath)")
            }
            
            c.set = viewModel.object(forRowAt: indexPath)
            c.delegate = self
            cell = c
        } else {
            guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier) as? SearchModeTableViewCell else {
                fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
            }
            c.mode = viewModel.mode
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
extension SetsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.mode == .resultsFound {
            return SetsTableViewCell.cellHeight
        } else {
            return tableView.frame.size.height / 3
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

// MARK:
extension SetsViewController: SetsTableViewCellDelegate {
    func languageAction(cell: UITableViewCell, code: String) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let set = viewModel.object(forRowAt: indexPath)
        let sender = ["set": set,
                      "languageCode": code] as [String : Any]
        performSegue(withIdentifier: "showSet", sender: sender)
    }
}
