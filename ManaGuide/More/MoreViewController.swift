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

enum MoreViewControllerSection: Int {
    case rules
    case lists
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .rules: return "Rules"
        case .lists: return "Lists"
        }
    }
    
    static var count: Int {
        return 2
    }
}

enum MoreViewControllerRuleRow: Int {
    case basic
    case comprehensive
    case tournament
    case ipr
    case jar
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .basic: return "Basic Rules"
        case .comprehensive: return "Comprehensive Rules"
        case .tournament: return "Tournament Rules"
        case .ipr: return "Infraction Procedure Guide"
        case .jar: return "Judging at Regular Rules Enforcement Level (REL)"
        }
    }
    
    var filePath : String? {
        var path: String?
        
        switch self {
        case .basic:
            path = "\(Bundle.main.bundlePath)/data/EN_M15_QckStrtBklt_LR_Crop.pdf"
        case .comprehensive:
            ()
        case .tournament:
            path = "\(Bundle.main.bundlePath)/data/mtg_mtr_18may18_en_0.pdf"
        case .ipr:
            path = "\(Bundle.main.bundlePath)/data/mtg_ipg_27apr18_en.pdf"
        case .jar:
            path = "\(Bundle.main.bundlePath)/data/mtg_jar_4.pdf"
        }
        
        return path
    }
    var imageIcon : UIImage {
        switch self {
        case .basic,
             .tournament,
             .ipr,
             .jar:
            return UIImage(bgIcon: .FAFilePdfO,
                           orientation: UIImageOrientation.up,
                           bgTextColor: LookAndFeel.GlobalTintColor,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FAFilePdfO,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        case .comprehensive:
            return UIImage(bgIcon: .FADatabase,
                           orientation: UIImageOrientation.up,
                           bgTextColor: LookAndFeel.GlobalTintColor,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FADatabase,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        }
    }
    
    static var count: Int {
        return 5
    }
}

enum MoreViewControllerListRow: Int {
    case bannedAndRestricted
    case reserved
    case artists
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .bannedAndRestricted: return "Banned and Restricted List"
        case .reserved: return "Reserved List"
        case .artists: return "Artists"
        }
    }
    
    var imageIcon : UIImage {
        switch self {
        case .bannedAndRestricted: return UIImage(bgIcon: .FABan,
                                                  orientation: UIImageOrientation.up,
                                                  bgTextColor: LookAndFeel.GlobalTintColor,
                                                  bgBackgroundColor: UIColor.clear,
                                                  topIcon: .FABan,
                                                  topTextColor: UIColor.clear,
                                                  bgLarge: false,
                                                  size: CGSize(width: 20, height: 20))
        case .reserved: return UIImage(bgIcon: .FAArchive,
                                       orientation: UIImageOrientation.up,
                                       bgTextColor: LookAndFeel.GlobalTintColor,
                                       bgBackgroundColor: UIColor.clear,
                                       topIcon: .FAArchive,
                                       topTextColor: UIColor.clear,
                                       bgLarge: false,
                                       size: CGSize(width: 20, height: 20))
        case .artists: return UIImage(bgIcon: .FAPaintBrush,
                                      orientation: UIImageOrientation.up,
                                      bgTextColor: LookAndFeel.GlobalTintColor,
                                      bgBackgroundColor: UIColor.clear,
                                      topIcon: .FAPaintBrush,
                                      topTextColor: UIColor.clear,
                                      bgLarge: false,
                                      size: CGSize(width: 20, height: 20))
        }
    }
    
    static var count: Int {
        return 3
    }
}

class MoreViewController: BaseViewController {
    
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
            
            dest.viewModel = SearchViewModel(withRequest: request, andTitle: dict["title"] as? String)
        }
    }

}

