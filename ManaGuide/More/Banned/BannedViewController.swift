//
//  BannedViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit

class BannedViewController: SearchViewController {

    // MARK: Variables
    var bannedViewModel: BannedViewModel!
    
    // MARK: Outlets
    @IBOutlet weak var contentSegmentedControl: UISegmentedControl!

    // MARK: Actions
    @IBAction func contentAction(_ sender: UISegmentedControl) {
        bannedViewModel.bannedContent = sender.selectedSegmentIndex == 0  ? .banned : .restricted
        updateDataDisplay()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        viewModel = bannedViewModel.refreshSearchViewModel()
        super.viewDidLoad()
        
        contentSegmentedControl.setTitle(BannedContent.banned.description, forSegmentAt: 0)
        contentSegmentedControl.setTitle(BannedContent.restricted.description, forSegmentAt: 1)
    }
    
    override func updateDataDisplay() {
        viewModel = bannedViewModel.refreshSearchViewModel()
        super.updateDataDisplay()
    }
}


