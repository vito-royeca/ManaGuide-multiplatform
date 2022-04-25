//
//  NewsFeedRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/24/22.
//

import SwiftUI
import BetterSafariView
import SDWebImageSwiftUI

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

//struct NewsFeedRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewsFeedRowView()
//    }
//}
