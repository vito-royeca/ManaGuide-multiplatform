//
//  SetViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import FontAwesome_swift
import InAppSettingsKit
import ManaKit
import MBProgressHUD
import PromiseKit
import RealmSwift

class SetViewController: SearchViewController {
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!

    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        guard let viewModel = viewModel as? SetViewModel else {
            fatalError()
        }
        
        viewModel.content = sender.selectedSegmentIndex == 0 ? .cards : .wiki
        countLabel.isHidden = sender.selectedSegmentIndex == 0 ? false : true
        updateDataDisplay()
    }
    
    @IBAction func showRightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Search")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentSegmentedControl.setImage(UIImage.fontAwesomeIcon(name: .images,
                                                                 style: .solid,
                                                                 textColor: LookAndFeel.GlobalTintColor,
                                                                 size: CGSize(width: 30, height: 30)),
                                         forSegmentAt: 0)
        contentSegmentedControl.setImage(UIImage.fontAwesomeIcon(name: .wikipediaW,
                                                                 style: .brands,
                                                                 textColor: LookAndFeel.GlobalTintColor,
                                                                 size: CGSize(width: 30, height: 30)),
                                         forSegmentAt: 1)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                                  object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateData(_:)),
                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                               object: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.rightBarButtonItem = nil
        } else {
            rightMenuButton.image = UIImage.fontAwesomeIcon(name: .slidersH,
                                                            style: .solid,
                                                            textColor: LookAndFeel.GlobalTintColor,
                                                            size: CGSize(width: 30, height: 30))
            rightMenuButton.title = nil
        }
        
        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: "CardGridTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: CardGridTableViewCell.reuseIdentifier)
        tableView.register(ManaKit.sharedInstance.nibFromBundle("CardTableViewCell"),
                           forCellReuseIdentifier: CardTableViewCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
        
        title = viewModel.title
    }

    override func viewDidAppear(_ animated: Bool) {
        guard let viewModel = viewModel as? SetViewModel else {
            fatalError()
        }

        switch viewModel.content {
        case .cards:
            super.viewDidAppear(animated)
        case .wiki:
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
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //let searchGenerator = SearchRequestGenerator()
        //let sortDescriptors = searchGenerator.createSortDescriptors()
        
        if segue.identifier == "showCard" {
            guard let dest = segue.destination as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let predicate = dict["predicate"] as? NSPredicate else {
                return
            }
            
            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withPredicate: predicate,
                                           withSortDescriptors: dict["sortDescriptors"] as? [SortDescriptor],
                                           andMode: .loading)

        } else if segue.identifier == "showCardModal" {
            guard let nav = segue.destination as? UINavigationController,
                let dest = nav.children.first as? CardViewController,
                let dict = sender as? [String: Any],
                let cardIndex = dict["cardIndex"] as? Int,
                let predicate = dict["predicate"] as? NSPredicate else {
                return
            }

            dest.viewModel = CardViewModel(withCardIndex: cardIndex,
                                           withPredicate: predicate,
                                           withSortDescriptors: dict["sortDescriptors"] as? [SortDescriptor],
                                           andMode: .loading)
            
        } else if segue.identifier == "showSearch" {
            /*guard let dest = segue.destination as? SearchViewController,
                let request = sender as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request,
                                             andTitle: "Search Results",
                                             andMode: .loading)*/
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = viewModel as? SetViewModel else {
            fatalError()
        }
        
        var cell: UITableViewCell?
        
        switch viewModel.content {
        case .cards:
            cell = createCardCell(at: indexPath)
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
                cell = c
            }
        }
        
        return cell!
    }
    
    // MARK: Custom methods
    override func updateDataDisplay() {
        guard let viewModel = viewModel as? SetViewModel else {
            fatalError()
        }
        
        switch viewModel.content {
        case .cards:
            if #available(iOS 11.0, *) {
                navigationItem.searchController?.searchBar.isHidden = false
                navigationItem.hidesSearchBarWhenScrolling = false
            } else {
                tableView.tableHeaderView = searchController.searchBar
            }
            
            if viewModel.mode == .loading {
                fetchData()
            } else {
                tableView.reloadData()
            }
            
        case .wiki:
            if #available(iOS 11.0, *) {
                navigationItem.searchController?.searchBar.isHidden = true
                navigationItem.hidesSearchBarWhenScrolling = true
            } else {
                tableView.tableHeaderView = nil
            }
            
            tableView.dataSource = self
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let viewModel = viewModel as? SetViewModel else {
            fatalError()
        }
        
        var height = CGFloat(0)

        switch viewModel.content {
        case .cards:
            height = heightForCell()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = viewModel as? SetViewModel else {
            fatalError()
        }
        
        switch viewModel.content {
        case .cards:
            handleDidSelectRow(at: indexPath)
        case .wiki:
            ()
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let viewModel = viewModel as? SetViewModel else {
            fatalError()
        }
        
        switch viewModel.content {
        case .cards:
            return handleWillSelectRow(at: indexPath)
        case .wiki:
            ()
        }
        
        return nil
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
                var cardName = ""
                var setCode = ""
                
                for component in value.components(separatedBy: "\"") {
                    if component.hasPrefix("+set:") {
                        setCode = component.replacingOccurrences(of: "+set:", with: "").lowercased()
                    } else if component.hasPrefix("!") {
                        continue
                    } else {
                        cardName = component.replacingOccurrences(of: "+", with: " ")
                            .replacingOccurrences(of: "\"", with: "")
                    }
                }
                
                let predicate = NSPredicate(format: "name = %@ AND set.code = %@ AND language.code = %@", cardName, setCode, "en")
                let results =  ManaKit.sharedInstance.realm.objects(CMCard.self).filter(predicate)

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
                    let alertVC = UIAlertController(title: "Card Not found",
                                                    message: "The card: \(cardName) was not found in the database",
                                                    preferredStyle: .alert)
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
