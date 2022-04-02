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
    @StateObject var viewModel = NewsViewModel()
    @State private var currentFeed: FeedItem? = nil
    
    init() {
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }

    var body: some View {
        List {
            ForEach(viewModel.feeds, id:\.id) { feed in
                let tap = TapGesture()
                    .onEnded { _ in
                        currentFeed = feed
                    }
                
                NewsFeedRowView(item: feed)
                    .listRowSeparator(.hidden)
                    .gesture(tap)
            }
        }
            .sheet(item: $currentFeed, content: { currentFeed in
                if let url = URL(string: currentFeed.url ?? "") {
                    SafariView(
                        url: url,
                        configuration: SafariView.Configuration(
                            entersReaderIfAvailable: true,
                            barCollapsingEnabled: true
                        )
                    )
                }
            })
            .listStyle(.plain)
            .navigationTitle("News")
            .overlay(
                Group {
                    if viewModel.isBusy {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        EmptyView()
                    }
                })
            .onAppear {
                viewModel.fetchData()
            }
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

// MARK: - Item View

struct NewsFeedRowView: View {
    var item: FeedItem
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 20) {
                    if let link = item.image,
                       let url = URL(string: link) {
                        WebImage(url: url)
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100, alignment: .center)
                            .cornerRadius(10)
                            .clipped()
                    } else {
                        EmptyView()
                    }
                
                    VStack(alignment: .leading) {
                        HStack {
                            if let link = item.channelImage,
                               let url = URL(string: link) {
                                WebImage(url: url)
                                    .resizable()
                                    .indicator(.activity)
                                    .transition(.fade(duration: 0.5))
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30, alignment: .center)
                                    .clipped()
                            } else {
                                EmptyView()
                            }
                            Text(item.channel ?? "")
                                .font(.subheadline)
                        }
                        Spacer()
                        Text(item.title ?? "")
                            .font(.headline)
                        Spacer()
                    }
                }
                    .padding(10)
                
                Divider()
                    .background(Color.secondary)
                
                HStack {
                    let authorString = item.author != nil ? " \u{2022} \(item.author ?? "")" : ""
                    Text("\(item.datePublishedString ?? "")\(authorString)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
//                    Button(action: {
//                        print("button pressed")
//                    }) {
//                        Image(systemName: "ellipsis")
//                            .renderingMode(.original)
//                            .foregroundColor(Color(.systemBlue))
//                    }
//                        .buttonStyle(PlainButtonStyle())
                }
                    .padding(5)
            }
        }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary, lineWidth: 1)
            )
    }
}

