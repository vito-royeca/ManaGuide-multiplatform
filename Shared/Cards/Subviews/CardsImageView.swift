//
//  CardsImageView.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 11/19/23.
//

import SwiftUI
import ManaKit

struct CardsImageView: View {
    @EnvironmentObject var viewModel: CardsViewModel
    @Binding var selectedCard: MGCard?
    @Binding var cardsPerRow: Double

    var body: some View {
        let cardWidth = (UIScreen.main.bounds.size.width - 60 ) * cardsPerRow
        
        let columns = [
            GridItem(.adaptive(minimum: cardWidth))
        ]
        
        return LazyVGrid(columns: columns,
                         spacing: 20,
                         pinnedViews: [.sectionHeaders]) {
            ForEach(viewModel.sections, id: \.name) { section in
                Section(header: HStack {
                    Text(section.name)
                    Spacer()
                }) {
                    ForEach(section.objects as? [MGCard] ?? [], id: \.newIDCopy) { card in
                        VStack {
                            CardImageRowView(card: card,
                                             showPrice: true)
                        }
                        .onTapGesture {
                            select(card: card)
                        }
                    }
                }
            }
        }
    }
    
    private func select(card: MGCard) {
        selectedCard = card
    }
}

#Preview {
    let model = CardsViewModel()
    
    return CardsImageView(selectedCard: .constant(nil),
                          cardsPerRow: .constant(0.5))
        .environmentObject(model)
}
