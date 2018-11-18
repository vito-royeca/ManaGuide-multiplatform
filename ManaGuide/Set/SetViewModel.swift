//
//  SetViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 25.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit
import PromiseKit

enum SetContent: Int {
    case cards
    case wiki
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .cards: return "Cards"
        case .wiki: return "Wiki"
        }
    }
    
    static var count: Int {
        return 2
    }
}

class SetViewModel: BaseViewModel {
    // MARK: Variables
    var queryString = ""
    var searchCancelled = false
    var setContent: SetContent = .cards

    private var _set: CMSet?
    private var _searchViewModel: SearchViewModel?
    
    // MARK: Init
    init(withSet set: CMSet, languageCode: String) {
        super.init()
        _set = set
        
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "set.code = %@ AND language.code = %@", set.code!, languageCode)
        _searchViewModel = SearchViewModel(withRequest: request,
                                           andTitle: set.name,
                                           andMode: .loading)
    }
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        if mode == .resultsFound {
            var rows = 0
            
            switch setContent {
            case .cards:
                rows = _searchViewModel!.numberOfRows(inSection: section)
            case .wiki:
                rows = 2
            }
            
            return rows
        } else {
            return 1
        }
    }
    
    func numberOfSections() -> Int {
        if mode == .resultsFound {
            var number = 0
            
            switch setContent {
            case .cards:
                number = _searchViewModel!.numberOfSections()
            case .wiki:
                number = 1
            }
            
            return number
        } else {
            return 1
        }
    }
    
    func sectionIndexTitles() -> [String]? {
        if mode == .resultsFound {
            var titles: [String]?
            
            switch setContent {
            case .cards:
                titles = _searchViewModel!.sectionIndexTitles()
            case .wiki:
                ()
            }
            return titles

        } else {
            return nil
        }
    }
    
    func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        if mode == .resultsFound {
            var sectionIndex = 0
            
            switch setContent {
            case .cards:
                sectionIndex = _searchViewModel!.sectionForSectionIndexTitle(title: title, at: index)
            case .wiki:
                ()
            }
            return sectionIndex

        } else {
            return 0
        }
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        if mode == .resultsFound {
            var titleHeader: String?
            
            switch setContent {
            case .cards:
                titleHeader = _searchViewModel!.titleForHeaderInSection(section: section)
            case .wiki:
                ()
            }
            
            return titleHeader

        } else {
            return nil
        }
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> CMCard {
        return _searchViewModel!.object(forRowAt: indexPath)
    }
    
    func allObjects() -> [CMCard]? {
        return _searchViewModel!.allObjects()
    }
    
    func isEmpty() -> Bool {
        guard let objects = allObjects() else {
            return true
        }
        return objects.count == 0
    }

    func fetchData() -> Promise<Void> {
        return Promise { seal in
        
            _searchViewModel!.queryString = queryString
            
            firstly {
                _searchViewModel!.fetchData()
            }.done {
                self._searchViewModel!.mode = self._searchViewModel!.isEmpty() ? (self._searchViewModel!.queryString.isEmpty ? .standBy : .noResultsFound) : .resultsFound
                self.mode = self._searchViewModel!.mode
                seal.fulfill(())
                
            }.catch { error in
                self.mode = .error
                seal.reject(error)
            }
        }
    }
    
    // MARK: Presentation methods
    func getSearchTitle() -> String? {
        return _searchViewModel!.getSearchTitle()
    }
    
    func getSearchViewModel() -> SearchViewModel {
        guard let searchViewModel = _searchViewModel else {
            fatalError("")
        }
        return searchViewModel
    }

    func wikiURL() -> URL? {
        guard let set = _set else {
            return nil
        }
        
        var path = ""
        
        if let name = set.name,
            let code = set.code {
            
            if code == "LEA" {
                path = "Alpha"
            } else if code == "LEB" {
                path = "Beta"
            } else {
                path = name.replacingOccurrences(of: " and ", with: " & ")
                    .replacingOccurrences(of: " ", with: "_")
            }
        }
        
        return URL(string: "https://mtg.gamepedia.com/\(path)")
    }
}
