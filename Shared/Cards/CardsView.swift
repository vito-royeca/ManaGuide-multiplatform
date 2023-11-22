//
//  CardsView.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 11/19/23.
//

import SwiftUI
import ManaKit

struct CardsView: View {
    @EnvironmentObject var viewModel: CardsViewModel
    @Binding var selectedCard: MGCard?

    @AppStorage("CardsViewSort") private var cardsSort = CardsViewSort.defaultValue
    @AppStorage("CardsRarityFilter") private var cardsRarityFilter: String?
    @AppStorage("CardsTypeFilter") private var cardsTypeFilter: String?
    @AppStorage("CardsViewDisplay") private var cardsDisplay = CardsViewDisplay.defaultValue
    @State private var cardsPerRow = 0.5

    var body: some View {
        VStack {
            if cardsDisplay == .image {
                CardsImageView(selectedCard: $selectedCard,
                               cardsPerRow: $cardsPerRow)
                .environmentObject(viewModel)
                .padding(.horizontal, 10)
            } else if cardsDisplay == .list {
                CardsListView(selectedCard: $selectedCard)
                    .environmentObject(viewModel)
                    .padding(.horizontal, 10)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewSort)) { output in
            sortBy(sorter: output.object as? CardsViewSort ?? CardsViewSort.defaultValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewRarityFilter)) { output in
            filterBy(rarity: output.object as? String ?? nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewTypeFilter)) { output in
            filterBy(type: output.object as? String ?? nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewClear)) { _ in
            resetToDefaults()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateCardsPerRow()
        }
        .onAppear {
            updateCardsPerRow()
        }
    }

    // MARK: - Private methods

    private func fetchRemoteData() {
        Task {
            viewModel.sort = cardsSort
            viewModel.rarityFilter = cardsRarityFilter
            viewModel.typeFilter = cardsTypeFilter
            try await viewModel.fetchRemoteData()
        }
    }

    private func sortBy(sorter: CardsViewSort) {
        cardsSort = sorter
        viewModel.sort = sorter
        viewModel.fetchLocalData()
    }

    private func filterBy(rarity: String?) {
        cardsRarityFilter = rarity
        viewModel.rarityFilter = rarity
        viewModel.fetchLocalData()
    }

    private func filterBy(type: String?) {
        cardsTypeFilter = type
        viewModel.typeFilter = type
        viewModel.fetchLocalData()
    }

    private func resetToDefaults() {
        viewModel.sort = cardsSort
        viewModel.rarityFilter = cardsRarityFilter
        viewModel.typeFilter = cardsTypeFilter
        viewModel.display = cardsDisplay
        viewModel.fetchLocalData()
    }

    private func updateCardsPerRow() {
        cardsPerRow = UIDevice.current.orientation == .portrait ? 0.5 : 0.4
    }
}

#Preview {
    let model = CardsViewModel()
    
    return CardsView(selectedCard: .constant(nil))
        .environmentObject(model)
}
