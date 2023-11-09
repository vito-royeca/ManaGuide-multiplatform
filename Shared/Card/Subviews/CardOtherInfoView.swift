//
//  CardOtherInfoView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import SwiftUI
import ManaKit

struct CardOtherInfoView: View {
    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        Group {
            CardTextRowView(title: card.set?.name ?? " ", subtitle: "Set")
            
            HStack {
                Text("Set Symbol")
//                    .font(.headline)
                Spacer()
                Text(card.displayKeyrune)
                    .scaledToFit()
                    .font(Font.custom("Keyrune", size: 20))
                    .foregroundColor(Color(card.keyruneColor))
            }
            
            CardTextRowView(title: card.rarity?.name ?? " ", subtitle: "Rarity")
            
            CardTextRowView(title: "#\(card.collectorNumber ?? " ")", subtitle: "Collector Number")
            
            CardTextRowView(title: card.artist?.name ?? " ", subtitle: "Artist")
            
            if let frame = card.frame {
                CardTextRowView(title: frame.name ?? " ", subtitle: "Frame")
            }

            if let language = card.language {
                CardTextRowView(title: language.name ?? " ", subtitle: "Language")
            }
            
            if let layout = card.layout {
                CardTextRowView(title: layout.name ?? " ", subtitle: "Layout")
            }

            if let releaseDate = card.displayReleaseDate {
                CardTextRowView(title: releaseDate, subtitle: "Release Date")
            }
            
            if let watermark = card.watermark {
                CardTextRowView(title: watermark.name ?? " ", subtitle: "Watermark")
            }
        }
    }
}

#Preview {
    let model = CardViewModel(newID: "isd_en_51",
                              relatedCards: [])
    Task {
        try await model.fetchRemoteData()
    }
    
    if let card = model.cardObject {
        return CardOtherInfoView(card: card)
    } else {
        return Text("Loading...")
    }
}
