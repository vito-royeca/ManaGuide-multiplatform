//
//  BannedListViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 07/08/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import ManaKit
import PromiseKit

class BannedListViewController: BaseSearchViewController {

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        
        viewModel = BannedListViewModel()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBanned" {
            guard let dest = segue.destination as? BannedViewController,
                let dict = sender as? [String: Any],
                let format = dict["format"] as? CMCardFormat else {
                return
            }
            
            dest.viewModel = BannedViewModel(withFormat: format)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if viewModel.mode == .resultsFound {
            let c = tableView.dequeueReusableCell(withIdentifier: "BannedCell",
                                                  for: indexPath)
            
            guard let label = c.textLabel,
                let cardFormat = viewModel.object(forRowAt: indexPath) as? CMCardFormat else {
                fatalError("UILabel not found")
            }
            label.text = cardFormat.name
            cell = c
            
        } else {
            guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier) as? SearchModeTableViewCell else {
                fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
            }
            c.mode = viewModel.mode
            cell = c
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension BannedListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.mode == .resultsFound {
            return UITableView.automaticDimension
        } else {
            return tableView.frame.size.height / 3
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let format = viewModel.object(forRowAt: indexPath)
        performSegue(withIdentifier: "showBanned", sender: ["format": format])
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if viewModel.mode == .resultsFound {
            return indexPath
        } else {
            return nil
        }
    }
}

