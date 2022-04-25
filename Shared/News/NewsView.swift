//
//  NewsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/30/22.
//

import SwiftUI
import BetterSafariView
import FeedKit
import SDWebImageSwiftUI

struct NewsView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @StateObject var viewModel = NewsViewModel()
    @State private var currentFeed: FeedItem? = nil
    @State private var showingSafariView = false
    
    init() {
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    viewModel.fetchData()
                }
            } else {
                bodyData
            }
        }
            .onAppear {
                viewModel.fetchData()
            }
    }

    var bodyData: some View {
        List {
            ForEach(viewModel.feeds, id:\.id) { feed in
                if let url = URL(string: feed.url ?? "") {
                    let tap = TapGesture()
                        .onEnded { _ in
                            showingSafariView.toggle()
                        }
                    
                    NewsFeedRowView(item: feed)
                        .safariView(isPresented: $showingSafariView) {
                            SafariView(
                                url: url,
                                configuration: SafariView.Configuration(
                                    entersReaderIfAvailable: true,
                                    barCollapsingEnabled: true
                                )
                            )
                        }
                        .gesture(tap)
                        .listRowSeparator(.hidden)
                        .padding(.bottom)
                }
            }
        }
            .listStyle(.plain)
            .navigationTitle("News")
    }
}

// MARK: - Previous

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NewsView()
        }
    }
}
