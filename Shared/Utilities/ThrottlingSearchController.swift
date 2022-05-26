//
//  ThrottlingSearchController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 12/07/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit

class ThrottlingSearchController: UISearchController {
    // Throttle engine
    var throttler: Throttler? = nil
    
    // Throttling interval
    public var throttlingInterval: TimeInterval? = 0 {
        didSet {
            guard let interval = throttlingInterval else {
                self.throttler = nil
                return
            }
            self.throttler = Throttler(seconds: interval)
            
        }
    }
    
    public var doSearch: ((String?) -> (Void))? = nil
    public var showSearchResults: (() -> (Void))? = nil
    
    init() {
        super.init(searchResultsController: nil)
        searchResultsUpdater = self
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        searchResultsUpdater = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        searchResultsUpdater = self
    }
}

// MARK: UISearchResultsUpdating
extension ThrottlingSearchController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let throttler = self.throttler else {
            return
        }
        
        let text = searchController.searchBar.text
        
        throttler.throttle {
//            DispatchQueue.global(qos: .background).async {
//                self.doSearch?(text)
//
//                DispatchQueue.main.async {
//                    self.showSearchResults?()
//                }
//            }
            
            DispatchQueue.main.async {
                self.doSearch?(text)
            }
        }
    }
}

