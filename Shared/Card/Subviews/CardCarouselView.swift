//
//  CardCarouselView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/18/23.
//

import CoreData
import SwiftUI
import ManaKit
import SwiftUIPager

struct CardCarouselView: View {
    let viewModel: CardViewModel
    let height: CGFloat

    var body: some View {
        pagerView
            .onAppear {
                fetchRemoteData()
            }
    }
    
    private var pagerView: some View {
        Pager(page: Page.withIndex(viewModel.index),
              data: viewModel.cards) { card in
            if let cardObject = viewModel.find(MGCard.self,
                                               id: card) {
                CardImageRowView(card: cardObject)
            }
        }
            .onPageChanged({ pageNumber in
                let currentCard = viewModel.cards[pageNumber]
                  
                if let cardObject = viewModel.find(MGCard.self,
                                                     id: currentCard) {
                    viewModel.newID = cardObject.newIDCopy
                }
                fetchRemoteData()
            })
            .itemSpacing(5)
            .itemAspectRatio(0.8)
            .interactive(scale: 0.8)
            .pagingPriority(.high)
    }

    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchRemoteData()
            try await viewModel.fetchPreviousRemoteData()
            try await viewModel.fetchNextRemoteData()
        }
    }
}

#Preview {
    let model = CardViewModel(newID: "isd_en_51", relatedCards: [])
    Task {
        try await model.fetchRemoteData()
    }
    
    return CardCarouselView(viewModel: model,
                            height: 400)
}
