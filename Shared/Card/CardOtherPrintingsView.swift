//
//  CardOtherPrintingsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/5/23.
//

import SwiftUI
import ManaKit

struct CardOtherPrintingsView: View {
    @AppStorage("cardsSort") private var sort = CardsViewSort.name
    @StateObject var viewModel: CardOtherPrintingsViewModel
    @State private var showingSort = false
    @State private var selectedCard: MGCard?
    
    init(newID: String, languageCode: String) {
        _viewModel = StateObject(wrappedValue: CardOtherPrintingsViewModel(newID: newID,
                                                                           languageCode: languageCode))
    }

    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    viewModel.fetchRemoteData()
                }
            } else {
                listView
            }
        }
        .onAppear {
            viewModel.sort = sort
            viewModel.fetchRemoteData()
        }
    }
    
    var listView: some View {
        List {
            ForEach(viewModel.data) { card in
                if let card = viewModel.find(MGCard.self,
                                             id: card) {
                    CardsStoreLargeView(card: card)
                        .onTapGesture {
                            selectedCard = card
                        }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsStoreViewSort)) { (output) in
            viewModel.fetchLocalData()
        }
        .sheet(item: $selectedCard) { card in
            NavigationView {
                CardView(newID: card.newIDCopy,
                         relatedCards: viewModel.data)
            }
        }
        .listStyle(.plain)
        .navigationBarTitle("All Other Printings")
    }
}

// MARK: {reviews
#Preview {
    NavigationView {
        CardOtherPrintingsView(newID: "rvr_en_273", languageCode: "en")
    }
        .previewInterfaceOrientation(.landscapeLeft)
}
