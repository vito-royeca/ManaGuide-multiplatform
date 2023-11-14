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
                    Task {
                        try await viewModel.fetchRemoteData()
                    }
                }
            } else {
                listView
            }
        }
        .onAppear {
            Task {
                viewModel.sort = sort
                try await viewModel.fetchRemoteData()
            }
        }
    }
    
    var listView: some View {
        List {
            ForEach(viewModel.sections, id: \.name) { section in
                ForEach(section.objects as? [MGCard] ?? []) { card in
                    CardsStoreLargeView(card: card)
                        .onTapGesture {
                            selectedCard = card
                        }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewSort)) { (output) in
            viewModel.fetchLocalData()
        }
        .sheet(item: $selectedCard) { card in
            NavigationView {
                CardView(newID: card.newIDCopy,
                         relatedCards: [],
                         withCloseButton: true)
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
