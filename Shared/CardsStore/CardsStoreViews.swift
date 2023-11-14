//
//  CardsStoreViews.swift
//  ManaGuide
//
//  Created by Vito Royeca on 5/5/22.
//

import CoreData
import SwiftUI
import ManaKit

struct CardsStoreHeaderView: View {
    @ObservedObject var viewModel: SetViewModel

    var body: some View {
        VStack(spacing: 10) {
            if let set = viewModel.setObject {
                SetRowView(set: set,
                           style: .header)
            }
        }
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
                .font(Font.custom(font.name,
                                  size: font.size))
                .lineLimit(1)
            HStack {
                Text(card.displayKeyrune)
                    .font(Font.custom("Keyrune",
                                      size: 20))
                    .foregroundColor(Color(card.keyruneColor))
                Text("\u{2022} #\(card.collectorNumber ?? "") \u{2022} \(card.rarity?.name ?? "") \u{2022} \(card.language?.displayCode ?? "")")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
//            WebImage(url: card.imageURL(for: .artCrop))
//                .resizable()
//                .placeholder(Image(uiImage: ManaKit.shared.image(name: .cropBack)!))
//                .indicator(.activity)
//                .transition(.fade(duration: 0.5))
//                .aspectRatio(contentMode: .fill)
//                .frame(width: 280,
//                       height: 200,
//                       alignment: .center)
//                .cornerRadius(16)
//                .clipped()
            CacheAsyncImage(url: card.imageURL(for: .artCrop)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    Image(uiImage: ManaKit.shared.image(name: .cropBack)!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                }
            }
            .frame(width: 280,
                   height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
            CardsStorePriceView(card: card)
        }
    }
}

struct CardsStoreLargeView: View {
    @State var card: MGCard
    
    var body: some View {
        HStack(alignment: .top) {
            CacheAsyncImage(url: card.imageURL(for: .artCrop)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    Image(uiImage: ManaKit.shared.image(name: .cropBack)!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                }
            }
            .frame(width: 80,
                   height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading) {
                ZStack {
                    HStack {
                        let font = card.nameFont
                        Text(card.displayName ?? "")
                            .font(Font.custom(font.name, size: font.size))
                        Spacer()
                    }
                    
                    // FIXME: Abnormal number of gesture recognizer dependencies: 100. System performance may be affected. Please investigate reducing gesture recognizers and/or their dependencies.
//                    AttributedText(
//                        NSAttributedString(symbol: card.displayManaCost,
//                                           pointSize: 16)
//                    )
//                        .multilineTextAlignment(.trailing)
                }
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
            CacheAsyncImage(url: card.imageURL(for: .artCrop)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    Image(uiImage: ManaKit.shared.image(name: .cropBack)!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                }
            }
            .frame(width: 60,
                   height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 16))

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

// MARK: - Previews
#Preview {
    let viewModel = CardViewModel(newID: "isd_en_176", relatedCards: [])
    Task {
        try await viewModel.fetchRemoteData()
    }

    return Group {
        if let card = viewModel.card,
           let cardObject = viewModel.find(MGCard.self, id: card) {
            CardsStoreFeatureView(card: cardObject)
                .previewLayout(.fixed(width: 400,
                                      height: 300))

            CardsStoreLargeView(card: cardObject)
                .previewLayout(.fixed(width: 400,
                                      height: 125))

            CardsStoreCompactView(card: cardObject)
                .previewLayout(.fixed(width: 400,
                                      height: 83))
        } else {
            Text("Card not found")
        }
    }
}
