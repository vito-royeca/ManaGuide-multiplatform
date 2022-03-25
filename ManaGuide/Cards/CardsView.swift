//
//  CardsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import SwiftUI
import ManaKit

struct CardsView: View {
    @StateObject var viewModel: CardsViewModel
    
    @EnvironmentObject var cardsViewSettings: CardsViewSettings
    @State private var showingSort = false
    @State private var showingDisplay = false
    
    init(viewModel: CardsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            ForEach(viewModel.cards) { card in
                let newID = "\(card.set?.code ?? "")_\(card.language?.code ?? "")_\(card.collectorNumber ?? "")"
                CardRowView(card: card)
                    .background(NavigationLink("", destination: CardView(newID: newID)).opacity(0))
                    .listRowSeparator(.hidden)
            }
        }
            .listStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSort.toggle()
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                        .actionSheet(isPresented: $showingSort) {
                            ActionSheet(
                                title: Text("Sort by"),
                                buttons: [
                                    .default(Text("\(cardsViewSettings.sort == .castingCost ? "\u{2713}" : "") Casting Cost")) {
                                        cardsViewSettings.sort = .castingCost
                                    },
                                    .default(Text("\(cardsViewSettings.sort == .collectorNumber ? "\u{2713}" : "") Collector Number")) {
                                        cardsViewSettings.sort = .collectorNumber
                                    },
                                    .default(Text("\(cardsViewSettings.sort == .name ? "\u{2713}" : "") Name")) {
                                        cardsViewSettings.sort = .name
                                    }, 
                                    .default(Text("\(cardsViewSettings.sort == .rarity ? "\u{2713}" : "") Rarity")) {
                                        cardsViewSettings.sort = .rarity
                                    },
                                    .default(Text("\(cardsViewSettings.sort == .setName ? "\u{2713}" : "") Set Name")) {
                                        cardsViewSettings.sort = .setName
                                    },
                                    .default(Text("\(cardsViewSettings.sort == .setReleaseDate ? "\u{2713}" : "") Set Release Date")) {
                                        cardsViewSettings.sort = .setReleaseDate
                                    },
                                    .default(Text("\(cardsViewSettings.sort == .type ? "\u{2713}" : "") Type")) {
                                        cardsViewSettings.sort = .type
                                    },
                                    .cancel(Text("Cancel"))
                                ]
                            )
                        }

                    Button(action: {
                        showingDisplay.toggle()
                    }) {
                        Image(systemName: "eyeglasses")
                    }
                    .actionSheet(isPresented: $showingDisplay) {
                        ActionSheet(
                            title: Text("Display by"),
                            buttons: [
                                .default(Text("\(cardsViewSettings.display == .image ? "\u{2713}" : "") Image")) {
                                    cardsViewSettings.display = .image
                                },
                                .default(Text("\(cardsViewSettings.display == .list ? "\u{2713}" : "") List")) {
                                    cardsViewSettings.display = .list
                                },
                                .default(Text("\(cardsViewSettings.display == .summary ? "\u{2713}" : "") Summary")) {
                                    cardsViewSettings.display = .summary
                                },
                                .cancel(Text("Cancel"))
                            ]
                        )
                    }
                }
            }
            .overlay(
                Group {
                    if viewModel.isBusy {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        EmptyView()
                    }
                })
            .onAppear {
                viewModel.fetchData()
            }
    }
}

struct CardsView_Previews: PreviewProvider {
    static var previews: some View {
        let cardsViewSettings = CardsViewSettings()
        
        NavigationView {
            CardsView(viewModel: SetViewModel(setCode: "ice", languageCode: "en"))
        }
            .environmentObject(cardsViewSettings)
    }
}
