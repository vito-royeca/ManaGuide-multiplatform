//
//  ArtistsViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 19/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import ManaKit
import PromiseKit

class ArtistsViewController: BaseSearchViewController {
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.register(UINib(nibName: "SearchModeTableViewCell",
                                 bundle: nil),
                           forCellReuseIdentifier: SearchModeTableViewCell.reuseIdentifier)
        
        viewModel = ArtistsViewModel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearch" {
            guard let dest = segue.destination as? SearchViewController,
                let dict = sender as? [String: Any],
                let request = dict["request"] as? NSFetchRequest<CMCard> else {
                return
            }
            
            dest.viewModel = SearchViewModel(withRequest: request,
                                             andTitle: dict["title"] as? String,
                                             andMode: .loading)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        
        if viewModel.mode == .resultsFound {
            let c = tableView.dequeueReusableCell(withIdentifier: "ArtistCell",
                                                  for: indexPath)
            // Configure Cell
            guard let label = c.textLabel,
                let artist = viewModel.object(forRowAt: indexPath) as? CMCardArtist else {
                    fatalError("UILabel not found")
            }
            label.text = artist.name
            cell = c
            
        } else {
            guard let c = tableView.dequeueReusableCell(withIdentifier: SearchModeTableViewCell.reuseIdentifier) as? SearchModeTableViewCell else {
                fatalError("\(SearchModeTableViewCell.reuseIdentifier) is nil")
            }
            cell = c
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate
extension ArtistsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.mode == .resultsFound {
            return UITableView.automaticDimension
        } else {
            return tableView.frame.size.height / 3
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let artist = viewModel.object(forRowAt: indexPath) as? CMCardArtist else {
            return
        }
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "artist.name = %@ AND language.code = %@", artist.name!, "en")
        
        performSegue(withIdentifier: "showSearch", sender: ["request": request,
                                                            "title": artist.name!])
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if viewModel.isEmpty() {
            return nil
        } else {
            return indexPath
        }
    }
}
