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
    @Published var isFailed = false

    // MARK: - Constants
    
    let feedSource = [
        "MTG Goldfish": "https://www.mtggoldfish.com/feed.rss",
//        "WotC": "https://magic.wizards.com/en/rss/rss.xml",
        "MTGAzone": "https://mtgazone.com/feed/",
//        "ChannelFireBall": "https://strategy.channelfireball.com/all-strategy/feed/",
        "HotC": "https://www.hipstersofthecoast.com/feed/",
        "Pure MTGO": "https://puremtgo.com/rss.xml",
        "FacetoFace": "https://magic.facetofacegames.com/feed/",
        "Quiet Speculation": "https://www.quietspeculation.com/feed/",
        "EDHREC": "https://edhrec.com/articles//feed",
        "Card Kingdom Blog": "https://blog.cardkingdom.com/feed/",
        "SCG": "https://articles.starcitygames.com/feed/",
        "Draftism": "https://draftsim.com//feed",
    ]
    let maxFeeds = 20
    var lastUpdated: Date?
    
    func fetchData() {
        guard !isBusy, willFetchNews() else {
            return
        }
        
        isBusy.toggle()
        isFailed = false

        let group = DispatchGroup()
        var newFeeds = [FeedItem]()
        var failed = false
        
        for (_, value) in feedSource {
            if let url = URL(string: value) {
                let parser = FeedParser(URL: url)
                
                group.enter()
                parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
                    switch result {
                    case .success(let feed):
                        switch feed {
                        case let .atom(feed):
                            newFeeds.append(contentsOf: feed.feedItems())
                        case let .rss(feed):
                            newFeeds.append(contentsOf: feed.feedItems())
                        case let .json(feed):
                            newFeeds.append(contentsOf: feed.feedItems())
                        }
                    case .failure(let error):
                        failed = true
                        print(error)
                    }
                    
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            let date = Date()
            newFeeds = newFeeds.sorted(by: { ($0.datePublished ?? date) > ($1.datePublished ?? date) })
            newFeeds = newFeeds.count >= self.maxFeeds ? newFeeds.dropLast(newFeeds.count - self.maxFeeds) : newFeeds
            
            self.lastUpdated = Date()
            self.feeds = newFeeds
            self.isBusy.toggle()
            self.isFailed = failed
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

