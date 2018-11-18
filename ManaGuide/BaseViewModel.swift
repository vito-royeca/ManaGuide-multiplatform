//
//  BaseViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 18/11/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit

enum ViewModelMode: Int {
    case standBy
    case loading
    case noResultsFound
    case resultsFound
    case error
    
    var cardArt: [String: String]? {
        switch self {
        case .standBy:
            return ["setCode": "leb",
                    "name": "Library of Leng"]
        case .loading:
            return ["setCode": "vma",
                    "name": "Frantic Search"]
        case .noResultsFound:
            return ["setCode": "a25",
                    "name": "Azusa, Lost but Seeking"]
        case .resultsFound:
            return nil
        case .error:
            return ["setCode": "plc",
                    "name": "Dismal Failure"]
        }
    }
    
    var description : String? {
        switch self {
        // Use Internationalization, as appropriate.
        case .standBy: return "Ready"
        case .loading: return "Loading..."
        case .noResultsFound: return "No data found"
        case .resultsFound: return nil
        case .error: return "nil"
        }
    }
}

class BaseViewModel: NSObject {
    var mode: ViewModelMode = .loading
    
    
}
