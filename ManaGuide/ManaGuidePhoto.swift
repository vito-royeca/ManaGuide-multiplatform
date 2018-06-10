//
//  ManaGuidePhoto.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 10/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import IDMPhotoBrowser
import ManaKit
import PromiseKit

class ManaGuidePhoto: NSObject, IDMPhotoProtocol {
    var card: CMCard?
    var image: UIImage?
    var progressUpdateBlock: IDMProgressUpdateBlock?

    init(card: CMCard) {
        self.card = card
    }
    
    func underlyingImage() -> UIImage? {
        image = ManaKit.sharedInstance.cardImage(card!, imageType: .normal)
        return image
    }
    
    func loadUnderlyingImageAndNotify() {
        firstly {
            ManaKit.sharedInstance.downloadImage(ofCard: card!, imageType: .normal)
        }.done { (image: UIImage?) in
            self.image = image
            self.imageLoadingComplete()
        }.catch { error in
            self.unloadUnderlyingImage()
            self.imageLoadingComplete()
        }
    }
    
    func unloadUnderlyingImage() {
        image = nil
    }
    
    func placeholderImage() -> UIImage? {
        return ManaKit.sharedInstance.cardBack(card!)
    }
    
    func imageLoadingComplete() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION), object: self)
    }

}
