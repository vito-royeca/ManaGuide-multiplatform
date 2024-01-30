//
//  CardsListView.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 11/19/23.
//

import SwiftUI
import ManaKit

struct CardsListView: View {
    @EnvironmentObject var viewModel: CardsViewModel
    @Binding var selectedCard: MGCard?

    var body: some View {
        ForEach(viewModel.sections, id: \.name) { section in
            Section(header: HStack {
                Text(section.name)
                Spacer()
            }) {
                ForEach(section.objects as? [MGCard] ?? [], id: \.newIDCopy) { card in
                    CardsStoreLargeView(card: card)
                        .padding(.bottom, 10)
                        .onTapGesture {
                            select(card: card)
                        }
                        .listRowSeparator(.hidden)
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
    
    return CardsListView(selectedCard: .constant(nil))
        .environmentObject(model)
}
