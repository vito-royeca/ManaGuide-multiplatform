//
//  ManaGuidePhoto.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 10/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import IDMPhotoBrowser
import ManaKit
import PromiseKit

class ManaGuidePhoto : NSObject, IDMPhotoProtocol {
    var card: CMCard?
    @objc var progressUpdateBlock: IDMProgressUpdateBlock?
    
    private var _underlyingImage: UIImage?
    
    init(withCard card: CMCard) {
        self.card = card
    }
    
    func underlyingImage() -> UIImage? {
        return _underlyingImage
    }
    
    func loadUnderlyingImageAndNotify() {
        guard let card = card else {
            return
        }
        
        firstly {
            ManaKit.sharedInstance.downloadImage(ofCard: card,
                                                 imageType: .normal,
                                                 faceOrder: 0)
        }.done {
            self._underlyingImage = ManaKit.sharedInstance.cardImage(card,
                                                                     imageType: .normal,
                                                                     faceOrder: 0,
                                                                     roundCornered: true)
            self.imageLoadingComplete()
        }.catch { error in
            self.unloadUnderlyingImage()
            self.imageLoadingComplete()
        }
    }
    
    func unloadUnderlyingImage() {
        _underlyingImage = nil
    }
    
    func placeholderImage() -> UIImage? {
        guard let card = card else {
            return nil
        }
        
        return ManaKit.sharedInstance.cardBack(card)
    }
    
    func caption() -> String? {
        return nil
    }
    
    func imageLoadingComplete() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION),
                                        object: self)
    }
}