// MARK: UITableViewDataSource
extension MoreViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        
        switch section {
        case MoreViewControllerSection.rules.rawValue:
            rows = MoreViewControllerRuleRow.count
        case MoreViewControllerSection.lists.rawValue:
            rows = MoreViewControllerListRow.count
        default:
            ()
        }
        
        return rows
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return MoreViewControllerSection.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        var image: UIImage?
        var text: String? = nil
        
        switch indexPath.section {
        case MoreViewControllerSection.rules.rawValue:
            switch indexPath.row {
            case MoreViewControllerRuleRow.basic.rawValue:
                image = MoreViewControllerRuleRow.basic.imageIcon
                text = MoreViewControllerRuleRow.basic.description
            case MoreViewControllerRuleRow.comprehensive.rawValue:
                image = MoreViewControllerRuleRow.comprehensive.imageIcon
                text = MoreViewControllerRuleRow.comprehensive.description
            case MoreViewControllerRuleRow.tournament.rawValue:
                image = MoreViewControllerRuleRow.tournament.imageIcon
                text = MoreViewControllerRuleRow.tournament.description
            case MoreViewControllerRuleRow.ipr.rawValue:
                image = MoreViewControllerRuleRow.ipr.imageIcon
                text = MoreViewControllerRuleRow.ipr.description
            case MoreViewControllerRuleRow.jar.rawValue:
                image = MoreViewControllerRuleRow.jar.imageIcon
                text = MoreViewControllerRuleRow.jar.description
            default:
                ()
            }
        case MoreViewControllerSection.lists.rawValue:
            switch indexPath.row {
            case MoreViewControllerListRow.bannedAndRestricted.rawValue:
                image = MoreViewControllerListRow.bannedAndRestricted.imageIcon
                text = MoreViewControllerListRow.bannedAndRestricted.description
            case MoreViewControllerListRow.reserved.rawValue:
                image = MoreViewControllerListRow.reserved.imageIcon
                text = MoreViewControllerListRow.reserved.description
            case MoreViewControllerListRow.artists.rawValue:
                image = MoreViewControllerListRow.artists.imageIcon
                text = MoreViewControllerListRow.artists.description
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
        var headerTitle: String?
     
        switch section {
        case MoreViewControllerSection.rules.rawValue:
            headerTitle = MoreViewControllerSection.rules.description
        case MoreViewControllerSection.lists.rawValue:
            headerTitle = MoreViewControllerSection.lists.description
        default:
            ()
        }
        
        return headerTitle
    }
}

// MARK: UITableViewDelegate
extension MoreViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var identifier = ""
        var sender: [String: Any]?
        
        switch indexPath.section {
        case MoreViewControllerSection.rules.rawValue:
            switch indexPath.row {
            case MoreViewControllerRuleRow.basic.rawValue:
                identifier = "showPDF"
                sender = ["url": URL(fileURLWithPath: MoreViewControllerRuleRow.basic.filePath!),
                          "title": MoreViewControllerRuleRow.basic.description]
                
            case MoreViewControllerRuleRow.comprehensive.rawValue:
                identifier = "showComprehensiveRules"
                sender = nil
                
            case MoreViewControllerRuleRow.tournament.rawValue:
                identifier = "showPDF"
                sender = ["url": URL(fileURLWithPath: MoreViewControllerRuleRow.tournament.filePath!),
                          "title": MoreViewControllerRuleRow.tournament.description]
                
            case MoreViewControllerRuleRow.ipr.rawValue:
                identifier = "showPDF"
                sender = ["url": URL(fileURLWithPath: MoreViewControllerRuleRow.ipr.filePath!),
                          "title": MoreViewControllerRuleRow.ipr.description]
                
            case MoreViewControllerRuleRow.jar.rawValue:
                identifier = "showPDF"
                sender = ["url": URL(fileURLWithPath: MoreViewControllerRuleRow.jar.filePath!),
                          "title": MoreViewControllerRuleRow.jar.description]

            default:
                ()
            }
        case MoreViewControllerSection.lists.rawValue:
            switch indexPath.row {
            case MoreViewControllerListRow.bannedAndRestricted.rawValue:
                identifier = "showBannedAndRestricted"
                sender = nil
                
            case MoreViewControllerListRow.reserved.rawValue:
                let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
                request.predicate = NSPredicate(format: "reserved = true")
                identifier = "showSearch"
                sender = ["title": "Reserved List",
                          "request": request]
                
            case MoreViewControllerListRow.artists.rawValue:
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

