//
//  SpotlightManager.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 14/12/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreServices
import CoreSpotlight
import ManaKit
import PromiseKit
import RealmSwift
import SDWebImage

enum SpotlightCardProperties: String, CaseIterable {
    case firebaseID
    case name
    case myTypeName = "myType.name"
    case power
    case toughness
    case loyalty
    case imageURIs
}

class SpotlightManager: NSObject {
    func addSpotlightItem(forCards cards: [CMCard]) {
        var items = [CSSearchableItem]()

        for card in cards {
            // Create an attribute set to describe an item.
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeData as String)
            
            // Add metadata that supplies details about the item.
            attributeSet.title = "\(card.name!)"
            if let typeName = card.typeLine!.name {
                var description = "\(typeName)"
                
                if let myType = card.myType,
                    let myTypeName = myType.name {
                    if myTypeName == "Creature" {
                        if let power = card.power,
                            let toughness = card.toughness {
                            description += "\n\(power)/\(toughness)"
                        }
                    }
                }
                attributeSet.contentDescription = description
            }
            if let imageURIs = card.imageURIs,
                let dict = NSKeyedUnarchiver.unarchiveObject(with: imageURIs as Data) as? [String: String],
                let urlString = dict["normal"],
                let path = SDImageCache.shared.cachePath(forKey: urlString),
                let localUrl = URL(string: "file://\(path)") {
                
                attributeSet.thumbnailURL = localUrl
            }
            attributeSet.domainIdentifier = "cards"
            
            // Create an item with a unique identifier, a domain identifier, and the attribute set you created earlier.
            let item = CSSearchableItem(uniqueIdentifier: "\(card.id!)",
                domainIdentifier: "cards",
                attributeSet: attributeSet)
            items.append(item)
        }
        
        // Add the item to the on-device index.
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("\(error)")
            }
        }
    }
    
    func createSpotlightItems() {
        var willCopy = true
        
        if let scryfallDate = UserDefaults.standard.string(forKey: ManaKit.UserDefaultsKeys.ScryfallDate) {
            if scryfallDate == ManaKit.Constants.ScryfallDate {
                willCopy = false
            }
        }
        
        if willCopy {
            deletePreviousSpotlightItems()

            firstly {
    //            when(fulfilled: createSetItems(), createCardItems())
                createCardItems()
            }.done {
                print("Spotlight indexing done.")
            }.catch { error in
                print("\(error)")
            }
        }
    }
    
    private func deletePreviousSpotlightItems() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error = error {
                print("Error deleting spotlight items: \(error)")
            } else {
                print("Spotlight indexing deleted.")
            }
        }
    }
    
    private func createSetItems() -> Promise<Void> {
        return Promise { seal in
            let predicate = NSPredicate(format: "parent = nil")
            let sortDescriptors = [SortDescriptor(keyPath: "releaseDate", ascending: false)]
            
            var items = [CSSearchableItem]()
            for set in ManaKit.sharedInstance.realm.objects(CMSet.self).filter(predicate).sorted(by: sortDescriptors) {
                // Create an attribute set to describe an item.
                let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeData as String)
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                
                // Add metadata that supplies details about the item.
                attributeSet.title = "\(set.name!)"
                attributeSet.contentDescription = "Set Code: \(set.code!)\nCards: \(set.cardCount)"
                if let releaseDate = set.releaseDate {
                    attributeSet.addedDate = f.date(from: releaseDate)
                    attributeSet.completionDate = f.date(from: releaseDate)
                }
                attributeSet.thumbnailData = self.setIcon(set: set)?.pngData()
                attributeSet.domainIdentifier = "sets"
                
                // Create an item with a unique identifier, a domain identifier, and the attribute set you created earlier.
                let item = CSSearchableItem(uniqueIdentifier: "\(set.code!)",
                    domainIdentifier: "sets",
                    attributeSet: attributeSet)
                items.append(item)
            }
            
            // Add the item to the on-device index.
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }
        }
    }
    
    private func createCardItems() -> Promise<Void> {
        return Promise { seal in
            var dict = [String: CMCard]()
            let predicate = NSPredicate(format: "language.code = %@ AND id != nil", "en")
            let sortDescriptors = [SortDescriptor(keyPath: "set.releaseDate", ascending: false),
                                   SortDescriptor(keyPath: "name", ascending: true)]
            
            for card in  ManaKit.sharedInstance.realm.objects(CMCard.self).filter(predicate).sorted(by: sortDescriptors) {
                if let _ = dict[card.name!] {
                    continue
                } else {
                    dict[card.name!] = card
                }
            }

            var items = [CSSearchableItem]()
            let cards = Array(dict.values)
            for card in cards {
                // Create an attribute set to describe an item.
                let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeData as String)
                
                // Add metadata that supplies details about the item.
                attributeSet.title = "\(card.name!)"
                if let typeName = card.typeLine!.name {
                    var description = "\(typeName)"
                    
                    if let myType = card.myType,
                        let myTypeName = myType.name {
                        if myTypeName == "Creature" {
                            if let power = card.power,
                                let toughness = card.toughness {
                                description += "\n\(power)/\(toughness)"
                            }
                        }
                    }
                    attributeSet.contentDescription = description
                }
                if let imageURIs = card.imageURIs,
                    let dict = NSKeyedUnarchiver.unarchiveObject(with: imageURIs as Data) as? [String: String],
                    let urlString = dict["normal"],
                    let path = SDImageCache.shared.cachePath(forKey: urlString),
                    let localUrl = URL(string: "file://\(path)") {
                    
                    attributeSet.thumbnailURL = localUrl
                    
                }
                attributeSet.domainIdentifier = "cards"
                
                // Create an item with a unique identifier, a domain identifier, and the attribute set you created earlier.
                let item = CSSearchableItem(uniqueIdentifier: "\(card.id!)",
                    domainIdentifier: "cards",
                    attributeSet: attributeSet)
                items.append(item)
            }
                
            // Add the item to the on-device index.
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }
        }
    }
    
    private func setIcon(set: CMSet) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: 180, height: 180)
        let nameLabel = UILabel(frame: frame)
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = .black
        nameLabel.font = UIFont(name: "Keyrune", size: 180)
        nameLabel.text = set.keyruneUnicode()
        UIGraphicsBeginImageContext(frame.size)
        if let currentContext = UIGraphicsGetCurrentContext() {
            nameLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }
}
