//
//  Notifications+Names.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/14/23.
//

import Foundation

extension NSNotification {
    static let CardsViewSort = Notification.Name.init("CardsViewSort")
    static let CardsViewRarityFilter = Notification.Name.init("CardsViewRArityFilter")
    static let CardsViewTypeFilter = Notification.Name.init("CardsViewTypeFilter")
    static let CardsViewDisplay = Notification.Name.init("CardsViewDisplay")
    static let CardsViewClear = Notification.Name.init("CardsViewClear")
    static let SetsViewSort = Notification.Name.init("SetsViewSort")
    static let SetsViewTypeFilter = Notification.Name.init("SetsViewTypeFilter")
    static let SetsViewClear = Notification.Name.init("SetsViewClear")
}
