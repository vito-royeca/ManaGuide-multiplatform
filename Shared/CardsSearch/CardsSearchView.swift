//
//  CardsSearchView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import SwiftUI

import SwiftUI
import ManaKit

struct CardsSearchView: View {
    @StateObject var viewModel = CardsSearchViewModel()
    @State var query = ""
    @State var scopeSelection = 0
    @State private var selectedCard: MGCard?
    
    var body: some View {
//        SearchNavigation(query: $query,
//                         scopeSelection: $scopeSelection,
//                         isBusy: $viewModel.isBusy,
//                         delegate: self) {
//            Group {
//                if viewModel.isBusy {
//                    BusyView()
//                } else if viewModel.isFailed {
//                    ErrorView {
//                        search()
//                    }
//                } else {
//                    contentView
//                }
//            }
//        }
        NavigationView {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    search()
                }
            } else {
                contentView
                    .searchable(text: $query,
                                placement: .navigationBarDrawer(displayMode: .automatic),
                                prompt: "Search for Magic sets...")
            }
        }
        .onChange(of: query) { _ in
            search()
        }
        .onSubmit(of: .search) {
            search()
        }        
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
        .navigationBarTitle("Search")
    }
}

// MARK: - Previews

#Preview {
    CardsSearchView()
}

// MARK: - SearchNavigation

extension CardsSearchView: SearchNavigationDelegate {
    var options: [SearchNavigationOptionKey : Any]? {
        return [
            .automaticallyShowsSearchBar: true,
            .obscuresBackgroundDuringPresentation: true,
            .hidesNavigationBarDuringPresentation: true,
            .hidesSearchBarWhenScrolling: false,
            .placeholder: "Search for Magic cards...",
            .showsBookmarkButton: false,
//            .scopeButtonTitles: ["All", "Bookmarked", "Seen"],
//            .scopeBarButtonTitleTextAttributes: [NSAttributedString.Key.font: UIFont.dckxRegularText],
//            .searchTextFieldFont: UIFont.dckxRegularText
         ]
    }
    
    func search() {
        guard query.count >= 3 else {
            return
        }
        
        viewModel.query = query
        Task {
            try await viewModel.fetchRemoteData()
        }
    }
    
    func scope() {
        
    }
    
    func cancel() {
        query = ""
        viewModel.fetchLocalData()
    }
}
