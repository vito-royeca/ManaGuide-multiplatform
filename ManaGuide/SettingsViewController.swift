//
//  SettingsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import InAppSettingsKit
import ManaKit

class SettingsViewController: IASKAppSettingsViewController {

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        delegate = self
        
        let slideshowEnabled = UserDefaults.standard.bool(forKey: "slideshowRandom")
        hiddenKeys = slideshowEnabled ? nil : Set(["slideshowSet"])
    }
}

// MARK: IASKSettingsDelegate
extension SettingsViewController: IASKSettingsDelegate {
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, titlesFor specifier: IASKSpecifier!) -> [Any]! {
        var array = [String]()
        
        if specifier.key() == "slideshowSet" {
            let request = CMSet.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false),
                                       NSSortDescriptor(key: "name", ascending: true)]
            
            guard let sets = try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request) as? [CMSet] else {
                return array
            }
            
            for set in sets {
                array.append(set.name!)
            }
        }
        
        return array
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, valuesFor specifier: IASKSpecifier!) -> [Any]! {
        var array = [String]()
        
        if specifier.key() == "slideshowSet" {
            let request = CMSet.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false),
                                       NSSortDescriptor(key: "name", ascending: true)]
            
            guard let sets = try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request) as? [CMSet] else {
                return array
            }
            
            for set in sets {
                array.append(set.code!)
            }
        }
        
        return array
    }
}
