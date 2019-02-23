//
//  SetViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 25.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import ManaKit
import PromiseKit
import RealmSwift

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

class SetViewModel: SearchViewModel {
    // MARK: Variables
    var content: SetContent = .cards

    private var _set: CMSet?
    
    // MARK: Init
    init(withSet set: CMSet, languageCode: String) {
        super.init(withPredicate: NSPredicate(format: "set.code = %@ AND language.code = %@",
                                              set.code!, languageCode),
                   andSortDescriptors: nil,
                   andTitle: set.name,
                   andMode: .loading)
        _set = set
    }
    
    // MARK: Overrides
    override func numberOfRows(inSection section: Int) -> Int {
        var rows = 2
        
        switch content {
        case .cards:
            rows = super.numberOfRows(inSection: section)
        case .wiki:
            rows = 2
        }
        
        return rows
    }
    
    override func sectionIndexTitles() -> [String]? {
        if content == .cards {
            return super.sectionIndexTitles()
        } else {
            return nil
        }
    }
    
    override func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        if content == .cards {
            return super.sectionForSectionIndexTitle(title: title, at: index)
        } else {
            return 0
        }
    }
    
    // MARK: Presentation methods
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
