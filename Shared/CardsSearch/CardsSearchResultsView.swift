//
//  CardsSearchResultsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/25/23.
//

import SwiftUI
import ManaKit

struct CardsSearchResultsView: View {
    @EnvironmentObject var viewModel: CardsSearchViewModel
    @State private var selectedCard: MGCard?
    
    var body: some View {
        contentView
    }
    
    private var contentView: some View {
        ZStack {
            if viewModel.cards.isEmpty {
                EmptyResultView()
            } else {
                List {
                    CardsView(selectedCard: $selectedCard)
                        .environmentObject(viewModel as CardsViewModel)
                }
                .listStyle(.plain)
                .modifier(SectionIndex(sections: viewModel.sections,
                                       sectionIndexTitles: viewModel.sectionIndexTitles))
            }
        }
        .sheet(item: $selectedCard) { card in
            NavigationView {
                CardView(newID: card.newIDCopy,
                         relatedCards: viewModel.cards,
                         withCloseButton: true)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                CardsMenuView(includeFilters: false)
                    .environmentObject(viewModel as CardsViewModel)
            }
        }
        .navigationBarTitle("\(viewModel.cards.count) result\(viewModel.cards.count > 1 ? "s" : "")")
    }
}

#Preview {
    let viewModel = CardsSearchViewModel()

    return CardsSearchResultsView()
        .environmentObject(viewModel)
}
