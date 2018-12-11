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
    case card
    case details
    case store
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .card: return "Card"
        case .details: return "Details"
        case .store: return "Store Pricing"
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
    case mainData
    case set
    case artist
    case parts
    case variations
    case otherPrintings
    case rulings
    case legalities
    case otherDetails
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .mainData: return "Main Data"
        case .set: return "Set"
        case .artist: return "Artist"
        case .parts: return "Faces, Tokens, & Other Parts"
        case .variations: return "Variations"
        case .otherPrintings: return "Other Printings"
        case .rulings: return "Rulings"
        case .legalities: return "Legalities"
        case .otherDetails: return "Other Details"
        }
    }
    
    static var count: Int {
        return 9
    }
}

enum CardDetailsMainDataSection : Int {
    case name
    case type
    case text
    case powerToughness

    static var count: Int {
        return 4
    }
}

enum CardOtherDetailsSection : Int {
    case border
    case colorIdentity
    case colors
    case colorshifted
    case convertedManaCost
    case frameEffect
    case layout
    case releaseDate
    case reservedList
    case setOnlineOnly
    case storySpotlight
    case timeshifted
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .border: return "Border"
        case .colorIdentity: return "Color Identity"
        case .colors: return "Colors"
        case .colorshifted: return "Colorshifted"
        case .convertedManaCost: return "Converted Mana Cost"
        case .frameEffect: return "Frame Effect"
        case .layout: return "Layout"
        case .releaseDate: return "Release Date"
        case .reservedList: return "Reserved List"
        case .setOnlineOnly: return "Set Online Only"
        case .storySpotlight: return "Story Spotlight"
        case .timeshifted: return "Timeshifted"
        }
    }
    
    static var count: Int {
        return 12
    }
}

class CardViewModel: BaseSearchViewModel {
    // MARK: Variables
    var cardIndex = 0
    var cardViewIncremented = false
    var content: CardContent = .card
    var faceOrder = 0
    var flipAngle = CGFloat(0)

    var partsViewModel: SearchViewModel?
    var variationsViewModel: SearchViewModel?
    var otherPrintingsViewModel: SearchViewModel?
    
