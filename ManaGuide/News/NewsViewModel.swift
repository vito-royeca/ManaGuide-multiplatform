//
//  NewsViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/30/22.
//

import Foundation
import FeedKit

class NewsViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Variables

    @Published var feeds = [FeedItem]()
    @Published var isBusy = false

    // MARK: - Constants
    
    let feedSource = [
        "MTG Goldfish": "https://www.mtggoldfish.com/feed.rss",
        "WotC": "https://magic.wizards.com/en/rss/rss.xml",
        "MTGAzone": "https://mtgazone.com/feed/",
        "ChannelFireBall": "https://strategy.channelfireball.com/all-strategy/feed/",
        "HotC": "https://www.hipstersofthecoast.com/feed/",
        "Pure MTGO": "https://puremtgo.com/rss.xml",
        "FacetoFace": "https://magic.facetofacegames.com/feed/",
        "Quiet Speculation": "https://www.quietspeculation.com/feed/",
        "EDHREC": "https://edhrec.com/articles//feed",
        "Card Kingdom Blog": "https://blog.cardkingdom.com/feed/",
        "SCG": "https://articles.starcitygames.com/feed/",
        "Draftism": "https://draftsim.com//feed"
    ]
    let maxFeeds = 20
    var lastUpdated: Date?
    
    func fetchData() {
        guard !isBusy, willFetchNews() else {
            return
        }
        
        isBusy.toggle()
        
        let group = DispatchGroup()
        let date = Date()
        var newFeeds = [FeedItem]()
        
        for (_, value) in feedSource {
            if let url = URL(string: value) {
                group.enter()
            
                let parser = FeedParser(URL: url)
                parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
                    group.leave()
                    
                    switch result {
                    case .success(let feed):
                        switch feed {
                        case let .atom(feed):
                            newFeeds.append(contentsOf: feed.feedItems().sorted(by: { ($0.datePublished ?? date) > ($1.datePublished ?? date) }))
                        case let .rss(feed):
                            newFeeds.append(contentsOf: feed.feedItems().sorted(by: { ($0.datePublished ?? date) > ($1.datePublished ?? date) }))
                        case let .json(feed):
                            newFeeds.append(contentsOf: feed.feedItems().sorted(by: { ($0.datePublished ?? date) > ($1.datePublished ?? date) }))
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            newFeeds = newFeeds.sorted(by: { ($0.datePublished ?? date) > ($1.datePublished ?? date) })
            newFeeds = newFeeds.count >= self.maxFeeds ? Array(newFeeds.prefix(upTo: self.maxFeeds)) : newFeeds
            
    //        print(date)
    //        for feed in limitedFeeds {
    //            print("\(newFeed.datePublished ?? Date()): \(newFeed.datePublishedString ?? "")")
    //        }

            self.lastUpdated = Date()
            self.feeds = newFeeds
            self.isBusy.toggle()
        })
    }
    
    func willFetchNews() -> Bool {
        var willFetch = true

        if let lastUpdated = lastUpdated {
            // 5 minutes
            if let diff = Calendar.current.dateComponents([.minute],
                                                          from: lastUpdated,
                                                          to: Date()).minute {
                willFetch = diff >= Constants.cacheAge
            }
        } else {
            lastUpdated = Date()
        }
        
        return willFetch
    }
}

