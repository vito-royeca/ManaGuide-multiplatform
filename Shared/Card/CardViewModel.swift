//
//  CardViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 08.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import SwiftUI
import ManaKit

class CardViewModel: ViewModel {
    @Published var index = 0
    @Published var card: NSManagedObjectID?
    @Published var cards: [NSManagedObjectID] = []
    
    // MARK: - Variables
    
    var newID: String
    var relatedCards: [NSManagedObjectID]
    var dataAPI: API

    // MARK: - Initializers
    
    init(newID: String,
         relatedCards: [NSManagedObjectID],
         dataAPI: API = ManaKit.shared) {
        self.newID = newID
        self.relatedCards = relatedCards
        self.dataAPI = dataAPI
    }

    // MARK: - Methods
    
    override func fetchRemoteData() async throws {
        guard !isBusy else {
            return
        }

        do {
            if try dataAPI.willFetchCard(newID: newID) {
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                    self.isFailed = false
                }

                let objectID = try await dataAPI.fetchCard(newID: newID)
                
                DispatchQueue.main.async {
                    self.isBusy.toggle()

                    self.card = objectID
                    if let card = self.card {
                        self.cards = self.relatedCards.isEmpty ? [card] : self.relatedCards
                        self.index = self.cards.firstIndex(of: card) ?? 0
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.card = self.findCard(newID: self.newID)
                    if let card = self.card {
                        self.cards = self.relatedCards.isEmpty ? [card] : self.relatedCards
                        self.index = self.cards.firstIndex(of: card) ?? 0
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isBusy.toggle()
                self.isFailed = true
            }
        }
    }
    
    func fetchPreviousRemoteData() async throws {
        for i in stride(from: 5, through: 1, by: -1) {
            let previousIndex = index - i
            
            if previousIndex >= 0 {
                do {
                    if let previousCard = find(MGCard.self, id: cards[previousIndex]),
                        try dataAPI.willFetchCard(newID: previousCard.newIDCopy) {
                        let _ = try await dataAPI.fetchCard(newID: previousCard.newIDCopy)
                    }
                } catch {
                    print(error)
                }
            }
        }
    }

    func fetchNextRemoteData() async throws {
        for i in 1...5 {
            let nextIndex = index + i
            
            if nextIndex <= cards.count - 1 {
                do {
                    if let nextCard = find(MGCard.self, id: cards[nextIndex]),
                       try dataAPI.willFetchCard(newID: nextCard.newIDCopy) {
                        _ = try await dataAPI.fetchCard(newID: nextCard.newIDCopy)
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension CardViewModel {
    func findCard(newID: String) -> NSManagedObjectID? {
        let predicate = NSPredicate(format: "newID == %@", newID)
        return ManaKit.shared.find(MGCard.self,
                                   properties: nil,
                                   predicate: predicate,
                                   sortDescriptors: nil,
                                   createIfNotFound: false)?.first?.objectID
    }

    var cardObject: MGCard? {
        get {
            if let card = card {
                find(MGCard.self, id: card)
            } else {
                nil
            }
        }
    }
}

// MARK: - Legacy Code
/*

 // MARK: Enums
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
     case relatedData
     case rulings
     case legalities
     case otherDetails
     
     var description : String {
         switch self {
         // Use Internationalization, as appropriate.
         case .mainData: return "Main Data"
         case .set: return "Set"
         case .relatedData: return "Related Data"
         case .rulings: return "Rulings"
         case .legalities: return "Legalities"
         case .otherDetails: return "Other Details"
         }
     }
     
     static var count: Int {
         return 6
     }
 }

 enum CardRelatedDataSection : Int {
     case artist
     case parts
     case variations
     case otherPrintings
     
     var description : String {
         switch self {
         // Use Internationalization, as appropriate.
             case .artist: return "Artist"
             case .parts: return "Faces, Tokens, & Other Parts"
             case .variations: return "Variations"
             case .otherPrintings: return "Other Printings"
         }
     }
     
     static var count: Int {
         return 4
     }
 }

 enum CardDetailsMainDataSection : Int {
     case name
     case type
     case text
     case powerToughness
     case loyalty
     
     static var count: Int {
         return 5
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

extension CardViewModel {
    func numberOfRows(inSection section: Int) -> Int {
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
            case CardDetailsSection.relatedData.rawValue:
                rows = CardRelatedDataSection.count
            case CardDetailsSection.rulings.rawValue:
                rows = card.cardRulings.count >= 1 ? card.cardRulings.count : 1
            case CardDetailsSection.legalities.rawValue:
                rows = card.cardLegalities.count >= 1 ? card.cardLegalities.count : 1
            case CardDetailsSection.otherDetails.rawValue:
                rows = CardOtherDetailsSection.count
            default:
                rows = 1
            }
        case .store:
            guard let storePricing = card.tcgplayerStorePricing else {
                return 1
            }
            rows = storePricing.suppliers.count + 1
        }
        
        return rows
    }
    
    func numberOfSections() -> Int {
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
    
    func titleForHeaderInSection(section: Int) -> String? {
        var headerTitle: String?
        
        switch content {
        case .details:
            switch section {
            case CardDetailsSection.set.rawValue:
                headerTitle = CardDetailsSection.set.description
            case CardDetailsSection.relatedData.rawValue:
                headerTitle = CardDetailsSection.relatedData.description
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

    func object(forRowAt indexPath: IndexPath) -> Object? {
        guard let results = _results else {
            return nil
        }
        return results[indexPath.row]
    }
    
    func count() -> Int {
        guard let results = _results else {
            return 0
        }
        return results.count
    }
    
    func fetchData() -> Promise<Void> {
        return Promise { seal  in
            if let predicate = predicate {
                _results = ManaKit.sharedInstance.realm.objects(CMCard.self).filter(predicate)
            } else {
                _results = ManaKit.sharedInstance.realm.objects(CMCard.self)
            }
            
            if let sortDescriptors = sortDescriptors {
                _results = _results!.sorted(by: sortDescriptors)
            }
            
            updateSections()
            seal.fulfill(())
        }
    }
    
    // MARK: Custom methods
    func numberOfParts() -> Int {
        var count = 0
        
        if let model = _partsViewModel {
            count = model.count()
        }
        return count
    }
    
    func numberOfVariations() -> Int {
        var count = 0
        
        if let model = _variationsViewModel {
            count = model.count()
        }
        return count
    }
    
    func numberOfOtherPrintings() -> Int {
        var count = 0
        
        if let model = _otherPrintingsViewModel {
            count = model.count()
        }
        return count
    }
    
    func numberOfRulings() -> Int {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        return card.cardRulings.count
    }
    
    func numberOfLegalities() -> Int {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        return card.cardLegalities.count
    }

    func cardMainDetails() -> [[CardDetailsMainDataSection: CMCard]] {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        var details = [[CardDetailsMainDataSection: CMCard]]()
        var array = [CMCard]()
        var faceIndex = 0

        if card.faces.count > 0 {
            let orderedFaces = card.faces.sorted(by: {(a, b) -> Bool in
                return a.faceOrder < b.faceOrder
            })
            array.append(contentsOf: orderedFaces)
        } else {
            array.append(card)
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
            
            // power / toughness / loyalty
            if let type = card.typeLine,
                let name = type.name {
                if name.contains("Creature") {
                    if let _ = a.power,
                        let _ = a.toughness {
                        details.append([CardDetailsMainDataSection.powerToughness: a])
                    }
                } else if name.contains("Planeswalker") {
                    if let _ = a.loyalty {
                        details.append([CardDetailsMainDataSection.loyalty: a])
                    }
                }
            }
            
            faceIndex += 1
        }
        
        return details
    }
    
    func rulingText(inRow row: Int, pointSize: CGFloat) -> NSAttributedString? {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            return nil
        }
        
        let sortedRulings = card.cardRulings.sorted(by: {(first: Any, second: Any) -> Bool in
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
            let string = card.colorIdentities.map({ $0.name! }).joined(separator: ", ")
            if string.count > 0 {
                text = string
            }
        case .colors:
            let string = card.colors.map({ $0.name! }).joined(separator: ", ")
            if string.count > 0 {
                text = string
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
    
//    func predicateForVariations() -> NSPredicate {
//        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
//            fatalError()
//        }
//        return NSPredicate(format: "set.code = %@ AND language.code = %@ AND id != %@ AND name = %@",
//                           card.set!.code!,
//                           card.language!.code!,
//                           card.id!,
//                           card.name!)
//        request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: false),
//                                   NSSortDescriptor(key: "name", ascending: true),
//                                   NSSortDescriptor(key: "myNumberOrder", ascending: true)]
//    }
//
//    func predicateForParts() -> NSPredicate {
//        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
//            fatalError()
//        }
//
//        return NSPredicate(format: "id IN %@",
//                           card.parts.map({$0.id}))
//    }
//
//    func predicateForOtherPrintings() -> NSPredicate {
//        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
//            fatalError()
//        }
//
//        return NSPredicate(format: "set.code != %@ AND language.code = %@ AND id != %@ AND name = %@",
//                           card.set!.code!,
//                           card.language!.code!,
//                           card.id!,
//                           card.name!)
//    }
    
    func userRatingForCurrentCard() -> Double {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        
        guard let fbUser = Auth.auth().currentUser,
            let user = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", fbUser.uid).first else {
            return 0
        }
        
        for c in user.ratings {
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
            let user = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", fbUser.uid).first else {
            return false
        }
        
        for c in user.favorites {
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
        let count = card.firebaseUserRatings.count
        return "\(count) Rating\(count > 1 ? "s" : "")"
    }
    
    func reloadRelatedCards() {
        guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard else {
            fatalError()
        }
        
        let sd = [SortDescriptor(keyPath: "set.releaseDate", ascending: false),
                  SortDescriptor(keyPath: "name", ascending: true),
                  SortDescriptor(keyPath: "myNumberOrder", ascending: true)]


        let variationsPredicate = NSPredicate(format: "set.code = %@ AND language.code = %@ AND id != %@ AND name = %@",
                                              card.set!.code!,
                                              card.language!.code!,
                                              card.id!,
                                              card.name!)
        
        let partsPredicate = NSPredicate(format: "id IN %@",
                                         card.parts.map({$0.id}))
    
        
        let otherPrintingsPredicate = NSPredicate(format: "set.code != %@ AND language.code = %@ AND id != %@ AND name = %@",
                                                  card.set!.code!,
                                                  card.language!.code!,
                                                  card.id!,
                                                  card.name!)
        
        _partsViewModel = SearchViewModel(withPredicate: partsPredicate,
                                          andSortDescriptors: sd,
                                          andTitle: nil,
                                          andMode: .loading)
        _variationsViewModel = SearchViewModel(withPredicate: variationsPredicate,
                                               andSortDescriptors: sd,
                                               andTitle: nil,
                                               andMode: .loading)
        _otherPrintingsViewModel = SearchViewModel(withPredicate: otherPrintingsPredicate,
                                                   andSortDescriptors: sd,
                                                   andTitle: nil,
                                                   andMode: .loading)
        
        firstly {
            when(fulfilled: [_partsViewModel!.fetchData(),
                             _variationsViewModel!.fetchData(),
                             _otherPrintingsViewModel!.fetchData()])
        }.done {
            self._partsViewModel!.mode = self._partsViewModel!.isEmpty() ? .noResultsFound : .resultsFound
            self._variationsViewModel!.mode = self._variationsViewModel!.isEmpty() ? .noResultsFound : .resultsFound
            self._otherPrintingsViewModel!.mode = self._otherPrintingsViewModel!.isEmpty() ? .noResultsFound : .resultsFound

            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardRelatedDataUpdated),
                                            object: nil,
                                            userInfo: ["card": card])
        }.catch { error in
            self._partsViewModel!.mode = .error
            self._variationsViewModel!.mode = .error
            self._otherPrintingsViewModel!.mode = .error

            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.CardRelatedDataUpdated),
                                            object: nil,
                                            userInfo: ["card": card])
        }
    }

    func downloadCardPricing() {
        guard let results = _results else {
            return
        }
        
        var cards = [CMCard]()
        for card in results {
            if card.willUpdateTCGPlayerCardPricing() {
                cards.append(card)
            }
        }
        
        if cards.count > 0 {
            firstly {
                ManaKit.sharedInstance.authenticateTcgPlayer()
            }.then {
                ManaKit.sharedInstance.getTcgPlayerPrices(forCards: cards)
            }.done {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.CardPricingUpdated),
                                                object: nil,
                                                userInfo: nil)
            }.catch { error in
                print(error)
            }
        }
    }
    
    // MARK: Firebase methods
    func toggleCardFavorite()  -> Promise<Void> {
        guard let card = self.object(forRowAt: IndexPath(row: self.cardIndex, section: 0)) as? CMCard,
            let firebaseID = card.firebaseID else {
            fatalError()
        }
        
        return Promise<Void> { seal in
            guard let fbUser = Auth.auth().currentUser,
                let user = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", fbUser.uid).first else {
                return
            }
            
            let userRef = Database.database().reference().child("users").child(fbUser.uid).child("favorites")
            let favorite = !self.isCurrentCardFavorite()
            
            userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : Bool] {
                    if favorite {
                        post[firebaseID] = true
                    } else {
                        post[firebaseID] = nil
                    }
                    
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                    
                } else {
                    userRef.setValue([firebaseID: favorite ? true : nil])
                    return TransactionResult.success(withValue: currentData)
                }
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    seal.reject(error)
                } else {
                    try! ManaKit.sharedInstance.realm.write {
                        if favorite {
                            card.firebaseUserFavorites.append(user)
                        } else {
                            if let index = card.firebaseUserFavorites.index(of: user) {
                                card.firebaseUserFavorites.remove(at: index)
                            }
                        }
                        ManaKit.sharedInstance.realm.add(user)
                    }
                    
                    // reload results
                    firstly {
                        self.saveFirebaseData(with: firebaseID)
                    }.then {
                        self.fetchData()
                    }.done {
                        if let index = self._results!.index(of: card) {
                            self.cardIndex = index
                        }
                        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                        object: nil,
                                                        userInfo: ["card": card])
                        seal.fulfill(())
                    }.catch { error in
                        seal.reject(error)
                    }
                }
            }
        }
    }
    
    func incrementCardViews() -> Promise<Void> {
        guard let card = self.object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard,
            let firebaseID = card.firebaseID else {
            fatalError()
        }
        

        return Promise<Void> { seal in
            let ref = Database.database().reference().child("cards").child(firebaseID)
            
            ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : Any] {
                    var views = post[FCCard.Keys.Views] as? Int ?? 0
                    views += 1
                    post[FCCard.Keys.Views] = views
                    
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                    
                } else {
                    ref.setValue([FCCard.Keys.Views: 1])
                    return TransactionResult.success(withValue: currentData)
                }
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    seal.reject(error)
                } else {
                    guard let snapshot = snapshot else {
                        return
                    }
                    let fcard = FCCard(snapshot: snapshot)
                    
                    try! ManaKit.sharedInstance.realm.write {
                        card.firebaseViews = Int64(fcard.views == nil ? 1 : fcard.views!)
                        ManaKit.sharedInstance.realm.add(card)
                    }
                    
                    // reload results
                    firstly {
                        self.saveFirebaseData(with: firebaseID)
                    }.then {
                        self.fetchData()
                    }.done {
                        if let index = self._results!.index(of: card) {
                            self.cardIndex = index
                        }
                        seal.fulfill(())
                    }.catch { error in
                        seal.reject(error)
                    }
                }
            }
        }
    }

    func updateCardRatings(rating: Double) -> Promise<Void> {
        guard let card = self.object(forRowAt: IndexPath(row: self.cardIndex, section: 0)) as? CMCard,
            let firebaseID = card.firebaseID else {
            fatalError()
        }
        
        return Promise<Void> { seal in
            guard let fbUser = Auth.auth().currentUser,
                let user = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", fbUser.uid).first,
                let userID = user.id else {
                return
            }
            
            let ref = Database.database().reference().child("cards").child(firebaseID)
            
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
                    ref.setValue([FCCard.Keys.Rating: rating,
                                  FCCard.Keys.Ratings: [userID: rating]])
                    return TransactionResult.success(withValue: currentData)
                }
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    seal.reject(error)
                } else {
                    guard let snapshot = snapshot else {
                        return
                    }
                    let fcard = FCCard(snapshot: snapshot)
                    
                    try! ManaKit.sharedInstance.realm.write {
                        card.firebaseRating = fcard.rating == nil ? rating : fcard.rating!
                        
                        if let ratings = fcard.ratings {
                            for (k,v) in ratings {
                                var user: CMUser?
                                var cardRating: CMCardRating?
                                
                                if let u = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", k).first {
                                    user = u
                                } else {
                                    user = CMUser()
                                    user!.id = k
                                }
                                ManaKit.sharedInstance.realm.add(user!)
                                
                                if let u = ManaKit.sharedInstance.realm.objects(CMCardRating.self).filter("user.id = %@ AND card.firebaseID = %@", k, firebaseID).first {
                                    cardRating = u
                                } else {
                                    cardRating = CMCardRating()
                                }
                                cardRating!.card = card
                                cardRating!.user = user
                                cardRating!.rating = v
                                ManaKit.sharedInstance.realm.add(cardRating!)
                                
                                card.firebaseUserRatings.append(cardRating!)
                                ManaKit.sharedInstance.realm.add(card)
                            }
                        } else {
                            var user: CMUser?
                            var cardRating: CMCardRating?
                            
                            if let u = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", userID).first {
                                user = u
                            } else {
                                user = CMUser()
                                user!.id = userID
                            }
                            ManaKit.sharedInstance.realm.add(user!)
                            
                            if let u = ManaKit.sharedInstance.realm.objects(CMCardRating.self).filter("user.id = %@ AND card.firebaseID = %@", userID, firebaseID).first {
                                cardRating = u
                            } else {
                                cardRating = CMCardRating()
                            }
                            cardRating!.card = card
                            cardRating!.user = user
                            cardRating!.rating = rating
                            ManaKit.sharedInstance.realm.add(cardRating!)
                            
                            card.firebaseUserRatings.append(cardRating!)
                            ManaKit.sharedInstance.realm.add(card)
                        }
                    }

                    seal.fulfill(())
                }
            }
        }
    }
    
    func updateUserRatings(rating: Double) -> Promise<Void> {
        return Promise { seal in
            guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard,
                let firebaseID = card.firebaseID else {
                fatalError()
            }
            
            guard let fbUser = Auth.auth().currentUser,
                let _ = ManaKit.sharedInstance.realm.objects(CMUser.self).filter("id = %@", fbUser.uid).first else {
                return
            }
            let userRef = Database.database().reference().child("users").child(fbUser.uid).child("ratedCards")
            
            userRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : Double] {
                    post[firebaseID] = rating
                    
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                    
                } else {
                    userRef.setValue([firebaseID: rating])
                    return TransactionResult.success(withValue: currentData)
                }
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    seal.reject(error)
                } else {
//                    if let snapshot = snapshot,
//                        let ratedCards = snapshot.value as? [String: Double] {
//
//                        for (k,v) in ratedCards {
//                            if let card = ManaKit.sharedInstance.realm.objects(CMCard.self).filter("firebaseID = %@", k).first {
//                                var cardRating: CMCardRating?
//
//                                if let c = ManaKit.sharedInstance.realm.objects(CMCardRating.self).filter("user.id = %@ AND card.id = %@", user.id!, k).first {
//                                    cardRating = c
//                                } else {
//                                    cardRating = CMCardRating()
//                                }
//                                cardRating!.card = card
//                                cardRating!.user = user
//                                cardRating!.rating = v
//                                ManaKit.sharedInstance.realm.add(cardRating!)
//
//                                user.ratings.append(cardRating!)
//                                ManaKit.sharedInstance.realm.add(user)
//                            }
//                        }
//                        seal.fulfill(())
//                    }
                    seal.fulfill(())
                }
            }
        }
    }

    func loadFirebaseData() -> Promise<Void> {
        return Promise { seal in
            guard let card = object(forRowAt: IndexPath(row: cardIndex, section: 0)) as? CMCard,
                let firebaseID = card.firebaseID else {
                fatalError()
            }
            
            let ref = Database.database().reference().child("cards").child(firebaseID)
            
            ref.observeSingleEvent(of: .value, with: { snapshot in
                if let value = snapshot.value as? [String : Any] {
                    // update views
                    try! ManaKit.sharedInstance.realm.write {
                        if let views = value[FCCard.Keys.Views] as? Int {
                            card.firebaseViews = Int64(views)
                        }
                        if let rating = value[FCCard.Keys.Rating] as? Double {
                            card.firebaseRating = rating
                        }
                        ManaKit.sharedInstance.realm.add(card)
                        seal.fulfill(())
                    }
                } else {
                    seal.fulfill(())
                }
            })
        }
    }
    
    func saveFirebaseData(with firebaseID: String) -> Promise<Void> {
        return Promise { seal in
            let ref = Database.database().reference().child("cards").child(firebaseID)
            let data = firebaseData(with: firebaseID)
            
            ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var post = currentData.value as? [String : Any] {
                    for (k,v) in data {
                        post[k] = v
                    }
                    
                    // Set value and report transaction success
                    currentData.value = post
                    return TransactionResult.success(withValue: currentData)
                    
                } else {
                    ref.setValue(data)
                    return TransactionResult.success(withValue: currentData)
                }
                
            }) { (error, committed, snapshot) in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }
        }
    }
    
    func deleteOldFirebaseData(with firebaseID: String) -> Promise<Void> {
        return Promise<Void> { seal in
            let ref = Database.database().reference().child("cards").child(firebaseID)
            
            ref.removeValue(completionBlock: { error, _ in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
                
            })
        }
    }
    
    func firebaseData(with firebaseID: String) -> [String: Any] {
        guard let card = ManaKit.sharedInstance.realm.objects(CMCard.self).filter("firebaseID = %@", firebaseID).first else {
            fatalError()
        }
        
        var dict = [String: Any]()
        
        dict["CMC"] = card.convertedManaCost
        dict["Mana"] = card.manaCost
        
        if let imageUris = card.imageURIs {
            if let d = NSKeyedUnarchiver.unarchiveObject(with: imageUris as Data) as? [String: String] {
                dict["image_uris"] = d
            }
        }
        
        if let keyruneCode = card.set!.myKeyruneCode {
            dict["Keyrune"] = keyruneCode
        } else {
            dict["Keyrune"] = nil
        }
        
        if let keyruneColor = card.keyruneColor() {
//            dict["KeyruneColor"] = keyruneColor.hexValue()
        } else {
            dict["KeyruneColor"] = ""
        }
        
        var ratings = [String: Double]()
        for rating in card.firebaseUserRatings {
            ratings[rating.user!.id!] = rating.rating
        }
        dict[FCCard.Keys.Views] = card.firebaseViews
        dict[FCCard.Keys.Rating] = card.firebaseRating
        dict[FCCard.Keys.Ratings] = ratings
        
        return dict
    }
}
*/

