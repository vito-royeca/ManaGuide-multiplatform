//
//  GlossaryDetailsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 08/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit

class GlossaryDetailsViewController: UIViewController {

    // MARK: Variables
    var glossary: CMGlossary?
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.estimatedRowHeight = CGFloat(88)
    }
}

// MARK: UITableViewDataSource
extension GlossaryDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if let c = tableView.dequeueReusableCell(withIdentifier: "DetailsCell"),
            let glossary = glossary {
            
            if let definitionLabel = c.contentView.viewWithTag(100) as? UILabel {
                definitionLabel.text = glossary.definition
            }
            
            cell = c
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension GlossaryDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
