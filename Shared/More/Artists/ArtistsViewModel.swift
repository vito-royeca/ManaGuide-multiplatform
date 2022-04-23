//
//  ArtistsViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 30.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import ManaKit
import PromiseKit

class ArtistsViewModel: BaseSearchViewModel {
    private var _sectionIndexTitles: [String]?
    private var _sectionTitles: [String]?

    override init() {
        super.init()

        sectionName = "nameSection"
        sortDescriptors = [NSSortDescriptor(key: "nameSection", ascending: true),
                           NSSortDescriptor(key: "lastName", ascending: true),
                           NSSortDescriptor(key: "firstName", ascending: true)]
    }
    
    // MARK: Custom methods
    override func fetchData() -> Promise<Void> {
        return Promise { seal in
            let request: NSFetchRequest<CMCardArtist> = CMCardArtist.fetchRequest()
            let count = queryString.count
            
            if count > 0 {
                if count == 1 {
                    request.predicate = NSPredicate(format: "lastName BEGINSWITH[cd] %@ OR firstName BEGINSWITH[cd] %@", queryString, queryString)
                } else {
                    request.predicate = NSPredicate(format: "lastName CONTAINS[cd] %@ OR firstName CONTAINS[cd] %@", queryString, queryString)
                }
            }
            request.sortDescriptors = sortDescriptors

            fetchedResultsController = getFetchedResultsController(with: request as? NSFetchRequest<NSManagedObject>)
            updateSections()
            seal.fulfill(())
        }
    }
    
    // MARK: Private methods
    
    
    override func updateSections() {
        guard let fetchedResultsController = fetchedResultsController,
            let artists = fetchedResultsController.fetchedObjects as? [CMCardArtist],
            let sections = fetchedResultsController.sections else {
                return
        }
        let letters = CharacterSet.letters
        
        _sectionIndexTitles = [String]()
        _sectionTitles = [String]()
        
        for artist in artists {
            let names = artist.name!.components(separatedBy: " ")
            
            if let lastName = names.last {
                var prefix = String(lastName.prefix(1))
                if prefix.rangeOfCharacter(from: letters) == nil {
                    prefix = "#"
                }
                prefix = prefix.uppercased().folding(options: .diacriticInsensitive, locale: .current)
                
                if !_sectionIndexTitles!.contains(prefix) {
                    _sectionIndexTitles!.append(prefix)
                }
            }
        }
        
        let count = sections.count
        if count > 0 {
            for i in 0...count - 1 {
                if let sectionTitle = sections[i].indexTitle {
                    _sectionTitles!.append(sectionTitle)
                }
            }
        }
        
        _sectionIndexTitles!.sort()
        _sectionTitles!.sort()
    }
}
