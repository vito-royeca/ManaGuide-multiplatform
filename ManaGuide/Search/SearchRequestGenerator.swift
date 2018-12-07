//
//  SearchRequestGenerator.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 12/07/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import ManaKit

enum SearchKey : Int {
    case keywordName
    case keywordText
    case flavorText
    
    var description : String {
        switch self {
        case .keywordName: return "searchKeywordName"
        case .keywordText: return "searchKeywordText"
        case .flavorText: return "searchFlavorText"
        }
    }
}

enum DisplayKey : Int {
    case sortBy
    case orderBy
    case displayBy
    
    var description : String {
        switch self {
        case .sortBy: return "searchSortBy"
        case .orderBy: return "searchOrderBy"
        case .displayBy: return "searchDisplayBy"
        }
    }
}

class SearchRequestGenerator: NSObject {
    func searchValue(for key: SearchKey) -> Any? {
        var value: Any?
        
        switch key {
        case .keywordName:
            if let v = UserDefaults.standard.value(forKey: key.description) as? Bool {
                value = v
            } else {
                value = true
            }
        case .keywordText:
            if let v = UserDefaults.standard.value(forKey: key.description) as? Bool {
                value = v
            } else {
                value = false
            }
        case .flavorText:
            if let v = UserDefaults.standard.value(forKey: key.description) as? Bool {
                value = v
            } else {
                value = false
            }
        }
        
        return value
    }
    
    func displayValue(for key: DisplayKey) -> Any? {
        var value: Any?
        
        switch key {
        case .sortBy:
            if let v = UserDefaults.standard.value(forKey: key.description) as? String {
                value = v
            } else {
                value = "name"
            }
        case .orderBy:
            if let v = UserDefaults.standard.value(forKey: key.description) as? Bool {
                value = v
            } else {
                value = true
            }
        case .displayBy:
            if let v = UserDefaults.standard.value(forKey: key.description) as? String {
                value = v
            } else {
                value = "list"
            }
        }

        return value
    }

    func syncValues(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        
        for (k,v) in userInfo {
            UserDefaults.standard.set(v, forKey: k)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    func getSectionName() -> String? {
        var sectionName: String?
        
        guard let sortBy = displayValue(for: .sortBy) as? String else {
            return "nameSection"
        }
        
        switch sortBy {
        case "name":
            sectionName = "myNameSection"
        case "number":
            sectionName = nil
        case "type":
            sectionName = "typeLine.name"
        case "rarity":
            sectionName = "rarity.name"
        case "artist":
            sectionName = "artist.name"
        default:
            ()
        }
        
        return sectionName
    }
    
    func createSearchRequest(query: String?, oldRequest: NSFetchRequest<CMCard>?) -> NSFetchRequest<CMCard>? {
        let newRequest: NSFetchRequest<CMCard> = CMCard.fetchRequest()
        var predicate = createKeywordPredicate(query: query)
        
        // create a negative predicate, i.e. search for cards with nil name which results to zero
        if predicate == nil && oldRequest == nil {
            predicate = NSPredicate(format: "name = nil")
        }
        
        if let oldRequest = oldRequest {
            var predicates = [NSPredicate]()
            
            if let predicate = predicate {
                predicates.append(predicate)
            }
            if let predicate = oldRequest.predicate {
                predicates.append(predicate)
            }
            
            if predicates.count > 1 {
                predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
            } else {
                predicate = predicates.first
            }
        }
        
        newRequest.sortDescriptors = createSortDescriptors()
        
        let idPredicate = NSPredicate(format: "id != nil AND language.code = %@", "en")
        if let predicate = predicate {
            newRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate,
                                                                                       idPredicate])
        } else {
            newRequest.predicate = idPredicate
        }
        
//        print("\(newRequest)")
        return newRequest
    }
    
    func createSortDescriptors() -> [NSSortDescriptor]? {
        guard let orderBy = displayValue(for: .orderBy) as? Bool else {
            return nil
        }
        
        var sortDescriptors = [NSSortDescriptor]()
        if let sectionName = getSectionName() {
            sortDescriptors.append(NSSortDescriptor(key: sectionName, ascending: orderBy))
            sortDescriptors.append(NSSortDescriptor(key: "name", ascending: orderBy))
            sortDescriptors.append(NSSortDescriptor(key: "set.releaseDate", ascending: orderBy))
            sortDescriptors.append(NSSortDescriptor(key: "myNumberOrder", ascending: orderBy))
        } else {
            sortDescriptors.append(NSSortDescriptor(key: "myNumberOrder", ascending: orderBy))
            sortDescriptors.append(NSSortDescriptor(key: "name", ascending: orderBy))
            sortDescriptors.append(NSSortDescriptor(key: "set.releaseDate", ascending: orderBy))
        }
        
        
        return sortDescriptors
    }
    
