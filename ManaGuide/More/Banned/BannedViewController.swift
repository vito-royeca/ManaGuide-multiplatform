//
//  BannedViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class BannedViewController: SearchViewController {
    // MARK: Variables
    
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!

    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        guard let viewModel = viewModel as? BannedViewModel else {
            return
        }
        
        viewModel.content = sender.selectedSegmentIndex == 0  ? .banned : .restricted
        fetchData()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        contentSegmentedControl.setTitle(BannedContent.banned.description, forSegmentAt: 0)
        contentSegmentedControl.setTitle(BannedContent.restricted.description, forSegmentAt: 1)
        
        title = viewModel.title
    }
}
