//
//  NewsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/30/22.
//

import SwiftUI
import BetterSafariView
import FeedKit

struct NewsView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @StateObject var viewModel = NewsViewModel()
    @State private var currentFeed: FeedItem? = nil
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    viewModel.fetchData()
                }
            } else {
                #if os(iOS)
                if horizontalSizeClass == .compact {
                    compactView
                } else {
                    regularView
                }
                #else
                regularView
                #endif
            }
        }
            .onAppear {
                viewModel.fetchData()
            }
    }

    func safariView(with url: URL) -> SafariView {
        let config = SafariView.Configuration(entersReaderIfAvailable: true,
                                              barCollapsingEnabled: true)
        return SafariView(url: url,
                          configuration: config)
            .preferredBarAccentColor(.clear)
            .preferredControlAccentColor(.accentColor)
            .dismissButtonStyle(.close)
    }
    
    var compactView: some View {
        List {
            ForEach(viewModel.feeds, id:\.id) { feed in
                let tap = TapGesture()
                    .onEnded { _ in
                        currentFeed = feed
                    }
                
                NewsFeedRowView(item: feed)
                    .gesture(tap)
                    .listRowSeparator(.hidden)
                    .padding(.bottom)
                
            }
        }
            .listStyle(.plain)
            .safariView(item: $currentFeed) { currentFeed in
                let config = SafariView.Configuration(entersReaderIfAvailable: false,
                                                      barCollapsingEnabled: true)
                return SafariView(url: URL(string: currentFeed.url ?? "")!,
                                  configuration: config)
                    .preferredBarAccentColor(.clear)
//                    .preferredControlAccentColor(.accentColor)
                    .dismissButtonStyle(.close)
            }
            .navigationBarTitle("News")
    }
    
    var regularView: some View {
        ScrollView() {
            LazyVGrid(columns: [GridItem](repeating: GridItem(.flexible()),
                                          count: 2),
                      pinnedViews: []) {
                ForEach(viewModel.feeds, id:\.id) { feed in
                    let tap = TapGesture()
                        .onEnded { _ in
                            currentFeed = feed
                        }

                    NewsFeedRowView(item: feed)
                        .frame(height: 200)
                        .padding()
                        .gesture(tap)
                }
            }
                .safariView(item: $currentFeed) { currentFeed in
                    let config = SafariView.Configuration(entersReaderIfAvailable: false,
                                                          barCollapsingEnabled: true)
                    return SafariView(url: URL(string: currentFeed.url ?? "")!,
                               configuration: config)
                        .preferredBarAccentColor(.clear)
//                        .preferredControlAccentColor(.accentColor)
                        .dismissButtonStyle(.close)
                }
                .padding()
                .navigationBarTitle("News")
        }
    }
}

// MARK: - Previous

#Preview {
    return NavigationView {
        NewsView()
    }
}
