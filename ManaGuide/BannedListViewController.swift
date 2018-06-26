//
//  BannedListViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource
import ManaKit

class BannedListViewController: BaseViewController {

    // MARK: Variables
    var dataSource: DATASource?
    var sectionIndexTitles = [String]()
    var sectionTitles = [String]()

    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dataSource = getDataSource(nil)
        updateSections()
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any] else {
                return
            }
            
            dest.request = dict["request"] as? NSFetchRequest<NSFetchRequestResult>
            dest.title = dict["title"] as? String
            dest.customSectionName = "legality.name"
        }
    }
    
    // MARK: Custom methods
    func getDataSource(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>?) -> DATASource? {
        var request:NSFetchRequest<NSFetchRequestResult>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            request = CMFormat.fetchRequest()
            
            request!.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            request!.predicate = NSPredicate(format: "ANY cardLegalities.legality.name IN %@", ["Banned", "Restricted"])
        }
        
        let configuration = { (cell: UITableViewCell, item: NSManagedObject, indexPath: IndexPath) -> Void  in
            guard let format = item as? CMFormat,
                let label = cell.textLabel else {
                return
            }
            
            label.text = format.name
        }
        
        let ds = DATASource(tableView: tableView,
                            cellIdentifier: "Cell",
                            fetchRequest: request!,
                            mainContext: ManaKit.sharedInstance.dataStack!.mainContext,
                            sectionName: "nameSection",
                            configuration: configuration)
        ds.delegate = self
        
        return ds
    }
    
    func updateSections() {
        if let dataSource = dataSource {
            let formats = dataSource.all() as [CMFormat]
            sectionIndexTitles = [String]()
            sectionTitles = [String]()
            
            for format in formats {
                let prefix = String(format.name!.prefix(1))
                
                if !sectionIndexTitles.contains(prefix) {
                    sectionIndexTitles.append(prefix)
                }
            }
            
            let sections = dataSource.numberOfSections(in: tableView)
            if sections > 0 {
                for i in 0...sections - 1 {
                    if let sectionTitle = dataSource.titleForHeader(i) {
                        sectionTitles.append(sectionTitle)
                    }
                }
            }
        }
        
        sectionIndexTitles.sort()
        sectionTitles.sort()
    }
}

// MARK: UITableViewDelegate
extension BannedListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let format = dataSource!.object(indexPath) as? CMFormat else {
            return
        }
        guard let name = format.name else {
            return
        }
        
        let request = CMCardLegality.fetchRequest()
        let predicate = NSPredicate(format: "legality.name IN %@ AND format.name IN %@", ["Banned", "Restricted"], [name])
        
        request.sortDescriptors = [NSSortDescriptor(key: "legality.name", ascending: true),
                                    NSSortDescriptor(key: "card.name", ascending: true)]
        request.predicate = predicate
        
        performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                            "title": name])
    }
}

// MARK: DATASourceDelegate
extension BannedListViewController : DATASourceDelegate {
    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
    func sectionIndexTitlesForDataSource(_ dataSource: DATASource, tableView: UITableView) -> [String] {
        return sectionIndexTitles
    }
    
    // tell table which section corresponds to section title/index (e.g. "B",1))
    func dataSource(_ dataSource: DATASource, tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
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

