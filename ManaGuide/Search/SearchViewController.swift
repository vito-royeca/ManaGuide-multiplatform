//
//  SearchViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import Font_Awesome_Swift
import InAppSettingsKit
import MBProgressHUD
import ManaKit
import PromiseKit

protocol SearchViewControllerDelegate: NSObjectProtocol {
    func reloadViewModel() -> SearchViewModel
}

class SearchViewController: BaseViewController {
    // MARK: Variables
    var viewModel: SearchViewModel!
    var delegate: SearchViewControllerDelegate?
    let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Search")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter"
        searchController.searchResultsUpdater = self
        definesPresentationContext = true

        rightMenuButton.image = UIImage.init(icon: .FABars,
                                             size: CGSize(width: 30, height: 30),
                                             textColor: .white,
                                             backgroundColor: .clear)
        rightMenuButton.title = nil

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        tableView.register(UINib(nibName: "EmptyTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: EmptyTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "CardGridTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: CardGridTableViewCell.reuseIdentifier)
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"),
                           forCellReuseIdentifier: CardTableViewCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
        
        title = viewModel.getSearchTitle()
        viewModel.fetchData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Settings
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateSettings(_:)),
                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                               object: nil)
        // Favorites
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateData(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                               object: nil)
        // Ratings
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateData(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                               object: nil)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        updateDataDisplay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Remove notification listeners
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                                  object:nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                  object:nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                  object:nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dict = sender as? [String: Any] else {
            return
        }
        
        let searchGenerator = SearchRequestGenerator()
        let sortDescriptors = searchGenerator.createSortDescriptors()
        
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController,
                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String] else {
                return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withCardIDs: cardIDs,
                                           withSortDescriptors: sortDescriptors)
            
        } else if segue.identifier == "showCardModal" {
            guard let nav = segue.destination as? UINavigationController,
                let dest = nav.childViewControllers.first as? CardViewController,
                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String] else {
                return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withCardIDs: cardIDs,
                                           withSortDescriptors: sortDescriptors)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateDataDisplay()
    }

    // MARK: Notification handlers
    @objc func updateSettings(_ notification: Notification) {
        let searchGenerator = SearchRequestGenerator()
        searchGenerator.syncValues(notification)
        
        DispatchQueue.main.async {
            self.updateDataDisplay()
        }
    }
    
    @objc func updateData(_ notification: Notification) {
        if let delegate = delegate {
            viewModel = delegate.reloadViewModel()
            
            DispatchQueue.main.async {
                self.updateDataDisplay()
            }
        }
    }
    
    // MARK: Custom methods
    func updateDataDisplay() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController?.searchBar.isHidden = false
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView?.tableHeaderView = searchController.searchBar
        }
        
        viewModel.fetchData()
        tableView?.reloadData()
        
        guard let cell = tableView?.cellForRow(at: IndexPath(row: 0, section: 0)) as? CardGridTableViewCell else {
            return
        }
        cell.collectionView.reloadData()
    }
}

// MARK: UITableViewDataSource
extension SearchViewController : UITableViewDataSource {
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
        let searchGenerator = SearchRequestGenerator()
        let displayBy = searchGenerator.displayValue(for: .displayBy) as? String
        var cell: UITableViewCell?
        
        
        switch displayBy {
        case "list":
            if viewModel.isEmpty() {
                guard let c = tableView.dequeueReusableCell(withIdentifier: EmptyTableViewCell.reuseIdentifier) as? EmptyTableViewCell else {
                    fatalError("\(EmptyTableViewCell.reuseIdentifier) is nil")
                }
                cell = c
                
            } else {
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardTableViewCell.reuseIdentifier) as? CardTableViewCell else {
                    fatalError("\(CardTableViewCell.reuseIdentifier) is nil")
                }
                let card = viewModel!.object(forRowAt: indexPath)
                c.card = card
                cell = c
            }
            
        case "grid":
            guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier) as? CardGridTableViewCell else {
                fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
            }
            let sectionIndexWidth = viewModel.sectionIndexTitles() != nil ? CGFloat(44) : CGFloat(0)
            let margins = CGFloat(16)
            let width = tableView.frame.size.width - sectionIndexWidth - margins
            var height = tableView.frame.size.height
            var size = CGSize(width: 0, height: 0)
            
            if viewModel.isEmpty() {
                height /= 3
                size = CGSize(width: width, height: height)
            } else {
                height -= kCardTableViewCellHeight - CGFloat(44)
                size = cardSize(inFrame: CGSize(width: width, height: height))
            }
            
            c.viewModel = viewModel
            c.delegate = self
            c.imageType = .normal
            c.updateItemSize(with: size)
            cell = c
            
        default:
            ()
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
extension SearchViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let searchGenerator = SearchRequestGenerator()
        var height = CGFloat(0)
        
        guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
            return height
        }
        
        switch displayBy {
        case "list":
            if viewModel.isEmpty() {
                height = tableView.frame.size.height / 3
            } else {
                height = kCardTableViewCellHeight
            }
        case "grid":
            height = tableView.frame.size.height
        default:
            ()
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cards = viewModel.allObjects() else {
            return
        }
        
        let card = viewModel.object(forRowAt: indexPath)
        let cardIndex = cards.index(of: card)
        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
        let sender = ["cardIndex": cardIndex as Any,
                      "cardIDs": cards.map({ $0.id })]
        performSegue(withIdentifier: identifier, sender: sender)
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
extension SearchViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
//        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
//        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
        viewModel.queryString = searchController.searchBar.text ?? ""
        viewModel.fetchData()
        
        let searchGenerator = SearchRequestGenerator()
        guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
            return
        }
        
        tableView.reloadData()
        
        switch displayBy {
        case "grid":
            guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CardGridTableViewCell else {
                return
            }
            cell.collectionView.reloadData()
        default:
            ()
        }

    }
}

// MARK:
extension SearchViewController : CardGridTableViewCellDelegate {
    func showCard(identifier: String, cardIndex: Int, cardIDs: [String]) {
        let sender = ["cardIndex": cardIndex as Any,
                      "cardIDs": cardIDs]
        performSegue(withIdentifier: identifier, sender: sender)
    }
}



