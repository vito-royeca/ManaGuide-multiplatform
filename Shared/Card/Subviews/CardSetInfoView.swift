//
//  CardSetInfoView.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 2/26/24.
//

import SwiftUI
import ManaKit

struct CardSetInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    var card: MGCard
    private let cmcFormatter = NumberFormatter()

    init(card: MGCard) {
        self.card = card
        
        cmcFormatter.minimumFractionDigits = 0
        cmcFormatter.maximumFractionDigits = 2
        cmcFormatter.numberStyle = .decimal
    }

    var body: some View {
        
        LabeledContent {
            Text(card.set?.name ?? String.emdash)
        } label: {
            Text("Set")
        }
        
        LabeledContent {
            Text(card.displayKeyrune)
                .scaledToFit()
                .font(Font.custom("Keyrune", size: 20))
                .foregroundColor(Color(card.keyruneColor))
        } label: {
            Text("Set Symbol")
        }
        
        LabeledContent {
            Text(card.rarity?.name ?? String.emdash)
        } label: {
            Text("Rarity")
        }
        
        LabeledContent {
            Text(cmcFormatter.string(from: card.cmc as NSNumber) ?? " ")
        } label: {
            Text("Converted Mana Cost")
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
        return CardSetInfoView(card: card)
    } else {
        return Text("Loading...")
    }
}