    init(withCardIndex cardIndex: Int,
         withCardIDs cardIDs: [String],
         withSortDescriptors sd: [NSSortDescriptor]?) {
        super.init()
        
        self.cardIndex = cardIndex
        self.sortDescriptors = sd
        
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@",
                                        cardIDs)
        request.sortDescriptors = sortDescriptors
        fetchedResultsController = getFetchedResultsController(with: request as? NSFetchRequest<NSManagedObject>)
        reloadRelatedCards()
    }
    
    // MARK: UITableView methods
    override func numberOfRows(inSection section: Int) -> Int {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var rows = 0
        
        switch content {
        case .card:
            rows = 1
            
        case .details:
            switch section {
            case CardDetailsSection.mainData.rawValue:
                rows = cardMainDetails().count

            case CardDetailsSection.rulings.rawValue:
                if let rulingsSet = card.cardRulings,
                    let rulings = rulingsSet.allObjects as? [CMCardRuling] {
                    rows = rulings.count >= 1 ? rulings.count : 1
                }
            case CardDetailsSection.legalities.rawValue:
                if let cardLegalitiesSet = card.cardLegalities,
                    let cardLegalities = cardLegalitiesSet.allObjects as? [CMCardLegality] {
                    rows = cardLegalities.count >= 1 ? cardLegalities.count : 1
                }
            case CardDetailsSection.otherDetails.rawValue:
                rows = CardOtherDetailsSection.count
            default:
                rows = 1
            }
            
        case .store:
            guard let storePricing = card.tcgplayerStorePricing,
                let suppliersSet = storePricing.suppliers,
                let suppliers = suppliersSet.allObjects as? [CMStoreSupplier] else {
                return rows
            }
            rows = suppliers.count + 1
        }
        
        return rows
    }
    
    func numberOfCards() -> Int {
        guard let fetchedResultsController = fetchedResultsController,
            let fetchedObjects = fetchedResultsController.fetchedObjects else {
            return 0
        }
        
        return fetchedObjects.count
    }

    func numberOfParts() -> Int {
        var count = 0
        
        if let model = partsViewModel,
            let allObjects = model.allObjects() {
            count = allObjects.count
        }
        return count
    }
    
    func numberOfVariations() -> Int {
        var count = 0
        
        if let model = variationsViewModel,
            let allObjects = model.allObjects() {
            count = allObjects.count
        }
        return count
    }
    
    func numberOfOtherPrintings() -> Int {
        var count = 0
        
        if let model = otherPrintingsViewModel,
            let allObjects = model.allObjects() {
            count = allObjects.count
        }
        return count
    }
    
    func numberOfRulings() -> Int {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var count = 0
        
        if let rulingsSet = card.cardRulings,
            let rulings = rulingsSet.allObjects as? [CMCardRuling] {
            count = rulings.count
        }
        return count
    }
    
    func numberOfLegalities() -> Int {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var count = 0
        
        if let cardLegalities = card.cardLegalities {
            count = cardLegalities.count
        }
        return count
    }
    
    override func numberOfSections() -> Int {
        var sections = 0
        
        switch content {
        case .card:
            sections = CardImageSection.count
        case .details:
            sections = CardDetailsSection.count
        case .store:
            sections = 1
        }
        
        return sections
    }
    
    override func titleForHeaderInSection(section: Int) -> String? {
        var headerTitle: String?
        
        switch content {
        case .details:
            switch section {
            case CardDetailsSection.set.rawValue:
                headerTitle = CardDetailsSection.set.description
            case CardDetailsSection.artist.rawValue:
                headerTitle = CardDetailsSection.artist.description
            case CardDetailsSection.parts.rawValue:
                headerTitle = CardDetailsSection.parts.description
                let count = numberOfParts()
                if count > 0 {
                    headerTitle?.append(": \(count)")
                }
            case CardDetailsSection.variations.rawValue:
                headerTitle = CardDetailsSection.variations.description
                let count = numberOfVariations()
                if count > 0 {
                    headerTitle?.append(": \(count)")
                }
            case CardDetailsSection.otherPrintings.rawValue:
                headerTitle = CardDetailsSection.otherPrintings.description
                let count = numberOfOtherPrintings()
                if count > 0 {
                    headerTitle?.append(": \(count)")
                }
            case CardDetailsSection.rulings.rawValue:
                headerTitle = CardDetailsSection.rulings.description
                let count = numberOfRulings()
                if count > 0 {
                    headerTitle?.append(": \(count)")
                }
            case CardDetailsSection.legalities.rawValue:
                headerTitle = CardDetailsSection.legalities.description
                let count = numberOfLegalities()
                if count > 0 {
                    headerTitle?.append(": \(count)")
                }
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
    func cardMainDetails() -> [[CardDetailsMainDataSection: CMCard]] {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var details = [[CardDetailsMainDataSection: CMCard]]()
        var array = [CMCard]()
        var faceIndex = 0

        if let facesSet = card.faces,
            let faces = facesSet.allObjects as? [CMCard] {
            if faces.count > 0 {
                let orderedFaces = faces.sorted(by: {(a, b) -> Bool in
                    return a.faceOrder < b.faceOrder
                })
                array.append(contentsOf: orderedFaces)
            } else {
                array.append(card)
            }
        }
        
        for a in array {
            // name
            details.append([CardDetailsMainDataSection.name: a])
            
            // typeline
            details.append([CardDetailsMainDataSection.type: a])
            
            // text
            if text(ofCard: a, pointSize: 17).string.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                details.append([CardDetailsMainDataSection.text: a])
            }
            
            // power / toughness
            if let type = card.typeLine,
                let name = type.name {
                if name.contains("Creature") {
                    if let _ = a.power,
                        let _ = a.toughness {
                        details.append([CardDetailsMainDataSection.powerToughness: a])
                    }
                } else if name.contains("Plainswalker") {
                    if let _ = a.loyalty {
                        details.append([CardDetailsMainDataSection.powerToughness: a])
                    }
                }
            }
            
            faceIndex += 1
        }
        
        return details
    }
    
    func rulingText(inRow row: Int, pointSize: CGFloat) -> NSAttributedString? {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard,
            let rulingsSet = card.cardRulings ,
            let rulings = rulingsSet.allObjects as? [CMCardRuling] else {
            return nil
        }
        
        let sortedRulings = rulings.sorted(by: {(first: Any, second: Any) -> Bool in
            if let a = first as? CMCardRuling,
                let b = second as? CMCardRuling,
                let aRuling = a.ruling,
                let bRuling = b.ruling,
                let aDate = aRuling.date,
                let bDate = bRuling.date {
                    return aDate > bDate
            }
            
            return false
        })
        
        if sortedRulings.count > 0 {
            let cardRuling = sortedRulings[row]
            var contents = ""
            
            if let ruling = cardRuling.ruling,
                let date = ruling.date,
                let text = ruling.text {
                contents.append(date)
                contents.append("\n\n")
                contents.append(text)
            }
            return NSAttributedString(symbol: contents,
                                      pointSize: pointSize)
        } else {
            return nil
        }
    }

    func text(ofCard card: CMCard, pointSize: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()

        if let language = card.language,
            let code = language.code {
         
            if code == "en" {
                if let oracleText = card.oracleText,
                    !oracleText.isEmpty {
                    attributedString.append(NSAttributedString(symbol: "\n\(oracleText)\n",
                                                               pointSize: pointSize))
                }
            } else {
                if let oracleText = card.printedText,
                    !oracleText.isEmpty {
                    attributedString.append(NSAttributedString(symbol: "\n\(oracleText)\n",
                                                               pointSize: pointSize))
                }
            
                // default to en oracleText
                if attributedString.string.isEmpty {
                    if let oracleText = card.oracleText,
                        !oracleText.isEmpty {
                        attributedString.append(NSAttributedString(symbol: "\n\(oracleText)\n",
                            pointSize: pointSize))
                    }
                }
            }
            
            
            if let flavorText = card.flavorText {
                let attributes = [NSAttributedString.Key.font: UIFont(name: "TimesNewRomanPS-ItalicMT", size: pointSize)]
                attributedString.append(NSAttributedString(string: "\n\(flavorText)\n",
                    attributes: attributes as [NSAttributedString.Key : Any]))
            }
        }
        return attributedString
    }
    
    func textOf(otherDetails: CardOtherDetailsSection) -> String {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var text = "\u{2014}"
        
        switch otherDetails {
        case .border:
            if let border = card.borderColor,
                let name = border.name {
                text = name
            }
        case .colorIdentity:
            if let colorIdentities_ = card.colorIdentities {
                if let s = colorIdentities_.allObjects as? [CMCardColor] {
                    
                    let string = s.map({ $0.name! }).joined(separator: ", ")
                    if string.count > 0 {
                        text = string
                    }
                }
            }
        case .colors:
            if let colors_ = card.colors,
                let s = colors_.allObjects as? [CMCardColor] {
                
                let string = s.map({ $0.name! }).joined(separator: ", ")
                if string.count > 0 {
                    text = string
                }
            }
        case .colorshifted:
            text = card.isColorshifted ? "Yes" : "No"
        case .convertedManaCost:
            text = "\(String(format: card.convertedManaCost == floor(card.convertedManaCost) ? "%.0f" : "%.1f", card.convertedManaCost))"
        case .frameEffect:
            if let frameEffect = card.frameEffect,
                let name = frameEffect.name {
                text = name
            }
        case .layout:
            if let layout = card.layout,
                let name = layout.name {
                text = name
            }
        case .releaseDate:
            if let releaseDate = card.releaseDate ?? card.set!.releaseDate {
                text = releaseDate
            }
        case .reservedList:
            text = card.isReserved ? "Yes" : "No"
        case .setOnlineOnly:
            if let set = card.set {
                text = set.isOnlineOnly ? "Yes" : "No"
            }
        case .storySpotlight:
            text = card.isStorySpotlight ? "Yes" : "No"
        case .timeshifted:
            text = card.isTimeshifted ? "Yes" : "No"
        }
        return text
    }
    
    func requestForVariations() -> NSFetchRequest<CMCard> {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        
        request.predicate = NSPredicate(format: "set.code = %@ AND language.code = %@ AND id != %@ AND name = %@",
                                        card.set!.code!,
                                        card.language!.code!,
                                        card.id!,
                                        card.name!)
        request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                   NSSortDescriptor(key: "name", ascending: true),
                                   NSSortDescriptor(key: "collectorNumber", ascending: true)]
        return request
    }
    
    func requestForParts() -> NSFetchRequest<CMCard> {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        
        if let partsSet = card.parts,
            let parts = partsSet.allObjects as? [CMCard] {
            request.predicate = NSPredicate(format: "id IN %@",
                                            parts.map({$0.id}))
            request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                       NSSortDescriptor(key: "name", ascending: true),
                                       NSSortDescriptor(key: "collectorNumber", ascending: true)]
        }
        return request
    }

    func requestForOtherPrintings() -> NSFetchRequest<CMCard> {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        
        request.predicate = NSPredicate(format: "set.code != %@ AND language.code = %@ AND id != %@ AND name = %@",
                                        card.set!.code!,
                                        card.language!.code!,
                                        card.id!,
                                        card.name!)
        request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                   NSSortDescriptor(key: "name", ascending: true),
                                   NSSortDescriptor(key: "collectorNumber", ascending: true)]
        return request
    }
    
    func userRatingForCurrentCard() -> Double {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        
        guard let fbUser = Auth.auth().currentUser,
            let user = ManaKit.sharedInstance.findObject("CMUser",
                                                         objectFinder: ["id": fbUser.uid as AnyObject],
                                                         createIfNotFound: false) as? CMUser,
            let set = user.ratings,
            let ratings = set.allObjects as? [CMCardRating] else {
                return 0
        }
        
        for c in ratings {
            if c.card?.id == card.id {
                return c.rating
            }
        }
        return 0
    }
    
    func isCurrentCardFavorite() -> Bool {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        guard let fbUser = Auth.auth().currentUser,
            let user = ManaKit.sharedInstance.findObject("CMUser",
                                                         objectFinder: ["id": fbUser.uid as AnyObject],
                                                         createIfNotFound: false) as? CMUser,
            let set = user.favorites,
            let favorites = set.allObjects as? [CMCard] else {
                return false
        }
        
        for c in favorites {
            if c.id == card.id {
                return true
            }
        }
        return false
    }

    func ratingStringForCard() -> String {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        
        return "\(card.firebaseRatings) Rating\(card.firebaseRatings > 1 ? "s" : "")"
    }
    
    func reloadRelatedCards() {
        partsViewModel = SearchViewModel(withRequest: requestForParts(),
                                         andTitle: nil,
                                         andMode: .loading)
        variationsViewModel = SearchViewModel(withRequest: requestForVariations(),
                                              andTitle: nil,
                                              andMode: .loading)
        otherPrintingsViewModel = SearchViewModel(withRequest: requestForOtherPrintings(),
                                                  andTitle: nil,
                                                  andMode: .loading)
    }

    // MARK: Firebase methods
    func toggleCardFavorite(firstAttempt: Bool) {
        let completion = { () -> Void in
            guard let card = self.object(forRowAt: IndexPath(row: self.cardIndex, section: 0)) as? CMCard else {
                fatalError()
            }
            
            guard let fbUser = Auth.auth().currentUser,
                let user = ManaKit.sharedInstance.findObject("CMUser",
                                                             objectFinder: ["id": fbUser.uid as AnyObject],
                                                             createIfNotFound: false) as? CMUser,
                let id = card.firebaseID else {
                return
            }
            
            let userRef = Database.database().reference().child("users").child(fbUser.uid).child("favorites")
            let favorite = !self.isCurrentCardFavorite()
            
            userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : Bool] {
                    if favorite {
                        post[id] = true
                    } else {
                        post[id] = nil
                    }
                    
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                    
                } else {
                    if firstAttempt {
                        return TransactionResult.abort()
                    } else {
                        userRef.setValue([id: favorite ? true : nil])
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
        
        saveCardData(firstAttempt: true, completion: completion)
    }
    
    func incrementCardViews(firstAttempt: Bool) {
        let completion = { () -> Void in
            guard let card = self.object(forRowAt: IndexPath(row: self.cardIndex, section: 0)) as? CMCard else {
                fatalError()
            }
            let ref = Database.database().reference().child("cards").child(card.firebaseID!)
            
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
                    
                    card.firebaseViews = Int64(fcard.views == nil ? 1 : fcard.views!)
                    
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
        
        saveCardData(firstAttempt: true, completion: completion)
    }

    func updateCardRatings(rating: Double, firstAttempt: Bool) {
        let completion = { () -> Void in
            guard let card = self.object(forRowAt: IndexPath(row: self.cardIndex, section: 0)) as? CMCard else {
                fatalError()
            }
            
            guard let fbUser = Auth.auth().currentUser,
                let user = ManaKit.sharedInstance.findObject("CMUser",
                                                             objectFinder: ["id": fbUser.uid as AnyObject],
                                                             createIfNotFound: false) as? CMUser,
                let id = card.firebaseID else {
                    return
            }
            
            let ref = Database.database().reference().child("cards").child(id)
            
            ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : Any] {
                    var ratings = post[FCCard.Keys.Ratings] as? [String: Double] ?? [String: Double]()
                    var tmpRating = Double(0)
                    
                    ratings[user.id!] = rating
                    for (_,v) in ratings {
                        tmpRating += v
                    }
                    tmpRating = tmpRating / Double(ratings.keys.count)
                    
                    post[FCCard.Keys.Rating] = tmpRating
                    post[FCCard.Keys.Ratings] = ratings
                    
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                    
                } else {
                    if firstAttempt {
                        return TransactionResult.abort()
                    } else {
                        ref.setValue([FCCard.Keys.Rating: rating,
                                      FCCard.Keys.Ratings : [id: rating]])
                        return TransactionResult.success(withValue: currentData)
                    }
                }
                
            }) { (error, committed, snapshot) in
                if committed {
                    guard let snapshot = snapshot else {
                        return
                    }
                    let fcard = FCCard(snapshot: snapshot)
                    
                    card.firebaseRating = fcard.rating == nil ? rating : fcard.rating!
                    card.firebaseRatings = fcard.ratings == nil ? Int32(1) : Int32(fcard.ratings!.count)
                    
                    ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                        try! backgroundContext.save()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                        object: nil,
                                                        userInfo: nil)
                        
                        self.updateUserRatings(rating: rating, firstAttempt: true)
                    }
                    
                } else {
                    // retry again, if we were aborted from above
                    self.updateCardRatings(rating: rating, firstAttempt: false)
                }
            }
        }
        
        saveCardData(firstAttempt: true, completion: completion)
    }
    
    func updateUserRatings(rating: Double, firstAttempt: Bool) {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        
        guard let fbUser = Auth.auth().currentUser,
            let user = ManaKit.sharedInstance.findObject("CMUser",
                                                         objectFinder: ["id": fbUser.uid as AnyObject],
                                                         createIfNotFound: false) as? CMUser,
            let id = card.firebaseID else {
                return
        }
        let userRef = Database.database().reference().child("users").child(fbUser.uid).child("ratedCards")
        
        userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : Double] {
                post[id] = rating
                
                // Set value and report transaction success
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
                
            } else {
                if firstAttempt {
                    return TransactionResult.abort()
                } else {
                    userRef.setValue([id: rating])
                    return TransactionResult.success(withValue: currentData)
                }
            }
            
        }) { (error, committed, snapshot) in
            if committed {
                if let snapshot = snapshot,
                    let ratedCards = snapshot.value as? [String: Double] {
                    
                    for (k,v) in ratedCards {
                        if let c = ManaKit.sharedInstance.findObject("CMCard",
                                                                  objectFinder: ["firebaseID": k as AnyObject],
                                                                  createIfNotFound: false) as? CMCard,
                            let cardRating = ManaKit.sharedInstance.findObject("CMCardRating",
                                                                           objectFinder: ["user.id": user.id! as AnyObject,
                                                                                          "card.id": k as AnyObject],
                                                                           createIfNotFound: true) as? CMCardRating {
                            cardRating.card = c
                            cardRating.user = user
                            cardRating.rating = v
                            user.addToRatings(cardRating)
                        }
                    }
                    
                    ManaKit.sharedInstance.dataStack!.performInNewBackgroundContext { backgroundContext in
                        try! backgroundContext.save()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                        object: nil,
                                                        userInfo: nil)
                    }
                }
            } else {
                // retry again, if we were aborted from above
                self.updateUserRatings(rating: rating, firstAttempt: false)
            }
        }
    }

    private func saveCardData(firstAttempt: Bool, completion: @escaping () -> Void) {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        let ref = Database.database().reference().child("cards").child(card.firebaseID!)
        
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : Any] {
                for (k,v) in self.firebaseCardData() {
                    post[k] = v
                }
                
                // Set value and report transaction success
                currentData.value = post
                return TransactionResult.success(withValue: currentData)
                
            } else {
                if firstAttempt {
                    return TransactionResult.abort()
                } else {
                    ref.setValue(self.firebaseCardData())
                    return TransactionResult.success(withValue: currentData)
                }
            }
            
        }) { (error, committed, snapshot) in
            if committed {
                completion()
            } else {
                // retry again, if we were aborted from above
                self.saveCardData(firstAttempt: false, completion: completion)
            }
        }
    }
    
    func loadCardData() {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        let ref = Database.database().reference().child("cards").child(card.firebaseID!)
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [String : Any] else {
                return
            }
            
            
            // update views
            if let views = value["Views"] as? Int {
                card.firebaseViews = Int64(views)
            }
            if let rating = value["Rating"] as? Double {
                card.firebaseRating = rating
            }
            try! ManaKit.sharedInstance.dataStack?.mainContext.save()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.CardViewsUpdated),
                                            object: nil,
                                            userInfo: nil)
        })
    }
    
    private func firebaseCardData() -> [String: Any] {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var dict = [String: Any]()
        
        dict["Name"] = card.name
        dict["CMC"] = card.convertedManaCost
        dict["ManaCost"] = card.manaCost
        
        if let imageUris = card.imageURIs {
            if let d = NSKeyedUnarchiver.unarchiveObject(with: imageUris as Data) as? [String: String] {
                dict["image_uris"] = d
            }
        } else {
            if let imageURL = ManaKit.sharedInstance.imageURL(ofCard: card,
                                                              imageType: .normal,
                                                              faceOrder: faceOrder) {
                dict["image_uri"] = imageURL.absoluteString
            }
        }
        dict["ImageURL"] = nil
        dict["CropURL"] = nil
        
        if let type = card.myType {
            dict["Type"] = type.name
        } else {
            dict["Type"] = nil
        }
        
        if let rarity = card.rarity {
            dict["Rarity"] = rarity.name
        } else {
            dict["Rarity"] = ""
        }
        
        if let set = card.set {
            dict["Set_Name"] = set.name
            dict["Set_Code"] = set.code
            dict["Set_KeyruneCode"] = set.myKeyruneCode
        }
        
        if let keyruneColor = ManaKit.sharedInstance.keyruneColor(forCard: card) {
            dict["KeyruneColor"] = keyruneColor.hexValue()
        } else {
            dict["KeyruneColor"] = ""
        }
        
        return dict
    }
    
    override func getFetchedResultsController(with fetchRequest: NSFetchRequest<NSManagedObject>?) -> NSFetchedResultsController<NSManagedObject> {
        let context = ManaKit.sharedInstance.dataStack!.viewContext
        var request: NSFetchRequest<CMCard>?
        
        if let fetchRequest = fetchRequest {
            request = fetchRequest as? NSFetchRequest<CMCard>
        } else {
            // Create a default fetchRequest
            request = CMCard.fetchRequest()
            request!.sortDescriptors = sortDescriptors
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
        
        return frc as! NSFetchedResultsController<NSManagedObject>
    }
}


