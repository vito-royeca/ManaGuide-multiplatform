//
//  SetRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/1/22.
//

import SwiftUI
import ManaKit

enum SetRowViewStyle {
    case header, listRow
}

struct SetRowView: View {
    @ObservedObject var set: MGSet
    let style: SetRowViewStyle

    var body: some View {
        if style == .listRow {
            listRowView
        } else if style == .header {
            headerView
        }
    }
    
    private var listRowView: some View {
        HStack(alignment: .center, spacing: 10) {
            if let url = set.smallLogoURL {
                CacheAsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                    } else {
                        EmptyView()
                    }
                }
                .frame(width: 100, height: 50)
            } else {
                Image(uiImage: ManaKit.sharedCoreData.image(name: .mtgLogo)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 50)
            }

            VStack(alignment: .leading) {
                Text(set.name ?? "")
                    .font(.subheadline)
                infoView
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .center) {
            if let url = set.bigLogoURL {
                CacheAsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                    } else {
                        EmptyView()
                    }
                }
                .frame(maxHeight: 100)
            } else {
                Image(uiImage: ManaKit.sharedCoreData.image(name: .mtgLogo)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 100)
            }

            HStack {
                Text(set.name ?? "")
                    .font(.title3)
                Spacer()
            }

            detailedInfoView
        }
    }

    private var infoView: some View {
        HStack {
            Text(set.keyrune2Unicode)
                .font(Font.custom("Keyrune", size: 20))
            Text((set.code).uppercased())
                .font(.subheadline)
                .foregroundColor(Color.gray)
            Spacer()
            Text("\(set.cardCount) cards")
                .font(.subheadline)
                .foregroundColor(Color.gray)
        }
    }

    private var detailedInfoView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Type")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                Text(set.setType?.name ?? "")
                    .font(.subheadline)
                Spacer()
                Text("Block")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                Text(set.setBlock?.name ?? String.emdash)
                    .font(.subheadline)
            }

            HStack {
                VStack {
                    Text("Symbol")
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                    Text(set.keyrune2Unicode)
                        .font(Font.custom("Keyrune", size: 20))
                }
                Spacer()
                VStack {
                    Text("Code")
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                    Text((set.code).uppercased())
                        .font(.subheadline)
                }
                Spacer()
                VStack {
                    Text("Release Date")
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                    Text(set.displayReleaseDate ?? "")
                        .font(.subheadline)
                }
                Spacer()
                VStack {
                    Text("Cards")
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                    Text("\(set.cardCount)")
                        .font(.subheadline)
                }
            }
        }
    }
}

#Preview {
    let viewModel = SetViewModel(setCode: "lea",
                                 languageCode: "en")
    Task {
        try await viewModel.fetchRemoteData()
    }
    
    return VStack {
        if let set = viewModel.setObject {
            SetRowView(set: set,
                       style: .header)
        } else {
            Text("Loading...")
        }
    }
}
