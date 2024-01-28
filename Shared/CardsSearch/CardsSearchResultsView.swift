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
    @AppStorage("CardsViewDisplay") private var cardsDisplay = CardsViewDisplay.defaultValue

    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    fetchRemoteData()
                } cancelAction: {
                    viewModel.isFailed = false
                }
            } else {
                contentView
            }
        }
        .onAppear {
            fetchRemoteData()
        }
    }
    
    private var contentView: some View {
        ZStack {
            if viewModel.cards.isEmpty {
                EmptyResultView()
            } else {
                if cardsDisplay == .list {
                    listWithModifierView
                } else if cardsDisplay == .image {
                    listView
                }
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

    private var listView: some View {
        List {
            CardsView(selectedCard: $selectedCard)
                .environmentObject(viewModel as CardsViewModel)
        }
        .listStyle(.plain)
    }

    private var listWithModifierView: some View {
        List {
            CardsView(selectedCard: $selectedCard)
                .environmentObject(viewModel as CardsViewModel)
        }
        .listStyle(.plain)
        .modifier(SectionIndex(sections: viewModel.sections,
                               sectionIndexTitles: viewModel.sectionIndexTitles))
    }
    
    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchRemoteData()
        }
    }
}

#Preview {
    let viewModel = CardsSearchViewModel()

    return CardsSearchResultsView()
        .environmentObject(viewModel)
}
