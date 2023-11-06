//
//  CardListRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/25/22.
//

import SwiftUI
import ManaKit

struct CardListRowView: View {
    private let font: ManaKit.Font
    private let card: MGCard
    
    init(card: MGCard) {
        self.card = card
        font = card.nameFont
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(spacing: 20) {
                    AsyncImage(url: card.imageURL(for: .artCrop)) { phase in
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
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                    VStack(alignment: .leading) {
                        Text(card.displayName ?? "")
                            .font(Font.custom(font.name,
                                              size: font.size))
                        Spacer()
                        HStack {
                            Text(card.displayKeyrune)
                                .font(Font.custom("Keyrune", size: 20))
                                .foregroundColor(Color(card.keyruneColor))
                            Text("\u{2022} #\(card.collectorNumber ?? "") \u{2022} \(card.rarity?.name ?? "") \u{2022} \(card.language?.displayCode ?? "")")
                                .font(.footnote)
                                .foregroundColor(Color.gray)
                            Spacer()
                            // TODO: implement in the future
//                            Button(action: {
//                                print("button pressed")
//                            }) {
//                                Image(systemName: "ellipsis")
//                                    .renderingMode(.original)
//                                    .foregroundColor(Color(.systemBlue))
//                            }
//                                .buttonStyle(PlainButtonStyle())
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    let model = CardViewModel(newID: "isd_en_51",
                              relatedCards: [])
    model.fetchRemoteData()
    
    return List {
        if let card = model.cardObject {
            CardListRowView(card: card)
        } else {
            Text("Loading...")
        }
    }
}
