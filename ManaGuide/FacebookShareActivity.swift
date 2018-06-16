//
//  FacebookShareActivity.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 16/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKShareKit

class FacebookShareActivity: UIActivity {
    private var parentViewController: UIViewController?
    
    fileprivate lazy var shareDialog: FBSDKShareDialog = {
        let dialog = FBSDKShareDialog()
        dialog.delegate = self
        dialog.fromViewController = self.parentViewController
        dialog.mode = .native
        
        return dialog
    }()
    
    open static var category: UIActivityCategory?
    
    init(parent: UIViewController?) {
        super.init()
        
        parentViewController = parent
    }
    
    open override class var activityCategory : UIActivityCategory {
        return category ?? .share
    }
    open class func setActivityCategory(_ category: UIActivityCategory) {
        self.category = category
    }
    
    open override var activityType : UIActivityType? {
        return UIActivityType(String(describing: FacebookShareActivity.self))
    }
    
    open override var activityTitle : String? {
        return "Facebook Share"
    }
    
    open override var activityImage : UIImage? {
        return UIImage(named: "\(activityType!.rawValue)\(FacebookShareActivity.activityCategory.rawValue)", in: Bundle(for: FacebookShareActivity.self), compatibleWith: nil)
    }
    
    open override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        var canPerform = true
        
        for item in activityItems {
            if let image = item as? UIImage {
                let photo = FBSDKSharePhoto()
                photo.image = image
                photo.isUserGenerated = true
                
                let content = FBSDKSharePhotoContent()
                content.photos = [photo]
                
                self.shareDialog.shareContent = content
                
            } else {
                canPerform = false
                break
            }
        }
        
        if canPerform {
            do {
                try shareDialog.validate()
                canPerform = shareDialog.canShow()
            } catch {
                canPerform = false
            }
        }
        
        return canPerform
    }
    
    open override func perform() {
        shareDialog.show()
    }
}

// MARK: FBSDKSharingDelegate
extension FacebookShareActivity : FBSDKSharingDelegate {
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable : Any]!) {
        
    }
    
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        
    }
    
    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        
    }
    
    
}

