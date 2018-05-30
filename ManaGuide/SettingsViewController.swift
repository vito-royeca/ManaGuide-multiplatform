//
//  SettingsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import InAppSettingsKit

class SettingsViewController: IASKAppSettingsViewController {

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let backButton = navigationItem.backBarButtonItem {
            backButton.title = " "
            backButton.tintColor = UIColor(red:0.41, green:0.12, blue:0.00, alpha:1.0) // maroon
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.tintColor = UIColor(red:0.41, green:0.12, blue:0.00, alpha:1.0) // maroon
        
        for v in cell.contentView.subviews {
            if let uiswitch = v as? UISwitch {
                uiswitch.onTintColor = UIColor(red:0.41, green:0.12, blue:0.00, alpha:1.0) // maroon
            }
        }
        return cell
    }
}
