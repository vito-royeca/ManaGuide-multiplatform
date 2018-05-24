//
//  MoreViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 06/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import DATASource

enum MoreViewControllerRow: Int {
    case basicRules
    case comprehensiveRules
    case bannedList
    case reservedList
    case artists
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .basicRules: return "Basic Rules"
        case .comprehensiveRules: return "Comprehensive Rules"
        case .bannedList: return "Banned and Restricted List"
        case .reservedList: return "Reserved List"
        case .artists: return "Artists"
        }
    }
    
    static var count: Int {
        return 5
    }
}

class MoreViewController: UIViewController {
    
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
        }
    }

}

// MARK: UITableViewDataSource
extension MoreViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MoreViewControllerRow.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        var text: String? = nil
        
        switch indexPath.row {
        case MoreViewControllerRow.basicRules.rawValue:
            text = MoreViewControllerRow.basicRules.description
        case MoreViewControllerRow.comprehensiveRules.rawValue:
            text = MoreViewControllerRow.comprehensiveRules.description
        case MoreViewControllerRow.bannedList.rawValue:
            text = MoreViewControllerRow.bannedList.description
        case MoreViewControllerRow.reservedList.rawValue:
            text = MoreViewControllerRow.reservedList.description
        case MoreViewControllerRow.artists.rawValue:
            text = MoreViewControllerRow.artists.description
        default:
            ()
        }
        
        cell!.textLabel?.text = text
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension MoreViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case MoreViewControllerRow.basicRules.rawValue:
            ()
        case MoreViewControllerRow.comprehensiveRules.rawValue:
            performSegue(withIdentifier: "showComprehensiveRules", sender: nil)
        case MoreViewControllerRow.bannedList.rawValue:
            performSegue(withIdentifier: "showBannedList", sender: nil)
        case MoreViewControllerRow.reservedList.rawValue:
            let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CMCard")
            request.predicate = NSPredicate(format: "reserved = true")
            request.sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                                       NSSortDescriptor(key: "name", ascending: true),
                                       NSSortDescriptor(key: "set.releaseDate", ascending: true)]
            performSegue(withIdentifier: "showSearch", sender: ["title": "Reserved List",
                                                                "request": request])
        case MoreViewControllerRow.artists.rawValue:
            performSegue(withIdentifier: "showArtists", sender: nil)
        default:
            ()
        }
    }
}
