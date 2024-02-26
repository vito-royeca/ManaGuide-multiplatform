//
//  CardOtherPrintingsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 2/20/24.
//

import SwiftUI
import ManaKit

struct CardOtherPrintingsView: View {
    @State private var selectedCard: MGCard?
    
    var card: MGCard

    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        contentView
    }
    
    var contentView: some View {
        let otherPrintings = card.sortedOtherPrintings ?? []
        let firstTen = otherPrintings.count >= 10 ?
            Array(otherPrintings[0...9]) : otherPrintings

        return List {
            ForEach(otherPrintings) { otherPrinting in
                CardsStoreLargeView(card: otherPrinting)
                    .onTapGesture {
                        selectedCard = card
                    }
            }
            if firstTen.count >= 10 {
                NavigationLink {
                    CardAllOtherPrintingsView(newID: card.newIDCopy,
                                              languageCode: card.language?.code ?? "en")
                } label: {
                    Text("See all")
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
