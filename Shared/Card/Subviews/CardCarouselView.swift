//
//  CardCarouselView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/18/23.
//

import SwiftUI
import ManaKit
import SwiftUIPager

struct CardCarouselView: View {
    let viewModel: CardViewModel
    let height: CGFloat

    var body: some View {
        if let card = viewModel.card {
            Pager(page: Page.withIndex(viewModel.relatedCards.firstIndex(of: card) ?? 0),
                  data: viewModel.relatedCards.isEmpty ? [card] : viewModel.relatedCards) { card in
                if let cardObject = viewModel.find(MGCard.self,
                                                   id: card) {
                    CardImageRowView(card: cardObject)
                }
            }
                  .onPageChanged({ pageNumber in
                      let currentCard = viewModel.relatedCards[pageNumber]
                      
                      if let cardObject = viewModel.find(MGCard.self,
                                                         id: currentCard) {
                          viewModel.newID = cardObject.newIDCopy
                          fetchRemoteData()
                      }
                  })
                  .itemSpacing(0.9)
                  .itemAspectRatio(0.9)
                  .interactive(scale: 0.9)
                  .pagingPriority(.high)
                  .frame(height: height)
        } else {
            EmptyView()
        }
    }
    
    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchRemoteData()
        }
    }
}

#Preview {
    let model = CardViewModel(newID: "isd_en_54", relatedCards: [])

    return CardCarouselView(viewModel: model,
                            height: 200)
}
