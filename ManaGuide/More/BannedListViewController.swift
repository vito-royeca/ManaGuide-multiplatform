//
//  BannedListViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import ManaKit

class BannedListViewController: BaseViewController {

    // MARK: Variables
    var fetchedResultsController: NSFetchedResultsController<CMFormat>?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()

    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fetchedResultsController = getFetchedResultsController(with: nil)
        updateSections()
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any] else {
                return
            }
            
            dest.request = dict["request"] as? NSFetchRequest<CMCard>
            dest.title = dict["title"] as? String
            dest.customSectionName = "legality.name"
        }
    }
    
    // MARK: Custom methods
    func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMFormat>?) -> NSFetchedResultsController<CMFormat> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMFormat>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // create a default fetchRequest
            request = CMFormat.fetchRequest()
            request!.predicate = NSPredicate(format: "ANY cardLegalities.legality.name IN %@", ["Banned", "Restricted"])
            request!.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
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
            let formats = fetchedResultsController.fetchedObjects,
            let sections = fetchedResultsController.sections else {
                return
        }
        
        sectionIndexTitles = [String]()
        sectionTitles = [String]()
        
        for format in formats {
            let prefix = String(format.name!.prefix(1))
            
            if !sectionIndexTitles.contains(prefix) {
                sectionIndexTitles.append(prefix)
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
}

// MARK: UITableViewDataSource
extension BannedListViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let formats = fetchedResultsController.fetchedObjects else {
                return 0
        }
        
        return formats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("Unexpected indexPath: \(indexPath)")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                                 for: indexPath)
        let format = fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
        guard let label = cell.textLabel else {
                fatalError("UILabel not found")
        }
        label.text = format.name
        
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
extension BannedListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let fetchedResultsController = fetchedResultsController else {
            fatalError("Unexpected indexPath: \(indexPath)")
        }
        let format = fetchedResultsController.object(at: indexPath)
        
        guard let name = format.name else {
            return
        }
        
        let request: NSFetchRequest<CMCardLegality> = CMCardLegality.fetchRequest()
        let predicate = NSPredicate(format: "legality.name IN %@ AND format.name IN %@", ["Banned", "Restricted"], [name])
        
        request.sortDescriptors = [NSSortDescriptor(key: "legality.name", ascending: true),
                                    NSSortDescriptor(key: "card.name", ascending: true)]
        request.predicate = predicate
        
        performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                            "title": name])
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension BannedListViewController : NSFetchedResultsControllerDelegate {
    
}
