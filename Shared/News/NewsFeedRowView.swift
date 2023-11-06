//
//  NewsFeedRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/24/22.
//

import SwiftUI
import BetterSafariView

struct NewsFeedRowView: View {
    var item: FeedItem
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 20) {
                    CacheAsyncImage(url: URL(string: item.image ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        } else {
                            EmptyView()
                        }
                    }
                    .frame(width: 100,
                           height: 100)
                
                    VStack(alignment: .leading) {
                        HStack {
                            CacheAsyncImage(url: URL(string: item.channelImage ?? "")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipped()
                                } else {
                                    EmptyView()
                                }
                            }
                            .frame(width: 30,
                                   height: 30)
                            
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
                    Text("\(item.datePublished?.elapsedTime() ?? "")\(authorString)")
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
            Spacer()
        }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary, lineWidth: 1)
            )
    }
}

//struct NewsFeedRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewsFeedRowView()
//    }
//}
