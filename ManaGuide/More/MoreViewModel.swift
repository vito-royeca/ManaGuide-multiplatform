//
//  MoreViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit

enum MoreSection: Int {
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

enum MoreRuleRow: Int {
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
                           orientation: UIImage.Orientation.up,
                           bgTextColor: LookAndFeel.GlobalTintColor,
                           bgBackgroundColor: UIColor.clear,
                           topIcon: .FAFilePdfO,
                           topTextColor: UIColor.clear,
                           bgLarge: false,
                           size: CGSize(width: 20, height: 20))
        case .comprehensive:
            return UIImage(bgIcon: .FADatabase,
                           orientation: UIImage.Orientation.up,
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

enum MoreListRow: Int {
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
                                                  orientation: UIImage.Orientation.up,
                                                  bgTextColor: LookAndFeel.GlobalTintColor,
                                                  bgBackgroundColor: UIColor.clear,
                                                  topIcon: .FABan,
                                                  topTextColor: UIColor.clear,
                                                  bgLarge: false,
                                                  size: CGSize(width: 20, height: 20))
        case .reserved: return UIImage(bgIcon: .FAArchive,
                                       orientation: UIImage.Orientation.up,
                                       bgTextColor: LookAndFeel.GlobalTintColor,
                                       bgBackgroundColor: UIColor.clear,
                                       topIcon: .FAArchive,
                                       topTextColor: UIColor.clear,
                                       bgLarge: false,
                                       size: CGSize(width: 20, height: 20))
        case .artists: return UIImage(bgIcon: .FAPaintBrush,
                                      orientation: UIImage.Orientation.up,
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

class MoreViewModel: NSObject {
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        var rows = 0
        
        switch section {
        case MoreSection.rules.rawValue:
            rows = MoreRuleRow.count
        case MoreSection.lists.rawValue:
            rows = MoreListRow.count
        default:
            ()
        }
        
        return rows
    }
    
    func numberOfSections() -> Int {
        return MoreSection.count
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        var headerTitle: String?
        
        switch section {
        case MoreSection.rules.rawValue:
            headerTitle = MoreSection.rules.description
        case MoreSection.lists.rawValue:
            headerTitle = MoreSection.lists.description
        default:
            ()
        }
        
        return headerTitle
    }
}
