//
//  MoreViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 06/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import ManaKit

class MoreViewController: BaseViewController {
    // MARK: Variables
    var viewModel = MoreViewModel()
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPDF" {
            guard let dest = segue.destination as? PDFViewerViewController,
                let dict = sender as? [String: Any] else {
                return
            }
            
            dest.url = dict["url"] as? URL
            dest.title = dict["title"] as? String
            
        } else if segue.identifier == "showComprehensiveRules" {
            guard let dest = segue.destination as? ComprehensiveRulesViewController else {
                return
            }
            
            dest.viewModel = ComprehensiveRulesViewModel(withRule: nil)
            
        } else if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any],
                let request = dict["request"] as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request,
                                             andTitle: dict["title"] as? String,
                                             andMode: .loading)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

}

// MARK: UITableViewDataSource
extension MoreViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        var image: UIImage?
        var text: String? = nil
        
        switch indexPath.section {
        case MoreSection.rules.rawValue:
            switch indexPath.row {
            case MoreRuleRow.basic.rawValue:
                image = MoreRuleRow.basic.imageIcon
                text = MoreRuleRow.basic.description
            case MoreRuleRow.comprehensive.rawValue:
                image = MoreRuleRow.comprehensive.imageIcon
                text = MoreRuleRow.comprehensive.description
            case MoreRuleRow.tournament.rawValue:
                image = MoreRuleRow.tournament.imageIcon
                text = MoreRuleRow.tournament.description
            case MoreRuleRow.ipr.rawValue:
                image = MoreRuleRow.ipr.imageIcon
                text = MoreRuleRow.ipr.description
            case MoreRuleRow.jar.rawValue:
                image = MoreRuleRow.jar.imageIcon
                text = MoreRuleRow.jar.description
            default:
                ()
            }
        case MoreSection.lists.rawValue:
            switch indexPath.row {
            case MoreListRow.bannedAndRestricted.rawValue:
                image = MoreListRow.bannedAndRestricted.imageIcon
                text = MoreListRow.bannedAndRestricted.description
            case MoreListRow.reserved.rawValue:
                image = MoreListRow.reserved.imageIcon
                text = MoreListRow.reserved.description
            case MoreListRow.artists.rawValue:
                image = MoreListRow.artists.imageIcon
                text = MoreListRow.artists.description
            default:
                ()
            }
        default:
            ()
        }
        
        cell!.imageView?.image = image
        cell!.textLabel?.text = text
        cell!.textLabel?.adjustsFontSizeToFitWidth = true

        return cell!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeaderInSection(section: section)
    }
}

// MARK: UITableViewDelegate
extension MoreViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var identifier = ""
        var sender: [String: Any]?
        
        switch indexPath.section {
        case MoreSection.rules.rawValue:
            switch indexPath.row {
            case MoreRuleRow.basic.rawValue:
                identifier = "showPDF"
                sender = ["url": URL(fileURLWithPath: MoreRuleRow.basic.filePath!),
                          "title": MoreRuleRow.basic.description]
                
            case MoreRuleRow.comprehensive.rawValue:
                identifier = "showComprehensiveRules"
                sender = nil
                
            case MoreRuleRow.tournament.rawValue:
                identifier = "showPDF"
                sender = ["url": URL(fileURLWithPath: MoreRuleRow.tournament.filePath!),
                          "title": MoreRuleRow.tournament.description]
                
            case MoreRuleRow.ipr.rawValue:
                identifier = "showPDF"
                sender = ["url": URL(fileURLWithPath: MoreRuleRow.ipr.filePath!),
                          "title": MoreRuleRow.ipr.description]
                
            case MoreRuleRow.jar.rawValue:
                identifier = "showPDF"
                sender = ["url": URL(fileURLWithPath: MoreRuleRow.jar.filePath!),
                          "title": MoreRuleRow.jar.description]

            default:
                ()
            }
        case MoreSection.lists.rawValue:
            switch indexPath.row {
            case MoreListRow.bannedAndRestricted.rawValue:
                identifier = "showBannedAndRestricted"
                sender = nil
                
            case MoreListRow.reserved.rawValue:
                let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                request.predicate = NSPredicate(format: "isReserved = true AND language.code = %@", "en")
                identifier = "showSearch"
                sender = ["title": "Reserved List",
                          "request": request]
                
            case MoreListRow.artists.rawValue:
                identifier = "showArtists"
                sender = nil
                
            default:
                ()
            }
        default:
            ()
        }
        
        performSegue(withIdentifier: identifier, sender: sender)
    }
}

