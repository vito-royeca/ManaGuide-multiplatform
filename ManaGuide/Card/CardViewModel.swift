//
//  CardViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 08.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import Firebase
import ManaKit

enum CardContent: Int {
    case image
    case details
    case store
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .image: return "Image"
        case .details: return "Details"
        case .store: return "Store"
        }
    }
    
    static var count: Int {
        return 3
    }
}

enum CardImageSection : Int {
    case pricing
    case image
    case actions
    
    static var count: Int {
        return 3
    }
}

enum CardDetailsSection : Int {
    case manaCost
    case type
    case oracleText
    case originalText
    case flavorText
    case artist
    case set
    case otherNames
    case otherPrintings
    case variations
    case rulings
    case legalities
    case otherDetails
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .manaCost: return "Mana Cost"
        case .type: return "Type"
        case .oracleText: return "Text"
        case .originalText: return "Original Text"
        case .flavorText: return "Flavor Text"
        case .artist: return "Artist"
        case .set: return "Set"
        case .otherNames: return "Other Names"
        case .otherPrintings: return "Other Printings"
        case .variations: return "Variations"
        case .rulings: return "Rulings"
        case .legalities: return "Legalities"
        case .otherDetails: return "Other Details"
        }
    }
    
    static var count: Int {
        return 13
    }
}

class CardViewModel: NSObject {
    // MARK: Variables
    var cardIndex = 0
    var content: CardContent = .image
    
