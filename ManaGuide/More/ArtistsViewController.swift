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

    // MARK: Constants
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: Variables
    var fetchedResultsController: NSFetchedResultsController<CMArtist>?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter"
        definesPresentationContext = true
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        tableView.keyboardDismissMode = .onDrag
        
        fetchedResultsController = getFetchedResultsController(with: nil)
        updateSections()
        tableView.reloadData()
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
    
    // MARK: Custom methods
    func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMArtist>?) -> NSFetchedResultsController<CMArtist> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMArtist>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // Create a default fetchRequest
            request = CMArtist.fetchRequest()
            request!.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                        NSSortDescriptor(key: "lastName", ascending: true),
                                        NSSortDescriptor(key: "firstName", ascending: true)]

        }
        
        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: request!,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        
        // Configure Fetched Results Controller
        frc.delegate = self
        
        // perform fetch
        do {
            try frc.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        return frc
    }

    func updateSections() {
        guard let fetchedResultsController = fetchedResultsController,
            let artists = fetchedResultsController.fetchedObjects,
            let sections = fetchedResultsController.sections else {
                return
        }
        
        
        let letters = CharacterSet.letters
        
        sectionIndexTitles = [String]()
        sectionTitles = [String]()
        
        for artist in artists {
            let names = artist.name!.components(separatedBy: " ")
            
            if let lastName = names.last {
                var prefix = String(lastName.prefix(1))
                if prefix.rangeOfCharacter(from: letters) == nil {
                    prefix = "#"
                }
                prefix = prefix.uppercased().folding(options: .diacriticInsensitive, locale: .current)
                
                if !sectionIndexTitles.contains(prefix) {
                    sectionIndexTitles.append(prefix)
                }
            }
        }
        
        let count = sections.count
        if count > 0 {
            for i in 0...count - 1 {
                if let sectionTitle = sections[i].indexTitle {
                    sectionTitles.append(sectionTitle)
                }
            }
        }
        
        sectionIndexTitles.sort()
        sectionTitles.sort()
    }

    func doSearch() {
        guard let text = searchController.searchBar.text else {
            return
        }
        var newRequest: NSFetchRequest<CMArtist>?
        
        if text.count > 0 {
            newRequest = CMArtist.fetchRequest()
            
            newRequest!.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                           NSSortDescriptor(key: "lastName", ascending: true),
                                           NSSortDescriptor(key: "firstName", ascending: true)]
            
            if text.count == 1 {
                newRequest!.predicate = NSPredicate(format: "firstName BEGINSWITH[cd] %@ OR lastName BEGINSWITH[cd] %@", text, text)
            } else if text.count > 1 {
                newRequest!.predicate = NSPredicate(format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", text, text)
            }
            fetchedResultsController = getFetchedResultsController(with: newRequest)
            updateSections()
            tableView.reloadData()
            
        } else {
            fetchedResultsController = getFetchedResultsController(with: nil)
            updateSections()
            tableView.reloadData()
        }
    }
}

// MARK: UITableViewDataSource
extension ArtistsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let artists = fetchedResultsController.fetchedObjects else {
                return 0
        }
        
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("Unexpected indexPath: \(indexPath)")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                                 for: indexPath)
        let artist = fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
        guard let label = cell.textLabel else {
            fatalError("UILabel not found")
        }
        
        label.text = artist.name
        
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        var sectionIndex = 0
        
        for i in 0...sectionTitles.count - 1 {
            if sectionTitles[i].hasPrefix(title) {
                sectionIndex = i
                break
            }
        }
        
        return sectionIndex
        
    }
}

// MARK: UITableViewDelegate
extension ArtistsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let fetchedResultsController = fetchedResultsController else {
            return
        }
        
        let artist = fetchedResultsController.object(at: indexPath)
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "artist_.name = %@", artist.name!)
        
        performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                            "title": artist.name!])
    }
}

// MARK: UISearchResultsUpdating
extension ArtistsViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doSearch), object: nil)
        perform(#selector(doSearch), with: nil, afterDelay: 0.5)
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension ArtistsViewController : NSFetchedResultsControllerDelegate {
    
}




