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
    case sectionName
    case sortBy
    case secondSortBy
    case orderBy
    case displayBy
    case keywordName
    case keywordText
    case flavorText
    
    var description : String {
        switch self {
        case .sectionName: return "searchSectionName"
        case .sortBy: return "searchSortBy"
        case .secondSortBy: return "searchSecondSortBy"
        case .orderBy: return "searchOrderBy"
        case .displayBy: return "searchDisplayBy"
        case .keywordName: return "searchKeywordName"
        case .keywordText: return "searchKeywordText"
        case .flavorText: return "searchFlavorText"
        }
    }
}

class SearchRequestGenerator: NSObject {
    override init() {
        super.init()
    }
    
    func searchValue(for key: SearchKey) -> Any? {
        var searchValue: Any?
        
        switch key {
        case .sectionName:
            if let value = UserDefaults.standard.value(forKey: key.description) as? String {
                searchValue = value
            } else {
                searchValue = "nameSection"
            }
        case .sortBy:
            if let value = UserDefaults.standard.value(forKey: key.description) as? String {
                searchValue = value
            } else {
                searchValue = "name"
            }
        case .secondSortBy:
            if let value = UserDefaults.standard.value(forKey: key.description) as? String {
                searchValue = value
            } else {
                searchValue = "name"
            }
        case .orderBy:
            if let value = UserDefaults.standard.value(forKey: key.description) as? Bool {
                searchValue = value
            } else {
                searchValue = true
            }
        case .displayBy:
            if let value = UserDefaults.standard.value(forKey: key.description) as? String {
                searchValue = value
            } else {
                searchValue = "list"
            }
        case .keywordName:
            if let value = UserDefaults.standard.value(forKey: key.description) as? Bool {
                searchValue = value
            } else {
                searchValue = true
            }
        case .keywordText:
            if let value = UserDefaults.standard.value(forKey: key.description) as? Bool {
                searchValue = value
            } else {
                searchValue = false
            }
        case .flavorText:
            if let value = UserDefaults.standard.value(forKey: key.description) as? Bool {
                searchValue = value
            } else {
                searchValue = false
            }
        }
        
        return searchValue
    }
    
    func syncValues(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        
        for (k,v) in userInfo {
            if k == SearchKey.sortBy.description {
                guard let string = v as? String else {
                    continue
                }
                
                switch string {
                case "name",
                     "numberOrder":
                    UserDefaults.standard.set("nameSection", forKey: SearchKey.sectionName.description)
                default:
                    UserDefaults.standard.set(string, forKey: SearchKey.sectionName.description)
                }
                
                UserDefaults.standard.set("name", forKey: SearchKey.secondSortBy.description)
                UserDefaults.standard.set(v, forKey: k)
            } else {
                UserDefaults.standard.set(v, forKey: k)
            }
        }
        UserDefaults.standard.synchronize()
    }
    
    func createSearchRequest(query: String?, oldRequest: NSFetchRequest<NSFetchRequestResult>?) -> NSFetchRequest<NSFetchRequestResult>? {
        guard let searchOrderBy = searchValue(for: .orderBy) as? Bool,
            let searchSectionName = searchValue(for: .sectionName) as? String,
            let searchSecondSortBy = searchValue(for: .secondSortBy) as? String else {
            return nil
        }
        
        let newRequest = CMCard.fetchRequest()
        var predicate: NSPredicate?
        
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
