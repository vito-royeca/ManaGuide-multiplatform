//
//  CardVariationsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 2/20/24.
//

import SwiftUI
import ManaKit

struct CardVariationsView: View {
    @State private var selectedCard: MGCard?

    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        contentView
    }
    
    var contentView: some View {
        let variations = card.sortedVariations ?? []

        return List {
            ForEach(variations) { variation in
                CardsStoreLargeView(card: variation)
                    .onTapGesture {
                        selectedCard = card
                    }
            }
        }
        .sheet(item: $selectedCard) { card in
            NavigationView {
                CardView(newID: card.newIDCopy,
                         relatedCards: [],
                         withCloseButton: true)
            }
        }
    }
}
