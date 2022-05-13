//
//  CardsStoreSeeAllView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 5/11/22.
//

import SwiftUI
import ManaKit

struct CardsStoreSeeAllView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var selectedCard: MGCard? = nil
    let title: String
    let cards: [MGCard]
    
    var body: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            compactListView
        } else {
            listView
        }
        #else
        listView
        #endif
    }
    
    var compactListView: some View {
        List {
            ForEach(cards) { card in
                let tap = TapGesture()
                    .onEnded { _ in
                        self.selectedCard = card
                    }

                CardsStoreLargeView(card: card)
                    .gesture(tap)
            }
        }
            .listStyle(.plain)
            .sheet(item: $selectedCard) { selectedCard in
                NavigationView {
                    CardView(newID: selectedCard.newIDCopy)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(title)
    }
    
    var listView: some View {
        ScrollView() {
            LazyVGrid(columns: [GridItem](repeating: GridItem(), count: 3), spacing: 10, pinnedViews: []) {
                ForEach(cards) { card in
                    let tap = TapGesture()
                        .onEnded { _ in
                            self.selectedCard = card
                        }
                    CardsStoreLargeView(card: card)
                        .gesture(tap)

                }
            }
                .padding()
                .sheet(item: $selectedCard) { selectedCard in
                    NavigationView {
                        CardView(newID: selectedCard.newIDCopy)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle(title)
        }
    }
}



struct CardsStoreSeeAllView_Previews: PreviewProvider {
    static var previews: some View {
        CardsStoreSeeAllView(title: "title", cards: [])
    }
}
