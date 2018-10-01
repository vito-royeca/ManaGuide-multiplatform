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
    
    private var _format: CMFormat?
    private var _searchViewModel: SearchViewModel?
    
    // MARK: Init
    init(withFormat format: CMFormat) {
        super.init()

        _format = format
        setupViewModel()
    }
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        return _searchViewModel!.numberOfRows(inSection: section)
    }
    
    func numberOfSections() -> Int {
        return _searchViewModel!.numberOfSections()
    }
    
    func sectionIndexTitles() -> [String]? {
        return _searchViewModel!.sectionIndexTitles()
    }
    
    func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        return _searchViewModel!.sectionForSectionIndexTitle(title: title, at: index)
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        return _searchViewModel!.titleForHeaderInSection(section: section)
    }
    
    // MARK: UICollectionView methods
    func collectionNumberOfRows(inSection section: Int) -> Int {
        return _searchViewModel!.collectionNumberOfRows(inSection: section)
    }
    
    func collectionNumberOfSections() -> Int {
        return _searchViewModel!.collectionNumberOfSections()
    }
    
    func collectionSectionIndexTitles() -> [String]? {
        return _searchViewModel!.sectionIndexTitles()
    }
    
    func collectionSectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        return _searchViewModel!.collectionSectionForSectionIndexTitle(title: title, at: index)
    }
    
    func collectionTitleForHeaderInSection(section: Int) -> String? {
        return _searchViewModel!.collectionTitleForHeaderInSection(section: section)
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> CMCard {
        return _searchViewModel!.object(forRowAt: indexPath)
    }
    
    func allObjects() -> [CMCard]? {
        return _searchViewModel!.allObjects()
    }
    
    func fetchData() {
        setupViewModel()
        _searchViewModel!.fetchData()
    }
    
    // MARK: Presentation methods
    func getFormatTitle() -> String? {
        guard let format = _format,
            let formatName = format.name else {
            return nil
        }
        
        return formatName
    }
    
    // MARK: Custom methods
    private func setupViewModel() {
        guard let format = _format,
            let formatName = format.name,
            let cardLegalities = findCardLEgalities(formantName: formatName, legalityName: bannedContent.description) else {
                return
        }
        
//        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
//        request.predicate = NSPredicate(format: "ANY cardLegalities.legality.name IN %@ AND format.name = %@", ["Banned"], format.name!)
//        [NSPredicate predicateWithFormat:@"(items.@count == %d) AND (SUBQUERY(items, $x, $x IN %@).@count == %d)",
//            itemSet.count, itemSet, itemSet.count];
        
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", cardLegalities.map { $0.card!.id })
        
        _searchViewModel = SearchViewModel(withRequest: request, andTitle: formatName)
        _searchViewModel!.queryString = queryString
    }
    
    private func findCardLEgalities(formantName: String, legalityName: String) -> [CMCardLegality]? {
        let request: NSFetchRequest<CMCardLegality> = CMCardLegality.fetchRequest()
        request.predicate = NSPredicate(format: "format.name = %@ AND legality.name = %@", formantName, legalityName)
        
        return try! ManaKit.sharedInstance.dataStack?.mainContext.fetch(request)
    }
}
