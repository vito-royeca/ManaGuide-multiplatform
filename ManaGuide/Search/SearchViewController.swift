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

class SearchViewController: BaseViewController {

    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var viewModel: SearchViewModel!
    var collectionView: UICollectionView?
    
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
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                                  object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateData(_:)),
                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                               object: nil)
        
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
        
        rightMenuButton.image = UIImage.init(icon: .FABars,
                                             size: CGSize(width: 30, height: 30),
                                             textColor: .white,
                                             backgroundColor: .clear)
        rightMenuButton.title = nil
        
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"),
                           forCellReuseIdentifier: CardTableViewCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
        
        title = viewModel.getSearchTitle()
        viewModel.fetchData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        updateDataDisplay()
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
//        if tableView != nil { // check if we have already loaded
            updateDataDisplay()
//        }
    }

    // MARK: Custom methods
    @objc func updateData(_ notification: Notification) {
        let searchGenerator = SearchRequestGenerator()
        searchGenerator.syncValues(notification)
        
        updateDataDisplay()
    }
    
    func updateDataDisplay() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController?.searchBar.isHidden = false
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        viewModel.fetchData()
        tableView.reloadData()
        collectionView?.reloadData()
    }
}

// MARK: UITableViewDataSource
extension SearchViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchGenerator = SearchRequestGenerator()
        let displayBy = searchGenerator.displayValue(for: .displayBy) as? String
        var cell: UITableViewCell?
        
        
        switch displayBy {
        case "list":
            guard let c = tableView.dequeueReusableCell(withIdentifier: CardTableViewCell.reuseIdentifier) as? CardTableViewCell else {
                fatalError("\(CardTableViewCell.reuseIdentifier) is nil")
            }
            let card = viewModel!.object(forRowAt: indexPath)
            c.card = card
            
            collectionView = nil
            cell = c
            
        case "grid":
            guard let c = tableView.dequeueReusableCell(withIdentifier: "GridCell") else {
                return UITableViewCell(frame: CGRect.zero)
            }
            guard let collectionView = c.viewWithTag(100) as? UICollectionView else {
                return UITableViewCell(frame: CGRect.zero)
            }
            
            collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
            collectionView.dataSource = self
            collectionView.delegate = self
            
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let sectionIndexWidth = viewModel.sectionIndexTitles() != nil ? CGFloat(44) : CGFloat(0)
                let width = tableView.frame.size.width - sectionIndexWidth
                let height = tableView.frame.size.height - kCardTableViewCellHeight - CGFloat(44)
                
                flowLayout.itemSize = cardSize(inFrame: CGSize(width: width, height: height))
                flowLayout.minimumInteritemSpacing = CGFloat(0)
                flowLayout.minimumLineSpacing = CGFloat(10)
                flowLayout.headerReferenceSize = CGSize(width: width, height: 22)
                flowLayout.sectionHeadersPinToVisibleBounds = true
            }
            
            self.collectionView = collectionView
            cell = c
            
        default:
            ()
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
extension SearchViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let searchGenerator = SearchRequestGenerator()
        var height = CGFloat(0)
        
        guard let displayBy = searchGenerator.displayValue(for: .displayBy) as? String else {
            return height
        }
        
        switch displayBy {
        case "list":
            height = kCardTableViewCellHeight
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
}

// UICollectionViewDataSource
extension SearchViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.collectionNumberOfRows(inSection: section)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.collectionNumberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardImageCell", for: indexPath)
        
        guard let imageView = cell.viewWithTag(100) as? UIImageView else {
            fatalError("Unexpected indexPath: \(indexPath)")
        }
        let card = viewModel.object(forRowAt: indexPath)
        
        if let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) {
            imageView.image = image
        } else {
            imageView.image = ManaKit.sharedInstance.cardBack(card)
            
            firstly {
                ManaKit.sharedInstance.downloadImage(ofCard: card, imageType: .normal)
            }.done {
                guard let image = ManaKit.sharedInstance.cardImage(card, imageType: .normal) else {
                    return
                }
                
                let animations = {
                    imageView.image = image
                }
                UIView.transition(with: imageView,
                                  duration: 1.0,
                                  options: .transitionFlipFromRight,
                                  animations: animations,
                                  completion: nil)
            }.catch { error in
                print("\(error)")
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let v = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier:"Header", for: indexPath)
        
        if kind == UICollectionView.elementKindSectionHeader {
            v.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
            
            if v.subviews.count == 0 {
                let label = UILabel(frame: CGRect(x: 20, y: 0, width: collectionView.frame.size.width - 20, height: 22))
                label.tag = 100
                v.addSubview(label)
            }
            
            guard let lab = v.viewWithTag(100) as? UILabel else {
                return v
            }
            
            lab.text = viewModel.collectionTitleForHeaderInSection(section: indexPath.section)//SectionIndexTitles()?[indexPath.section]
        }
        
        return v
    }
}

// UICollectionViewDelegate
extension SearchViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        
        switch displayBy {
        case "list":
            tableView.reloadData()
        case "grid":
            collectionView?.reloadData()
        default:
            ()
        }

    }
}

// MARK: NSFetchedResultsControllerDelegate
extension SearchViewController : NSFetchedResultsControllerDelegate {
    
}