    private var _fetchedResultsController: NSFetchedResultsController<CMCard>?
    private var _otherPrintingsFRC: NSFetchedResultsController<CMCard>?
    private var _variationsFRC: NSFetchedResultsController<CMCard>?
    private var _sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),
                                    NSSortDescriptor(key: "set.releaseDate", ascending: true),
                                    NSSortDescriptor(key: "number", ascending: true),
                                    NSSortDescriptor(key: "mciNumber", ascending: true)]

    init(withCardIndex cardIndex: Int, withCardIDs cardIDs: [String], withSortDescriptors sortDescriptors: [NSSortDescriptor]?) {
        super.init()
        
        self.cardIndex = cardIndex
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", cardIDs)
        request.sortDescriptors = sortDescriptors ?? _sortDescriptors
        _fetchedResultsController = getFetchedResultsController(with: request)
    }
    
    // MARK: UITableView methods
    func numberOfRows(inSection section: Int) -> Int {
        let card = object(forRowAt: IndexPath(row: cardIndex, section: 0))
        var rows = 0
        
        switch content {
        case .image:
            rows = 1
            
        case .details:
            switch section {
            case CardDetailsSection.otherNames.rawValue:
                if let names_ = card.names_ {
                    if let array = names_.allObjects as? [CMCard] {
                        rows = array.filter({ $0.name != card.name}).count
                    }
                }
                if rows == 0 {
                    rows = 1
                }
            case CardDetailsSection.rulings.rawValue:
                if let rulings_ = card.rulings_ {
                    rows = rulings_.allObjects.count >= 1 ? rulings_.allObjects.count : 1
                }
            case CardDetailsSection.legalities.rawValue:
                if let cardLegalities_ = card.cardLegalities_ {
                    rows = cardLegalities_.allObjects.count >= 1 ? cardLegalities_.allObjects.count : 1
                }
            default:
                rows = 1
            }
            
        case .store:
            guard let suppliers = card.suppliers else {
                return rows
            }
            rows = suppliers.count + 1
        }
        
        return rows
    }
    
    func numberOfCards() -> Int {
        guard let fetchedResultsController = _fetchedResultsController,
            let fetchedObjects = fetchedResultsController.fetchedObjects else {
            return 0
        }
        
        return fetchedObjects.count
    }
    
    func numberOfOtherPrintings() -> Int {
        guard let otherPrintingsFRC = _otherPrintingsFRC,
            let fetchedObjects = otherPrintingsFRC.fetchedObjects else {
            return 0
        }
        
        return fetchedObjects.count
    }
    
    func numberOfVariations() -> Int {
        guard let variationsFRC = _variationsFRC,
            let fetchedObjects = variationsFRC.fetchedObjects else {
            return 0
        }
        
        return fetchedObjects.count
    }
    
    func numberOfSections() -> Int {
        var sections = 0
        
        switch content {
        case .image:
            sections = CardImageSection.count
        case .details:
            sections = CardDetailsSection.count
        case .store:
            sections = 1
        }
        
        return sections
    }
    
    func titleForHeaderInSection(section: Int) -> String? {
        let card = object(forRowAt: IndexPath(row: cardIndex, section: 0))
        var headerTitle: String?
        
        switch content {
        case .details:
            switch section {
            case CardDetailsSection.manaCost.rawValue:
                headerTitle = CardDetailsSection.manaCost.description
            case CardDetailsSection.type.rawValue:
                headerTitle = CardDetailsSection.type.description
            case CardDetailsSection.oracleText.rawValue:
                headerTitle = CardDetailsSection.oracleText.description
            case CardDetailsSection.originalText.rawValue:
                headerTitle = CardDetailsSection.originalText.description
            case CardDetailsSection.flavorText.rawValue:
                headerTitle = CardDetailsSection.flavorText.description
            case CardDetailsSection.artist.rawValue:
                headerTitle = CardDetailsSection.artist.description
            case CardDetailsSection.set.rawValue:
                headerTitle = CardDetailsSection.set.description
            case CardDetailsSection.otherNames.rawValue:
                headerTitle = CardDetailsSection.otherNames.description
                var count = 0
                
                if let names_ = card.names_ {
                    if let array = names_.allObjects as? [CMCard] {
                        count = array.filter({ $0.name != card.name}).count
                        
                    }
                }
                headerTitle?.append(": \(count)")
            case CardDetailsSection.otherPrintings.rawValue:
                headerTitle = CardDetailsSection.otherPrintings.description
                var count = 0
                
                if let otherPrintingsFRC = _otherPrintingsFRC,
                    let fetchedObjects = otherPrintingsFRC.fetchedObjects {
                    count = fetchedObjects.count
                }
                headerTitle?.append(": \(count)")
            case CardDetailsSection.variations.rawValue:
                headerTitle = CardDetailsSection.variations.description
                var count = 0
                
                if let variationsFRC = _variationsFRC,
                    let fetchedObjects = variationsFRC.fetchedObjects {
                    count = fetchedObjects.count
                }
                headerTitle?.append(": \(count)")
            case CardDetailsSection.rulings.rawValue:
                headerTitle = CardDetailsSection.rulings.description
                var count = 0
                
                if let rulings_ = card.rulings_ {
                    count = rulings_.count
                }
                headerTitle?.append(": \(count)")
            case CardDetailsSection.legalities.rawValue:
                headerTitle = CardDetailsSection.legalities.description
                var count = 0
                
                if let cardLegalities_ = card.cardLegalities_ {
                    count = cardLegalities_.count
                }
                headerTitle?.append(": \(count)")
            case CardDetailsSection.otherDetails.rawValue:
                headerTitle = CardDetailsSection.otherDetails.description
            default:
                ()
            }
        default:
            ()
        }
        
        return headerTitle
    }
    
    // MARK: Custom methods
    func object(forRowAt indexPath: IndexPath) -> CMCard {
        guard let fetchedResultsController = _fetchedResultsController else {
            fatalError("fetchedResultsController is nil")
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    func otherPrinting(forRowAt indexPath: IndexPath) -> CMCard {
        guard let otherPrintingsFRC = _otherPrintingsFRC else {
            fatalError("otherPrintingsFRC is nil")
        }
        return otherPrintingsFRC.object(at: indexPath)
    }
    
    func variation(forRowAt indexPath: IndexPath) -> CMCard {
        guard let variationsFRC = _variationsFRC else {
            fatalError("variationsFRC is nil")
        }
        return variationsFRC.object(at: indexPath)
    }
    
    func fetchExtraData() {
        let card = object(forRowAt: IndexPath(row: cardIndex, section: 0))
        if let printings_ = card.printings_ {
            let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            let sets = printings_.allObjects as! [CMSet]
            var filteredSets = [CMSet]()
            
            if let set = card.set {
                filteredSets = sets.filter({ $0.code != set.code})
            }
            
            request.predicate = NSPredicate(format: "name = %@ AND set.code IN %@", card.name!, filteredSets.map({$0.code}))
            request.sortDescriptors = _sortDescriptors
            _otherPrintingsFRC = getFetchedResultsController(with: request)
        }
        
        if let variations_ = card.variations_,
            let variations = variations_.allObjects as? [CMCard] {
            
            let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", variations.map({$0.id}))
            request.sortDescriptors = _sortDescriptors
            _variationsFRC = getFetchedResultsController(with: request)
        }
    }
    
    func toggleCardFavorite(firstAttempt: Bool) {
        let card = object(forRowAt: IndexPath(row: cardIndex, section: 0))
        
        guard let fbUser = Auth.auth().currentUser,
            let user = ManaKit.sharedInstance.findObject("CMUser",
                                                         objectFinder: ["id": fbUser.uid as AnyObject],
                                                         createIfNotFound: false) as? CMUser,
            let id = card.id else {
            return
        }
        
        let userRef = Database.database().reference().child("users").child(fbUser.uid)
        let favorite = !isCurrentCardFavorite()
        
        userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : Any] {
                var dict: [String: Any]?
                
                if let d = post["favorites"] as? [String : Any] {
                    dict = d
                } else {
                    dict = [String: Any]()
                }
                
                if favorite {
                    dict![id] = true
                } else {
                    dict![id] = nil
                }
                
                post["favorites"] = dict
                
                // Set value and report transaction success
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
                
            } else {
                if firstAttempt {
                    return TransactionResult.abort()
                } else {
                    userRef.setValue(["favorites": [id: favorite ? true : nil]])
                    return TransactionResult.success(withValue: currentData)
                }
            }
            
        }) { (error, committed, snapshot) in
            if committed {
                if favorite {
                    user.addToFavorites(card)
                } else {
                    user.removeFromFavorites(card)
                }
                
                ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                    try! backgroundContext.save()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                    object: nil,
                                                    userInfo: nil)
                }
            } else {
                // retry again, if we were aborted from above
                self.toggleCardFavorite(firstAttempt: false)
            }
        }
        
    }
    
    func incrementCardViews(firstAttempt: Bool) {
        let card = object(forRowAt: IndexPath(row: cardIndex, section: 0))
        let ref = Database.database().reference().child("cards").child(card.id!)
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : Any] {
                var views = post[FCCard.Keys.Views] as? Int ?? 0
                views += 1
                post[FCCard.Keys.Views] = views
                
                // Set value and report transaction success
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
                
            } else {
                if firstAttempt {
                    return TransactionResult.abort()
                } else {
                    ref.setValue([FCCard.Keys.Views: 1])
                    return TransactionResult.success(withValue: currentData)
                }
            }
            
        }) { (error, committed, snapshot) in
            if committed {
                guard let snapshot = snapshot else {
                    return
                }
                let fcard = FCCard(snapshot: snapshot)
                
                card.views = Int64(fcard.views == nil ? 1 : fcard.views!)
                
                ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                    try! backgroundContext.save()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                                    object: nil,
                                                    userInfo: ["card": card])
                }
                
            } else {
                // retry again, if we were aborted from above
                self.incrementCardViews(firstAttempt: false)
            }
        }
    }

    func isCurrentCardFavorite() -> Bool {
        let card = object(forRowAt: IndexPath(row: cardIndex, section: 0))
        
        guard let fbUser = Auth.auth().currentUser,
            let user = ManaKit.sharedInstance.findObject("CMUser",
                                                         objectFinder: ["id": fbUser.uid as AnyObject],
                                                         createIfNotFound: false) as? CMUser,
            let favorites = user.favorites,
            let array = favorites.allObjects as? [CMCard] else {
            return false
        }
        
        for c in array {
            if c.id == card.id {
                return true
            }
        }
        return false
    }
    
    private func getFetchedResultsController(with fetchRequest: NSFetchRequest<CMCard>?) -> NSFetchedResultsController<CMCard> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMCard>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest
        } else {
            // Create a default fetchRequest
            request = CMCard.fetchRequest()
            request!.sortDescriptors = _sortDescriptors
        }
        
        // Create Fetched Results Controller
        let frc = NSFetchedResultsController(fetchRequest: request!,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        
        // Configure Fetched Results Controller
        frc.delegate = self
        
        // perform fetch
        do {
            try frc.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        return frc
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension CardViewModel : NSFetchedResultsControllerDelegate {
    
}

