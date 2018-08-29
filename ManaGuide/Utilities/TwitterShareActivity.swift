//
//  TwitterShareActivity.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 16/06/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import TwitterKit
import TwitterCore

class TwitterShareActivity: UIActivity {
    private var parentViewController: UIViewController?
    var photo: UIImage?
    
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
        return UIActivityType(String(describing: TwitterShareActivity.self))
    }
    
    open override var activityTitle : String? {
        return "Twitter Sharing"
    }
    
    open override var activityImage : UIImage? {
        return UIImage(named: "\(activityType!.rawValue)\(TwitterShareActivity.activityCategory.rawValue)",
                       in: Bundle(for: TwitterShareActivity.self),
                       compatibleWith: nil)
    }
    
    open override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        var canPerform = true
        
        for item in activityItems {
            if let image = item as? UIImage {
                photo = image
                
            } else {
                canPerform = false
                break
            }
        }
        
        return canPerform
    }
    
    open override func perform() {
        if let parentViewController = parentViewController {
            let composer = TWTRComposer()
            
            composer.setImage(photo)
            composer.show(from: parentViewController)
        }
    }
    
    open override func activityDidFinish(_ completed: Bool) {
        print("completed = \(completed)")
    }
}