    func createKeywordPredicate(query: String?) -> NSPredicate? {
        guard let searchKeywordName = searchValue(for: .keywordName) as? Bool,
            let searchKeywordText = searchValue(for: .keywordText) as? Bool,
            let searchKeywordFlavor = searchValue(for: .flavorText) as? Bool else {
            return nil
        }
        
        var predicate: NSPredicate?
        var subpredicates = [NSPredicate]()
        
        // process keyword filter
        if searchKeywordName {
            if let query = query {
                if query.count == 1 {
                    subpredicates.append(NSPredicate(format: "name BEGINSWITH[cd] %@", query))
                } else if query.count > 1{
                    subpredicates.append(NSPredicate(format: "name CONTAINS[cd] %@", query))
                }
            }
        }
        if searchKeywordText {
            if let query = query {
                if query.count == 1 {
                    subpredicates.append(NSPredicate(format: "text BEGINSWITH[cd] %@ OR originalText BEGINSWITH[cd] %@", query, query))
                } else if query.count > 1{
                    subpredicates.append(NSPredicate(format: "text CONTAINS[cd] %@ OR originalText CONTAINS[cd] %@", query, query))
                }
            }
        }
        if searchKeywordFlavor {
            if let query = query {
                if query.count == 1 {
                    subpredicates.append(NSPredicate(format: "flavor BEGINSWITH[cd] %@", query))
                } else if query.count > 1{
                    subpredicates.append(NSPredicate(format: "flavor CONTAINS[cd] %@", query))
                }
            }
        }
        
        if subpredicates.count > 1 {
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
        } else {
            predicate = subpredicates.first
        }
        
        return predicate
    }
    
    // TODO: use searchValue()
    func createManaCostPredicate() -> NSPredicate? {
        // TODO: double check X, Y, and Z manaCosts
        var predicate: NSPredicate?
        var subpredicates = [NSPredicate]()
        var arrayColors = [String]()
        
        // color filters
        var searchColorIdentityBlack = false
        var searchColorIdentityBlue = false
        var searchColorIdentityGreen = false
        var searchColorIdentityRed = false
        var searchColorIdentityWhite = false
        var searchColorIdentityColorless = false
        var searchColorIdentityBoolean = "or"
        var searchColorIdentityNot = false
        var searchColorIdentityMatch = "contains"
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityBlack") as? Bool {
            searchColorIdentityBlack = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityBlue") as? Bool {
            searchColorIdentityBlue = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityGreen") as? Bool {
            searchColorIdentityGreen = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityRed") as? Bool {
            searchColorIdentityRed = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityWhite") as? Bool {
            searchColorIdentityWhite = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityColorless") as? Bool {
            searchColorIdentityColorless = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityBoolean") as? String {
            searchColorIdentityBoolean = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityNot") as? Bool {
            searchColorIdentityNot = value
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchColorIdentityMatch") as? String {
            searchColorIdentityMatch = value
        }
        
        // process color filter
        if searchColorIdentityBlack {
            arrayColors.append("Black")
        }
        if searchColorIdentityBlue {
            arrayColors.append("Blue")
        }
        if searchColorIdentityGreen {
            arrayColors.append("Green")
        }
        if searchColorIdentityRed {
            arrayColors.append("Red")
        }
        if searchColorIdentityWhite {
            arrayColors.append("White")
        }
        if searchColorIdentityColorless {
            
        }
        
        if searchColorIdentityMatch == "contains" {
            subpredicates.append(NSPredicate(format: "ANY colorIdentities.name IN %@", arrayColors))
        } else {
            for color in arrayColors {
                subpredicates.append(NSPredicate(format: "ANY colorIdentities.name == %@", color))
            }
        }
        
        if subpredicates.count > 0 {
            if searchColorIdentityBoolean == "and" {
                let colorPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
                if predicate == nil {
                    predicate = colorPredicate
                } else {
                    predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate!, colorPredicate])
                }
            } else if searchColorIdentityBoolean == "or" {
                let colorPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
                if predicate == nil {
                    predicate = colorPredicate
                } else {
                    predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate!, colorPredicate])
                }
            }
            if searchColorIdentityNot {
                predicate = NSCompoundPredicate(notPredicateWithSubpredicate: predicate!)
            }
        }
        
        return predicate
    }
}
