//
//  MoreViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 06/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource

enum MoreViewControllerRows: Int {
    case basicRules, comprehensiveRules, bannedList, reservedList
}

class MoreViewController: UIViewController {

    // Constants:
    let rowTitles = ["Basic Rules", "Comprehensive Rules", "Banned and Restricted List", "Reserved List"]
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearch" {
            if let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any] {
                
                dest.request = dict["request"] as? NSFetchRequest<NSFetchRequestResult>
                dest.title = dict["title"] as? String
                dest.customSectionName = "nameSection"
            }
        } else if segue.identifier == "showComprehensiveRules" {
//            if let dest = segue.destination as? ComprehensiveRulesViewController {
//                
//                
//            }
        }
    }

}

// MARK: UITableViewDataSource
extension MoreViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowTitles.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        cell!.textLabel?.text = rowTitles[indexPath.row]
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension MoreViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case MoreViewControllerRows.basicRules.rawValue:
            ()
        case MoreViewControllerRows.comprehensiveRules.rawValue:
            performSegue(withIdentifier: "showComprehensiveRules", sender: nil)
        case MoreViewControllerRows.bannedList.rawValue:
            performSegue(withIdentifier: "showBannedList", sender: nil)
        case MoreViewControllerRows.reservedList.rawValue:
            let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
            request.predicate = NSPredicate(format: "reserved = true")
            request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                       NSSortDescriptor(key: "name", ascending: true),
                                       NSSortDescriptor(key: "set.releaseDate", ascending: true)]
            performSegue(withIdentifier: "showSearch", sender: ["title": "Reserved List",
                                                                "request": request])
        default:
            ()
        }
    }
}
