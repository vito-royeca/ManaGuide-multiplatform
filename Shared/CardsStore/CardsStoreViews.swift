//
//  CardsStoreViews.swift
//  ManaGuide
//
//  Created by Vito Royeca on 5/5/22.
//

import CoreData
import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct CardsStoreHeaderView: View {
    private let set: MGSet
    private let viewModel: SetViewModel

    init(set: MGSet, viewModel: SetViewModel) {
        self.set = set
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let logoImage = set.logoImage {
                Image(uiImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
            }
            SetRowView(set: set)
            SetLanguagesView(set: set, viewModel: viewModel)
        }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
    }
}

struct CardsStoreFeatureView: View {
    private let font: ManaKit.Font
    private let card: MGCard
    
    init(card: MGCard) {
        self.card = card
        font = card.nameFont
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(card.displayName ?? "")
                .font(Font.custom(font.name, size: font.size))
                .lineLimit(1)
            HStack {
                Text(card.displayKeyrune)
                    .font(Font.custom("Keyrune", size: 20))
                    .foregroundColor(Color(card.keyruneColor))
                Text("\u{2022} #\(card.collectorNumber ?? "") \u{2022} \(card.rarity?.name ?? "") \u{2022} \(card.language?.displayCode ?? "")")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
            WebImage(url: card.imageURL(for: .artCrop))
                .resizable()
                .placeholder(Image(uiImage: ManaKit.shared.image(name: .cropBack)!))
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 200, alignment: .center)
                .cornerRadius(16)
                .clipped()
            Spacer()
            CardsStorePriceView(card: card)
        }
    }
}

struct CardsStoreLargeView: View {
    private let font: ManaKit.Font
    private let card: MGCard

    init(card: MGCard) {
        self.card = card
        font = card.nameFont
    }
    
    var body: some View {
        HStack(alignment: .top) {
            WebImage(url: card.imageURL(for: .artCrop))
                .resizable()
                .placeholder(Image(uiImage: ManaKit.shared.image(name: .cropBack)!))
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80, alignment: .center)
                .cornerRadius(16)
                .clipped()
            VStack(alignment: .leading) {
                Text(card.displayName ?? "")
                    .font(Font.custom(font.name, size: font.size))
                HStack {
                    Text(card.displayKeyrune)
                        .font(Font.custom("Keyrune", size: 20))
                        .foregroundColor(Color(card.keyruneColor))
                    Text("\u{2022} #\(card.collectorNumber ?? "") \u{2022} \(card.rarity?.name ?? "") \u{2022} \(card.language?.displayCode ?? "")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CardsStorePriceView(card: card)
            }
            Spacer()
        }
    }
}

struct CardsStoreCompactView: View {
    private let font: ManaKit.Font
    private let card: MGCard
    
    init(card: MGCard) {
        self.card = card
        font = card.nameFont
    }
    
    var body: some View {
        HStack(alignment: .center) {
            WebImage(url: card.imageURL(for: .artCrop))
                .resizable()
                .placeholder(Image(uiImage: ManaKit.shared.image(name: .cropBack)!))
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60, alignment: .center)
                .cornerRadius(16)
                .clipped()
            VStack(alignment: .leading) {
                Text(card.displayName ?? "")
                    .font(Font.custom(font.name, size: font.size))
                    .lineLimit(1)
                HStack {
                    Text(card.displayKeyrune)
                        .font(Font.custom("Keyrune", size: 20))
                        .foregroundColor(Color(card.keyruneColor))
                    Text("\u{2022} #\(card.collectorNumber ?? "") \u{2022} \(card.rarity?.name ?? "") \u{2022} \(card.language?.displayCode ?? "")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CardsStorePriceView(card: card)
            }
            Spacer()
        }
    }
}

struct CardsStorePriceView: View {
    let card: MGCard
    
    var body: some View {
        HStack {
            Text("Normal")
                .font(.footnote)
                .foregroundColor(Color.blue)
            Spacer()
            Text(card.displayNormalPrice)
                .font(.footnote)
                .foregroundColor(Color.blue)
                .multilineTextAlignment(.trailing)
            Spacer()
            Text("Foil")
                .font(.footnote)
                .foregroundColor(Color.green)
            Spacer()
            Text(card.displayFoilPrice)
                .font(.footnote)
                .foregroundColor(Color.green)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct NumberView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CardViewModel(newID: "isd_en_51", relatedCards: [])
        
        Group {
            if let card = viewModel.card {
                CardsStoreFeatureView(card: card)
                    .previewLayout(.fixed(width: 400, height: 300))

                CardsStoreLargeView(card: card)
                    .previewLayout(.fixed(width: 400, height: 125))

                CardsStoreCompactView(card: card)
                    .previewLayout(.fixed(width: 400, height: 83))
            } else {
                Text("Loading...")
            }
        }
            .onAppear {
                viewModel.fetchRemoteData()
            }
    }
}
