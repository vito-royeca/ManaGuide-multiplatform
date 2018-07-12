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

class SearchRequestGenerator: NSObject {
    func defaultsValue() -> [String: Any] {
        var values = [String: Any]()
        
        // displayers
        if let value = UserDefaults.standard.value(forKey: "searchSectionName") as? String {
            values["searchSectionName"] = value
        } else {
            values["searchSectionName"] = "nameSection"
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchSortBy") as? String {
            values["searchSortBy"] = value
        } else {
            values["searchSortBy"] = "name"
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchSecondSortBy") as? String {
            values["searchSecondSortBy"] = value
        } else {
            values["searchSecondSortBy"] = "name"
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchOrderBy") as? Bool {
            values["searchOrderBy"] = value
        } else {
            values["searchOrderBy"] = true
        }
        
        if let value = UserDefaults.standard.value(forKey: "searchDisplayBy") as? String {
            values["searchDisplayBy"] = value
        } else {
            values["searchDisplayBy"] = "list"
        }
        //
        if let value = UserDefaults.standard.value(forKey: "searchKeywordName") as? Bool {
            values["searchKeywordName"] = value
        } else {
            values["searchKeywordName"] = true
        }
        if let value = UserDefaults.standard.value(forKey: "searchKeywordText") as? Bool {
            values["searchKeywordText"] = value
        } else {
            values["searchKeywordText"] = false
        }
        if let value = UserDefaults.standard.value(forKey: "searchKeywordFlavor") as? Bool {
            values["searchKeywordFlavor"] = value
        } else {
            values["searchKeywordFlavor"] = false
        }
        
        return values
    }
    
    func defaultValue(for key: String) -> Any? {
        let defaults = defaultsValue()
        return defaults[key]
    }
    
    func syncValues(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        
        var searchSectionName = defaultValue(for: "searchSectionName") as? String
        var searchSortBy = defaultValue(for: "searchSortBy") as? String
        var searchSecondSortBy = defaultValue(for: "searchSecondSortBy") as? String
        var searchOrderBy = defaultValue(for: "searchOrderBy") as? Bool
        var searchDisplayBy = defaultValue(for: "searchDisplayBy") as? String
        
        if let value = userInfo["searchSortBy"] as? String {
            searchSortBy = value
            
            switch searchSortBy {
            case "name":
                searchSectionName = "nameSection"
                searchSecondSortBy = "name"
            case "typeSection":
                searchSectionName = "typeSection"
                searchSecondSortBy = "name"
            default:
                ()
            }
        }
        
        if let value = userInfo["searchOrderBy"] as? Bool {
            searchOrderBy = value
        }
        
        if let value = userInfo["searchDisplayBy"] as? String {
            searchDisplayBy = value
        }
        
        UserDefaults.standard.set(searchSectionName, forKey: "searchSectionName")
        UserDefaults.standard.set(searchSortBy, forKey: "searchSortBy")
        UserDefaults.standard.set(searchSecondSortBy, forKey: "searchSecondSortBy")
        UserDefaults.standard.set(searchOrderBy, forKey: "searchOrderBy")
        UserDefaults.standard.set(searchDisplayBy, forKey: "searchDisplayBy")
        UserDefaults.standard.synchronize()
    }
    
    func createSearchRequest(query: String?, oldRequest: NSFetchRequest<NSFetchRequestResult>?) -> NSFetchRequest<NSFetchRequestResult>? {
        let newRequest = CMCard.fetchRequest()
        var predicate: NSPredicate?
        
        let defaults = defaultsValue()
        
        // displayers
        let searchSectionName = defaults["searchSectionName"] as! String
        let searchSecondSortBy = defaults["searchSecondSortBy"] as! String
        let searchOrderBy = defaults["searchOrderBy"] as! Bool
        
        if let kp = createKeywordPredicate(query: query) {
            predicate = kp
        }
        
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
            
            if predicates.count > 0 {
                predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
            }
        }
        
        print("\(predicate!)")
        newRequest.predicate = predicate
        newRequest.sortDescriptors = [NSSortDescriptor(key: searchSectionName, ascending: searchOrderBy),
                                      NSSortDescriptor(key: searchSecondSortBy, ascending: searchOrderBy),
                                      NSSortDescriptor(key: "set.releaseDate", ascending: searchOrderBy),
                                      NSSortDescriptor(key: "numberOrder", ascending: searchOrderBy)]
        
        return newRequest
    }
    
    func createKeywordPredicate(query: String?) -> NSPredicate? {
        let defaults = defaultsValue()
        var predicate: NSPredicate?
        var subpredicates = [NSPredicate]()
        
        // keyword filters
        let searchKeywordName = defaults["searchKeywordName"] as! Bool
        let searchKeywordText = defaults["searchKeywordText"] as! Bool
        let searchKeywordFlavor = defaults["searchKeywordFlavor"] as! Bool
        
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
            subpredicates.append(NSPredicate(format: "ANY colorIdentities_.name IN %@", arrayColors))
        } else {
            for color in arrayColors {
                subpredicates.append(NSPredicate(format: "ANY colorIdentities_.name == %@", color))
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
