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
    
    fileprivate lazy var shareDialog: ShareDialog = {
        let dialog = ShareDialog()
        dialog.delegate = self
        dialog.fromViewController = self.parentViewController
        dialog.mode = .automatic
        
        return dialog
    }()
    
    public static var category: UIActivity.Category?
    
    init(parent: UIViewController?) {
        super.init()
        
        parentViewController = parent
    }
    
    open override class var activityCategory : UIActivity.Category {
        return category ?? .share
    }
    open class func setActivityCategory(_ category: UIActivity.Category) {
        self.category = category
    }
    
    open override var activityType : UIActivity.ActivityType? {
        return UIActivity.ActivityType(String(describing: FacebookShareActivity.self))
    }
    
    open override var activityTitle : String? {
        return "Facebook Sharing"
    }
    
    open override var activityImage : UIImage? {
        return UIImage(named: "\(activityType!.rawValue)\(FacebookShareActivity.activityCategory.rawValue)",
                       in: Bundle(for: FacebookShareActivity.self),
                       compatibleWith: nil)
    }
    
    open override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        var canPerform = true
        
        for item in activityItems {
            if let image = item as? UIImage {
                let photo = SharePhoto()
                photo.image = image
                photo.isUserGenerated = true
                
                let content = SharePhotoContent()
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
                canPerform = shareDialog.canShow
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
extension FacebookShareActivity : SharingDelegate {
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        
    }
    
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        
    }
    
    func sharerDidCancel(_ sharer: Sharing) {
        
    }
}

