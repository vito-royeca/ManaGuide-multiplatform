//
//  SetsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import FontAwesome_swift
import InAppSettingsKit
import ManaKit
import PromiseKit

class SetsViewController: BaseSearchViewController {

    // MARK: Outlets
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!

    // MARK: actions
    @IBAction func rightMenuAction(_ sender: UIBarButtonItem) {
        showSettingsMenu(file: "Sets")
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                                  object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateDataDisplay(_:)),
                                               name: NSNotification.Name(rawValue: kIASKAppSettingChanged),
                                               object: nil)
        
        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        tableView.register(ManaKit.sharedInstance.nibFromBundle("SetTableViewCell"),
                           forCellReuseIdentifier: SetTableViewCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
        
        rightMenuButton.image = UIImage.fontAwesomeIcon(name: .slidersH,
                                                        style: .solid,
                                                        textColor: LookAndFeel.GlobalTintColor,
                                                        size: CGSize(width: 30, height: 30))
        rightMenuButton.title = nil
        title = "Sets"
        
        viewModel = SetsViewModel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSet" {
            guard let dest = segue.destination as? SetViewController,
            let dict = sender as? [String: Any],
            let set = dict["set"] as? CMSet,
            let languageCode = dict["languageCode"] as? String else {
                return
            }
            
            dest.viewModel = SetViewModel(withSet: set,
                                          languageCode: languageCode)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    override  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if viewModel.mode == .resultsFound {
            guard let c = tableView.dequeueReusableCell(withIdentifier: SetTableViewCell.reuseIdentifier,
                                                        for: indexPath) as? SetTableViewCell else {
                fatalError("Unexpected indexPath: \(indexPath)")
            }
            
            c.set = viewModel.object(forRowAt: indexPath) as? CMSet
            c.delegate = self
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
    
    // MARK: Custom methods
    @objc func updateDataDisplay(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
            let viewModel = viewModel as? SetsViewModel else {
            return
        }
        
        viewModel.updateSorting(with: userInfo)
        fetchData()
    }
}

// MARK: UITableViewDelegate
extension SetsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.mode == .resultsFound {
            return SetTableViewCell.cellHeight
        } else {
            return tableView.frame.size.height / 3
        }
    }
}

// MARK: SetsTableViewCellDelegate
extension SetsViewController: SetTableViewCellDelegate {
    func languageAction(cell: UITableViewCell, code: String) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let set = viewModel.object(forRowAt: indexPath)
        let sender = ["set": set,
                      "languageCode": code] as [String : Any]
        performSegue(withIdentifier: "showSet", sender: sender)
    }
}
