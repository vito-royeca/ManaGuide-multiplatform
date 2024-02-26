//
//  CardLanguagesView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 2/20/24.
//

import SwiftUI
import ManaKit

struct CardLanguagesView: View {
    @State private var selectedCard: MGCard?
    
    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        contentView
    }
    
    var contentView: some View {
        let otherLanguages = card.sortedOtherLanguages ?? []

        return List {
            ForEach(otherLanguages) { otherLanguage in
                CardsStoreLargeView(card: otherLanguage)
                    .onTapGesture {
                        selectedCard = otherLanguage
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

