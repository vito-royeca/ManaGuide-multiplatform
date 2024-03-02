//
//  CardComponentPartsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 2/20/24.
//

import SwiftUI
import ManaKit

struct CardComponentPartsView: View {
    @State private var selectedCard: MGCard?

    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        contentView
    }
    
    var contentView: some View {
        let componentParts = card.sectionedComponentParts
        
        return List {
            ForEach(Array(componentParts.keys), id: \.self) { key in
                Section(key) {
                    ForEach(componentParts[key] ?? []) { componentPart in
                        if let part = componentPart.part {
                            CardsStoreLargeView(card: part)
                                .onTapGesture {
                                    selectedCard = componentPart.part
                                }
                        }
                    }
                    
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
