//
//  SetView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit
import ScalingHeaderScrollView

struct SetView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("CardsViewSort") private var cardsSort = CardsViewSort.defaultValue
    @AppStorage("CardsRarityFilter") private var cardsRarityFilter: String?
    @AppStorage("CardsTypeFilter") private var cardsTypeFilter: String?
    @AppStorage("CardsViewDisplay") private var cardsDisplay = CardsViewDisplay.defaultValue

    @StateObject var viewModel: SetViewModel
    @State private var progress: CGFloat = 0
    @State private var showingSort = false
    @State private var selectedCard: MGCard?
    @State private var cardsPerRow = 0.5

    init(setCode: String, languageCode: String) {
        _viewModel = StateObject(wrappedValue: SetViewModel(setCode: setCode,
                                                            languageCode: languageCode))
    }
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    fetchRemoteData()
                }
            } else {
                ZStack {
                    scalingHeaderView
                    topButtons
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            updateCardsPerRow()
            fetchRemoteData()
        }
    }
    
    // MARK: - Private variables

    private var scalingHeaderView: some View {
        ScalingHeaderScrollView {
            ZStack {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
                SetHeaderView(viewModel: viewModel,
                              progress: $progress)
                    .padding(.top, 80)
            }
        } content: {
            if cardsDisplay == .image {
                imageContentView
                    .padding(.horizontal, 10)
            } else if cardsDisplay == .list {
                listContentView
                    .padding(.horizontal, 10)
            }
        }
        .collapseProgress($progress)
        .allowsHeaderCollapse()
        .height(min: 160,
                max: 320)
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
        .sheet(item: $selectedCard) { card in
            NavigationView {
                CardView(newID: card.newIDCopy,
                         relatedCards: viewModel.cards,
                         withCloseButton: true)
            }
        }
    }

    private var imageContentView: some View {
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

    private var listContentView: some View {
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
                }
            }
        }
    }

    private var topButtons: some View {
        VStack {
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                }
                    .padding(.top, 50)
                    .padding(.leading, 17)
                    .foregroundColor(.accentColor)
                Spacer()
                CardsMenuView()
                    .environmentObject(viewModel as CardsViewModel)
                    .padding(.top, 50)
                    .padding(.trailing, 17)
                    .foregroundColor(.accentColor)
            }
            Spacer()
        }
        .ignoresSafeArea()
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

    private func select(card: MGCard) {
        selectedCard = card
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

// MARK: - Previews

#Preview {
    NavigationView {
        SetView(setCode: "ugl", languageCode: "en")
    }
        .previewInterfaceOrientation(.landscapeLeft)
}

