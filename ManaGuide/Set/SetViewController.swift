//
//  SetViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import Font_Awesome_Swift
import InAppSettingsKit
import ManaKit
import MBProgressHUD
import PromiseKit

class SetViewController: BaseViewController {
    // MARK: Variables
    let searchController = UISearchController(searchResultsController: nil)
    var viewModel: SetViewModel!
    var collectionView: UICollectionView?
    
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        viewModel.setContent = sender.selectedSegmentIndex == 0 ? .cards : .wiki
        updateDataDisplay()
    }
    
    @IBAction func showRightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Search")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentSegmentedControl.setFAIcon(icon: .FADatabase, forSegmentAtIndex: 0)
        contentSegmentedControl.setFAIcon(icon: .FAWikipediaW, forSegmentAtIndex: 1)
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let searchGenerator = SearchRequestGenerator()
        let sortDescriptors = searchGenerator.createSortDescriptors()
        
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController,
                let dict = sender as? [String: Any],
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
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let cardIDs = dict["cardIDs"] as? [String] else {
                return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withCardIDs: cardIDs,
                                           withSortDescriptors: sortDescriptors)
            
        } else if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let request = sender as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request, andTitle: "Search Results")
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateDataDisplay()
    }
    
    // MARK: Custom methods
    @objc func updateData(_ notification: Notification) {
        let searchGenerator = SearchRequestGenerator()
        searchGenerator.syncValues(notification)
        
        updateDataDisplay()
    }

    func updateDataDisplay() {
        switch viewModel.setContent {
        case .cards:
            if #available(iOS 11.0, *) {
                navigationItem.searchController?.searchBar.isHidden = false
                navigationItem.hidesSearchBarWhenScrolling = false
            } else {
                tableView.tableHeaderView = searchController.searchBar
            }
            
        case .wiki:
            if #available(iOS 11.0, *) {
                navigationItem.searchController?.searchBar.isHidden = true
                navigationItem.hidesSearchBarWhenScrolling = true
            } else {
                tableView.tableHeaderView = nil
            }
            
            tableView.dataSource = self
        }
        
        viewModel.fetchData()
        tableView.reloadData()
        collectionView?.reloadData()
    }
}

// MARK: UITableViewDataSource
extension SetViewController : UITableViewDataSource {
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
        
        switch viewModel.setContent {
        case .cards:
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
        case .wiki:
            switch indexPath.row {
            case 0:
                guard let c = tableView.dequeueReusableCell(withIdentifier: BrowserNavigatorTableViewCell.reuseIdentifier) as? BrowserNavigatorTableViewCell else {
                    fatalError("BrowserNavigatorTableViewCell is nil")
                }
                c.delegate = self
                cell = c
            default:
                guard let c = tableView.dequeueReusableCell(withIdentifier: BrowserTableViewCell.reuseIdentifier) as? BrowserTableViewCell,
                    let url = viewModel.wikiURL() else {
                    fatalError("BrowserTableViewCell is nil")
                }
                
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0)
                c.webView.delegate = self
                c.webView.loadRequest(request)
                
                collectionView = nil
                cell = c
            }
            
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
extension SetViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = CGFloat(0)

        switch viewModel.setContent {
        case .cards:
            let searchGenerator = SearchRequestGenerator()
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
        case .wiki:
            switch indexPath.row {
            case 0:
                height = 44
            default:
                height = tableView.frame.size.height - 44
            }
        }
        
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.setContent {
        case .cards:
            guard let cards = viewModel.allObjects() else {
                return
            }

            let card = viewModel.object(forRowAt: indexPath)
            let cardIndex = cards.index(of: card)
            let identifier = UIDevice.current.userInterfaceIdiom == .phone ? "showCard" : "showCardModal"
            let sender = ["cardIndex": cardIndex as Any,
                          "cardIDs": cards.map({ $0.id })]
            performSegue(withIdentifier: identifier, sender: sender)
        default:
            ()
        }
    }
}

// UICollectionViewDataSource
extension SetViewController : UICollectionViewDataSource {
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
extension SetViewController : UICollectionViewDelegate {
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

// MARK: UIWebViewDelegate
extension SetViewController : UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard let url = request.url,
            let host = url.host else {
            return false
        }
        
        var willLoad = false
        
        if host.contains("gamepedia.com") {
            willLoad = true
        } else if host.contains("magiccards.info") ||
            host.contains("scryfall.com") {
            
            // Show the card instead opening the link!!!
            let urlComponents = URLComponents(string: url.absoluteString)
            let queryItems = urlComponents?.queryItems
            let q = queryItems?.filter({$0.name == "q"}).first
            
            if let value = q?.value {
                let r = value.index(value.startIndex, offsetBy: 1)
                let cardName = value.substring(from: r).replacingOccurrences(of: "+", with: " ")
                               .replacingOccurrences(of: "\"", with: "")
                
                let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                request.predicate = NSPredicate(format: "name = %@", cardName)
                request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                            NSSortDescriptor(key: "name", ascending: true)]
                
                let results = try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request)
                if results.count == 1 {
                    if let card = results.first {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            performSegue(withIdentifier: "showCard", sender: ["cardIndex": 0 as Any,
                                                                              "cardIDs": [card.id!]])
                        } else if UIDevice.current.userInterfaceIdiom == .pad {
                            performSegue(withIdentifier: "showCardModal", sender: ["cardIndex": 0 as Any,
                                                                                   "cardIDs": [card.id!]])
                        }
                    }
                } else if results.count > 1 {
                    performSegue(withIdentifier: "showSearch", sender: request)
                } else {
                    let alertVC = UIAlertController(title: "Card Not found", message: "The card: \(cardName) was not found in the database", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertVC.addAction(okAction)
                    present(alertVC, animated: true, completion: nil)
                }
            }
        }
        
        return willLoad
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        toggleBrowser(enabled: false)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        toggleBrowser(enabled: true)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        toggleBrowser(enabled: true)
        
        var html = "<html><body><center>"
        html.append(error.localizedDescription)
        html.append("</center></body></html>")
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func toggleBrowser(enabled: Bool) {
        guard let navCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BrowserNavigatorTableViewCell,
            let browserCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? BrowserTableViewCell else {
            return
        }

        if enabled {
            MBProgressHUD.hide(for: browserCell.webView, animated: true)
            navCell.backButton.isEnabled = browserCell.webView.canGoBack
            navCell.forwardButton.isEnabled = browserCell.webView.canGoForward
            navCell.refreshButton.isEnabled = true
        } else {
            MBProgressHUD.showAdded(to: browserCell.webView, animated: true)
            navCell.backButton.isEnabled = false
            navCell.forwardButton.isEnabled = false
            navCell.refreshButton.isEnabled = false
        }
        navCell.setNeedsDisplay()
    }
}

// MARK: UISearchResultsUpdating
extension SetViewController : UISearchResultsUpdating {
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

// MARK: BrowserNavigatorTableViewCellDelegate
extension SetViewController : BrowserNavigatorTableViewCellDelegate {
    func back() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? BrowserTableViewCell else {
            return
        }
        
        if cell.webView.canGoBack {
            cell.webView.goBack()
        }
    }
    
    func forward() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? BrowserTableViewCell else {
            return
        }
        
        if cell.webView.canGoForward {
            cell.webView.goForward()
        }
    }
    
    func reload() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? BrowserTableViewCell else {
            return
        }
        
        cell.webView.reload()
    }
}


