//
//  CardsMenuView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import SwiftUI

struct CardsMenuView: View {
    @EnvironmentObject private var viewModel: CardsViewModel
    @AppStorage("CardsViewSort") private var cardsSort = CardsViewSort.defaultValue
    @AppStorage("CardsRarityFilter") private var cardsRarityFilter: String?
    @AppStorage("CardsTypeFilter") private var cardsTypeFilter: String?
    @AppStorage("CardsViewDisplay") private var cardsDisplay = CardsViewDisplay.defaultValue
    
    var includeFilters = true

    var body: some View {
        Menu {
            sortByMenu
            if includeFilters {
                rarityFilterMenu
                typeFilterMenu
            }
            viewAsMenu
            clearMenu
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .onAppear {
            fetchRemoteData()
        }
    }
    
    private var sortByMenu: some View {
        Menu {
            ForEach(CardsViewSort.allCases, id:\.description) { sort in
                Button(action: {
                    cardsSort = sort
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort,
                                                    object: cardsSort)
                }) {
                    if cardsSort == sort {
                        Label(cardsSort.description,
                              systemImage: "checkmark")
                    } else {
                        Text(sort.description)
                    }
                }
            }
        } label: {
            Label("Sort by\n\(cardsSort.description)",
                  systemImage: "arrow.up.arrow.down")
        }
    }

    private var rarityFilterMenu: some View {
        Menu {
            Button(action: {
                cardsRarityFilter = nil
                NotificationCenter.default.post(name: NSNotification.CardsViewRarityFilter,
                                                object: cardsRarityFilter)
            }) {
                if cardsRarityFilter == nil {
                    Label(String.emdash,
                          systemImage: "checkmark")
                } else {
                    Text(String.emdash)
                }
            }

            ForEach(viewModel.rarities, id: \.name) { rarity in
                Button(action: {
                    cardsRarityFilter = rarity.name
                    NotificationCenter.default.post(name: NSNotification.CardsViewRarityFilter,
                                                    object: cardsRarityFilter)
                }) {
                    if cardsRarityFilter == rarity.name {
                        Label("\(cardsRarityFilter ?? String.emdash)",
                              systemImage: "checkmark")
                    } else {
                        Text("\(rarity.name ?? String.emdash)")
                    }
                }
            }
        } label: {
            Label("Filter by Rarity\n\(cardsRarityFilter ?? String.emdash)",
                  systemImage: "doc.text.magnifyingglass")
        }
    }

    private var typeFilterMenu: some View {
        Menu {
            Button(action: {
                cardsTypeFilter = nil
                NotificationCenter.default.post(name: NSNotification.CardsViewTypeFilter,
                                                object: nil)
            }) {
                if cardsTypeFilter == nil {
                    Label(String.emdash,
                          systemImage: "checkmark")
                } else {
                    Text(String.emdash)
                }
            }
            
            ForEach(viewModel.cardTypes, id: \.name) { cardType in
                Button(action: {
                    cardsTypeFilter = cardType.name
                    NotificationCenter.default.post(name: NSNotification.CardsViewTypeFilter,
                                                    object: cardsTypeFilter)
                }) {
                    if cardsTypeFilter == cardType.name {
                        Label("\(cardsTypeFilter ?? String.emdash)",
                              systemImage: "checkmark")
                    } else {
                        Text("\(cardType.name ?? String.emdash)")
                    }
                }
            }
        } label: {
            Label("Filter by Type\n\(cardsTypeFilter ?? String.emdash)",
                  systemImage: "doc.text.magnifyingglass")
        }
    }

    private var viewAsMenu: some View {
        Menu {
            ForEach(CardsViewDisplay.allCases, id:\.description) { display in
                Button(action: {
                    cardsDisplay = display
                    NotificationCenter.default.post(name: NSNotification.CardsViewDisplay,
                                                    object: cardsDisplay)
                }) {
                    if cardsDisplay == display {
                        Label(cardsDisplay.description,
                              systemImage: "checkmark")
                    } else {
                        Text(display.description)
                    }
                }
            }
        } label: {
            Label("View as\n\(cardsDisplay.description)",
                  systemImage: "eye")
        }
    }
    
    private var clearMenu: some View {
        Button(action: {
            cardsSort = CardsViewSort.defaultValue
            cardsRarityFilter = nil
            cardsTypeFilter = nil
            cardsDisplay = CardsViewDisplay.defaultValue
            NotificationCenter.default.post(name: NSNotification.CardsViewClear,
                                            object: nil)
        }) {
            Label("Reset to defaults",
                  systemImage: "clear")
        }
    }
    
    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchOtherData()
        }
    }
}


#Preview {
    let viewModel = CardsViewModel()

    return CardsMenuView()
        .environmentObject(viewModel)
}
