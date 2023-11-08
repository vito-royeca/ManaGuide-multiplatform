//
//  CardViewItemSource.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import UIKit
import LinkPresentation
import ManaKit

class CardViewItemSource: NSObject, UIActivityItemSource {
    let card: MGCard
    
    init(card: MGCard) {
        self.card = card
        super.init()
        
        // MARK: FIXME
//        if let url = card.imageURL(for: .artCrop),
//           SDImageCache.shared.imageFromCache(forKey: url.absoluteString) == nil {
//            SDWebImageDownloader.shared.downloadImage(with: url)
//        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return card.displayName ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // MARK: FIXME
//        guard let url = card.imageURL(for: .png),
//           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) else {
//            return nil
//        }
//
//        return image
        
        return nil
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return card.displayName ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                thumbnailImageForActivityType activityType: UIActivity.ActivityType?,
                                suggestedSize size: CGSize) -> UIImage? {
        // MARK: FIXME
//        guard let url = card.imageURL(for: .artCrop),
//           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) else {
//            return nil
//        }
//
//        return image
        return nil
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        
        // MARK: FIXME
//        if let url = card.imageURL(for: .artCrop),
//           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) {
//            metadata.iconProvider = NSItemProvider(object: image)
//        }
        metadata.title = card.displayName ?? ""
        
        return metadata
    }
}
