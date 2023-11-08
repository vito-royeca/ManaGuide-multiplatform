//
//  CardsStoreSeeAllView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 5/11/22.
//

import CoreData
import SwiftUI
import ManaKit

struct CardsStoreSeeAllView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var selectedCard: NSManagedObjectID? = nil
    let title: String
    let cards: [NSManagedObjectID]
    let viewModel = ViewModel()
    
    var body: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            compactView
        } else {
            regularView
        }
        #else
        regularView
        #endif
    }
    
    var compactView: some View {
        List {
            ForEach(cards) { card in
                let tap = TapGesture()
                    .onEnded { _ in
                        self.selectedCard = card
                    }

                if let card = viewModel.find(MGCard.self,
                                             id: card) {
                    CardsStoreLargeView(card: card)
                        .gesture(tap)
                }
            }
        }
            .listStyle(.plain)
            .sheet(item: $selectedCard) { selectedCard in
                NavigationView {
                    if let card = viewModel.find(MGCard.self,
                                                 id: selectedCard) {
                        CardView(newID: card.newIDCopy,
                                 relatedCards: cards,
                                 withCloseButton: true)
                    } else {
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(title)
    }
    
    var regularView: some View {
        ScrollView() {
            LazyVGrid(columns: [GridItem](repeating: GridItem(),
                                          count: 3),
                      spacing: 10,
                      pinnedViews: []) {
                ForEach(cards) { card in
                    let tap = TapGesture()
                        .onEnded { _ in
                            self.selectedCard = card
                        }
                    
                    if let card = viewModel.find(MGCard.self,
                                                 id: card) {
                        CardsStoreLargeView(card: card)
                            .gesture(tap)
                    }
                }
            }
                .padding()
                .sheet(item: $selectedCard) { selectedCard in
                    NavigationView {
                        if let card = viewModel.find(MGCard.self,
                                                     id: selectedCard) {
                            CardView(newID: card.newIDCopy,
                                     relatedCards: cards,
                                     withCloseButton: true)
                        } else {
                            EmptyView()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle(title)
        }
    }
}



#Preview {
    let model = CardsSearchViewModel()

    Task {
        
        model.query = "lion"
        model.scopeSelection = 0
        try await model.fetchRemoteData()
    }

    return NavigationView {
        CardsStoreSeeAllView(title: "title",
                             cards: [] /*model.data*/)
    }
}
