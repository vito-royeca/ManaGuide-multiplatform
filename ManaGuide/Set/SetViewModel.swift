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

class SetViewModel: BaseSearchViewModel {
    // MARK: Variables
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
        title = _searchViewModel!.title
    }
    
    // MARK: Presentation methods
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
