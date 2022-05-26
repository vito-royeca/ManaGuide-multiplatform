//
//  NewsMap.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/30/22.
//

import Foundation
import FeedKit
import Kanna

struct FeedItem: Identifiable {
    let formatter = DateFormatter()
    
    var channel: String?
    var channelImage: String?
    
    var id: String?
     
    var url: String?

    var title: String?

    var contentText: String?
    
    var contentHtml: String?
    
    var summary: String?
    
    var image: String?
    
    var datePublished: Date?
    
    var author: String?
    
    func parseImage(from html: String) -> String? {
        do {
            let doc = try Kanna.HTML(html: html, encoding: .utf8)
            for img in doc.xpath("//img") {
                return img["src"]
            }
                
        } catch {
            print(error)
        }
        
        return nil
    }
}

//struct FeedAuthor {
//
//    public var name: String?
//
//    public var url: String?
//
//    public var avatar: String?
//}

extension RSSFeed {
    func feedItems() -> [FeedItem] {
        var newItems = [FeedItem]()
        
        for item in items ?? [] {
            var newItem = FeedItem()
            
            newItem.channel = title
            newItem.channelImage = image?.url
            newItem.id = item.guid?.value ?? "\(item.title ?? "")_\(item.link ?? "")"
            newItem.url = (item.link?.hasPrefix("http") ?? false) ? item.link : "\(link ?? "")\(item.link ?? "")"
            newItem.title = item.title
            newItem.contentText = item.description
            newItem.contentHtml = nil
            newItem.summary = item.description
            newItem.image = newItem.parseImage(from: item.description ?? "") ?? item.media?.mediaThumbnails?.first?.attributes?.url
            newItem.datePublished = item.pubDate
            newItem.author = item.author ?? item.dublinCore?.dcCreator
            
            newItems.append(newItem)
        }
        return newItems
    }
}

extension JSONFeed {
    func feedItems() -> [FeedItem] {
        var newItems = [FeedItem]()
        
        for item in items ?? [] {
            var newItem = FeedItem()
            
            newItem.channel = title
            newItem.channelImage = icon
            newItem.id = item.id
            newItem.url = item.url
            newItem.title = item.title
            newItem.contentText = item.contentText
            newItem.contentHtml = item.contentHtml
            newItem.summary = item.summary
            newItem.image = item.image
            newItem.datePublished = item.datePublished
            newItem.author = item.author?.name
            
            newItems.append(newItem)
        }
        return newItems
    }
}

extension AtomFeed {
    func feedItems() -> [FeedItem] {
        var newItems = [FeedItem]()
        
        for entry in entries ?? [] {
            var newItem = FeedItem()
            
            newItem.channel = title
            newItem.channelImage = icon
            newItem.id = entry.id
            newItem.url = entry.links?.first?.attributes?.href
            newItem.title = entry.title
            newItem.contentText = nil
            newItem.contentHtml = nil
            newItem.summary = entry.summary?.value
            newItem.image = entry.media?.mediaThumbnails?.first?.attributes?.url
            newItem.datePublished = entry.published
            newItem.author = entry.authors?.first?.name
            
            newItems.append(newItem)
        }
        return newItems
    }
}
