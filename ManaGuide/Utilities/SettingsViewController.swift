//
//  SettingsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
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
        
//        if specifier.key() == "slideshowSet" {
//            let sortDescriptors = [SortDescriptor(keyPath: "releaseDate", ascending: false),
//                                   SortDescriptor(keyPath: "name", ascending: true)]
//
//            for set in ManaKit.sharedInstance.realm.objects(CMSet.self).sorted(by: sortDescriptors) {
//                array.append(set.name!)
//            }
//        }
        
        return array
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, valuesFor specifier: IASKSpecifier!) -> [Any]! {
        var array = [String]()
        
//        if specifier.key() == "slideshowSet" {
//            let sortDescriptors = [SortDescriptor(keyPath: "releaseDate", ascending: false),
//                                   SortDescriptor(keyPath: "name", ascending: true)]
//
//            for set in ManaKit.sharedInstance.realm.objects(CMSet.self).sorted(by: sortDescriptors) {
//                array.append(set.code!)
//            }
//        }
        
        return array
    }
}
