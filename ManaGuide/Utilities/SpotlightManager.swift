//
//  SpotlightManager.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 14/12/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import CoreServices
import CoreSpotlight
import ManaKit
import PromiseKit
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
    func createSpotlightItems() {
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
    
    private func deletePreviousSpotlightItems() {
        CSSearchableIndex.default()
            .deleteAllSearchableItems { error in
                if let error = error {
                    print("Error deleting spotlight items: \(error)")
                } else {
                    print("Spotlight indexing deleted.")
                }
        }
    }
    
    private func createSetItems() -> Promise<Void> {
        return Promise { seal in
            let request: NSFetchRequest<CMSet> = CMSet.fetchRequest()
            request.predicate = NSPredicate(format: "parent = nil")
            request.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]
            
            var items = [CSSearchableItem]()
            for set in try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) {
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
                attributeSet.domainIdentifier = "ManaGuide-sets"
                
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
            let request: NSFetchRequest<CMCard> = CMCard.fetchRequest()
            request.predicate = NSPredicate(format: "language.code = %@ AND id != nil", "en")
            request.sortDescriptors = [NSSortDescriptor(key: "set.releaseDate", ascending: false),
                                       NSSortDescriptor(key: "name", ascending: true)]
            
            for card in  try! ManaKit.sharedInstance.dataStack!.mainContext.fetch(request) {
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
                    let path = SDImageCache.shared().defaultCachePath(forKey: urlString),
                    let localUrl = URL(string: "file://\(path)") {
                    
                    attributeSet.thumbnailURL = localUrl
                    
                }
                attributeSet.domainIdentifier = "ManaGuide-cards"
                
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
        nameLabel.text = ManaKit.sharedInstance.keyruneUnicode(forSet: set)
        UIGraphicsBeginImageContext(frame.size)
        if let currentContext = UIGraphicsGetCurrentContext() {
            nameLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }
}
