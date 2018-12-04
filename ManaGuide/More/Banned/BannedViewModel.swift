//
//  BannedViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit
import PromiseKit

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

class BannedViewModel: SearchViewModel {
    // MARK: Variables
    var content: BannedContent = .banned
    private var _format: CMCardFormat?
    
    // MARK: Init
    init(withFormat format: CMCardFormat) {
        super.init(withTitle: format.name,
                   andMode: .loading)
        _format = format

//        guard let format = _format,
//            let formatName = format.name,
//            let cardLegalities = findCardLegalities(formantName: formatName, legalityName: content.description) else {
//            fatalError("CardLegalities is nil")
//        }
//
//        let newRequest: NSFetchRequest<CMCard> = CMCard.fetchRequest()
//        newRequest.predicate = NSPredicate(format: "id IN %@ AND language.code = %@", cardLegalities.map { $0.card!.id }, "en")
//        request = newRequest as? NSFetchRequest<NSManagedObject>
    }
    
    // MARK: Overrides
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            guard let format = _format,
                let formatName = format.name,
                let cardLegalities = findCardLegalities(formantName: formatName, legalityName: content.description) else {
                fatalError("CardLegalities is nil")
            }

            let newRequest: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            newRequest.predicate = NSPredicate(format: "id IN %@ AND language.code = %@", cardLegalities.map { $0.card!.id }, "en")
            fetchedResultsController = getFetchedResultsController(with: newRequest as? NSFetchRequest<NSManagedObject>)
            updateSections()
            seal.fulfill(())
        }
    }
    
    // MARK: Custom methods
    private func findCardLegalities(formantName: String, legalityName: String) -> [CMCardLegality]? {
        let request: NSFetchRequest<CMCardLegality> = CMCardLegality.fetchRequest()
        request.predicate = NSPredicate(format: "format.name = %@ AND legality.name = %@", formantName, legalityName)
        
        return try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request)
    }
}
