//
//  SetViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 25.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import SwiftUI
import ManaKit

class SetViewModel: NSObject, ObservableObject {

    // MARK: - Published Variables
    @Published private(set) var set: MGSet?
    @Published private(set) var cards = [MGCard]()
    @Published private(set) var isBusy = false
    
    // MARK: - Variables
    var setCode: String
    var languageCode: String
    var dataAPI: API
    private var frc: NSFetchedResultsController<MGCard>
    
    // MARK: - Initializers
    init(setCode: String, languageCode: String, dataAPI: API = ManaKit.shared) {
        self.setCode = setCode
        self.languageCode = languageCode
        self.dataAPI = dataAPI
        
        frc = NSFetchedResultsController(fetchRequest: SetViewModel.defaultFetchRequest(setCode: setCode, languageCode: languageCode),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        
        super.init()
        frc.delegate = self
        print("SetViewModel init... \(setCode)")
    }
    
    // MARK: - Methods
    func fetchData() {
        guard !isBusy && set == nil && cards.isEmpty else {
            return
        }
        
        isBusy.toggle()

        dataAPI.fetchSet(code: setCode,
                         languageCode: languageCode,
                         completion: { result in
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .success(let set):
                    self.set = set
                    self.fetchLocalData()
                case .failure(let error):
                    print(error)
                    self.set = nil
                    self.cards.removeAll()
                }
                
                self.isBusy.toggle()
//            }
        })
    }
    
    func fetchLocalData() {
        guard let set = set else {
            return
        }
        
        do {
            try frc.performFetch()
            cards = frc.fetchedObjects ?? []
            print("fetchLocalData... \(set.code): \(cards.count)")
        } catch {
            print(error)
            cards.removeAll()
        }
    }
    
    func clearData() {
//        set = nil
        cards.removeAll()
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension SetViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let cards = controller.fetchedObjects as? [MGCard] else {
            return
        }
        
        self.cards = cards
    }
}

// MARK: - NSFetchRequest
extension SetViewModel {
    static func defaultFetchRequest(setCode: String, languageCode: String) -> NSFetchRequest<MGCard> {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),
                               NSSortDescriptor(key: "collectorNumber", ascending: true)]
        let predicate = NSPredicate(format: "set.code == %@ AND language.code == %@ AND collectorNumber != null ", setCode, languageCode)
        
        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        return request
    }
}

// MARK: - Legacy Code

//var content: SetContent = .cards

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

extension SetViewModel {
    func wikiURL() -> URL? {
        guard let set = set else {
            return nil
        }
        
        var path = ""
        
        if let name = set.name {
            if set.code == "LEA" {
                path = "Alpha"
            } else if set.code == "LEB" {
                path = "Beta"
            } else {
                path = name.replacingOccurrences(of: " and ", with: " & ")
                    .replacingOccurrences(of: " ", with: "_")
            }
        }
        
        return URL(string: "https://mtg.gamepedia.com/\(path)")
    }
}
