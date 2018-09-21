//
//  AccountViewModel.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 14.09.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import CoreData
import Firebase
import ManaKit
import PromiseKit

class AccountViewModel: NSObject {
    private var _userRef: DatabaseReference?
    
    // MARK: Data monitors
    func monitorUser() {
        if let user = Auth.auth().currentUser {
            _userRef = Database.database().reference().child("users").child(user.uid)
            
            _userRef!.observe(.value, with: { snapshot in
                if let value = snapshot.value as? [String : Any] {
                    if let dict = value["favorites"] as? [String : Any] {
//                        self.favoriteMIDs = self.cardMIDs(withIds: Array(dict.keys))
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.FavoriteToggled),
                                                        object: nil,
                                                        userInfo: nil)
                    }
                    
                    if let dict = value["ratedCards"] as? [String : Any] {
//                        self.ratedCardMIDs = self.cardMIDs(withIds: Array(dict.keys))
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKeys.CardRatingUpdated),
                                                        object: nil,
                                                        userInfo: nil)
                    }
                }
            })
        }
    }
    
    func demonitorUser() {
        if let userRef = _userRef {
            userRef.removeAllObservers()
        }
        
        _userRef = nil
    }
}
