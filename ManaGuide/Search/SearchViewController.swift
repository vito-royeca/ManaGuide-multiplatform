//
//  SearchViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 20/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import FontAwesome_swift
import InAppSettingsKit
import MBProgressHUD
import ManaKit
import PromiseKit

protocol SearchViewControllerDelegate: NSObjectProtocol {
    func reloadViewModel() -> SearchViewModel
}

class SearchViewController: BaseSearchViewController {
    // MARK: Variables
    var delegate: SearchViewControllerDelegate?
    
    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    
    // MARK: Actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Search")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .slidersH,
                                                        style: .solid,
                                                        textColor: LookAndFeel.GlobalTintColor,
                                                        size: CGSize(width: 30, height: 30))
        rightMenuButton.title = nil

        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "CardGridTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: CardGridTableViewCell.reuseIdentifier)
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"),
                           forCellReuseIdentifier: CardTableViewCell.reuseIdentifier)
        
        title = viewModel.title
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Settings
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateSettings(_:)),
                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                               object: nil)
        // Favorites
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateData(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                               object: nil)
        // Ratings
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateData(_:)),
                                               name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                               object: nil)
        
        if let delegate = delegate {
            viewModel = delegate.reloadViewModel()
        }
        updateDataDisplay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Remove notification listeners
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                                  object:nil)
        // Favorites
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                  object:nil)
        // Ratings
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
                let dest = nav.children.first as? CardViewController,
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return createCardCell(at: indexPath)
    }

    // MARK: Notification handlers
    @objc func updateSettings(_ notification: Notification) {
        let searchGenerator = SearchRequestGenerator()
        searchGenerator.syncValues(notification)
        
        if viewModel.mode != .standBy {
            viewModel.mode = .loading
            updateDataDisplay()
        } else {
            tableView.reloadData()
        }
    }
    
    @objc func updateData(_ notification: Notification) {
        if let delegate = delegate {
            viewModel = delegate.reloadViewModel()
            viewModel.mode = .loading
            updateDataDisplay()
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
        
        if viewModel.mode == .loading {
            fetchData()
        }
    }
    
    func createCardCell(at indexPath: IndexPath) -> UITableViewCell {
        let searchGenerator = SearchRequestGenerator()
        let displayBy = searchGenerator.displayValue(for: .displayBy) as? String
        var cell: UITableViewCell?
        
        switch displayBy {
        case "list":
            switch viewModel.mode {
            case .resultsFound:
                guard let c = tableView.dequeueReusableCell(withIdentifier: CardTableViewCell.reuseIdentifier) as? CardTableViewCell,
                    let card = viewModel.object(forRowAt: indexPath) as? CMCard else {
                    fatalError("\(CardTableViewCell.reuseIdentifier) is nil")
                }
                c.card = card
                cell = c
            default:
                guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier) as? SearchModeTableViewCell else {
                    fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
                }
                c.mode = viewModel.mode
                cell = c
            }
            
        case "grid":
            guard let c = tableView.dequeueReusableCell(withIdentifier: CardGridTableViewCell.reuseIdentifier) as? CardGridTableViewCell,
                let viewModel = viewModel as? SearchViewModel else {
                fatalError("\(CardGridTableViewCell.reuseIdentifier) is nil")
            }
            let sectionIndexWidth = viewModel.sectionIndexTitles() != nil ? CGFloat(44) : CGFloat(0)
            let width = tableView.frame.size.width - sectionIndexWidth
            var height = tableView.frame.size.height
            var size = CGSize(width: 0, height: 0)
            
            if viewModel.mode == .resultsFound {
                height -= CardTableViewCell.cellHeight - CGFloat(44)
                size = cardSize(inFrame: CGSize(width: width, height: height))
            } else {
                height /= 3
                size = CGSize(width: width, height: height)
            }
            
            c.viewModel = viewModel
            c.delegate = self
            c.imageType = .normal
            c.animationOptions = .transitionFlipFromLeft
            c.updateItemSize(with: size)
            cell = c
            
        default:
            ()
        }
        
        return cell!
    }
    
    func heightForCell() -> CGFloat {
        let searchGenerator = SearchRequestGenerator()
        var height = CGFloat(0)
        
        guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
            return height
        }
        
        switch displayBy {
        case "list":
            if viewModel.mode == .resultsFound {
                height = CardTableViewCell.cellHeight
            } else {
                height = tableView.frame.size.height / 3
            }
        case "grid":
            height = tableView.frame.size.height
        default:
            ()
        }
        
        return height
    }
    
    func handleDidSelectRow(at indexPath: IndexPath) {
        guard let cards = viewModel.allObjects() as? [CMCard],
            let card = viewModel.object(forRowAt: indexPath) as? CMCard else {
            return
        }
        
        let cardIndex = cards.index(of: card)
        let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
        let sender = ["cardIndex": cardIndex as Any,
                      "cardIDs": cards.map({ $0.id })]
        performSegue(withIdentifier: identifier, sender: sender)
    }
    
    func handleWillSelectRow(at indexPath: IndexPath) -> IndexPath? {
        if viewModel.mode == .resultsFound {
            return indexPath
        } else {
            return nil
        }
    }
}

// MARK: UITableViewDelegate
extension SearchViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightForCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleDidSelectRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return handleWillSelectRow(at: indexPath)
    }
}

// MARK: CardGridTableViewCellDelegate
extension SearchViewController : CardGridTableViewCellDelegate {
    func showCard(identifier: String, cardIndex: Int, cardIDs: [String], sorters: [NSSortDescriptor]?) {
        var sender = ["cardIndex": cardIndex as Any,
                      "cardIDs": cardIDs]
        performSegue(withIdentifier: identifier, sender: sender)
    }
}



