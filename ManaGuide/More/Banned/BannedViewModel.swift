//
//  BannedViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit

enum BannedContent: Int {
    case banned
    case restricted
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .banned: return "Banned"
        case .restricted: return "Restricted"
        }
    }
    
    static var count: Int {
        return 2
    }
}

class BannedViewModel: NSObject {
    // MARK: Variables
    var queryString = ""
    var bannedContent: BannedContent = .banned
    
    private var _format: CMCardFormat?
    
    // MARK: Init
    init(withFormat format: CMCardFormat) {
        super.init()

        _format = format
    }
    
    // MARK: Custom methods
    func refreshSearchViewModel() -> SearchViewModel {
        guard let format = _format,
            let formatName = format.name,
            let cardLegalities = findCardLEgalities(formantName: formatName, legalityName: bannedContent.description) else {
            fatalError("CardLegalities is nil")
        }
        
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@ AND language.code = %@", cardLegalities.map { $0.card!.id }, "en")
        
        let searchViewModel = SearchViewModel(withRequest: request,
                                              andTitle: formatName,
                                              andMode: .loading)
        searchViewModel.queryString = queryString
        
        return searchViewModel
    }
    
    private func findCardLEgalities(formantName: String, legalityName: String) -> [CMCardLegality]? {
        let request: NSFetchRequest<CMCardLegality> = CMCardLegality.fetchRequest()
        request.predicate = NSPredicate(format: "format.name = %@ AND legality.name = %@", formantName, legalityName)
        
        return try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request)
    }
}
