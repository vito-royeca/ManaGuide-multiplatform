//
//  CardsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import SwiftUI

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct CardsView: View {
    @StateObject var viewModel = CardsSearchViewModel()
    @State var query: String?
    @State var scopeSelection: Int = 0
    
    var body: some View {
        SearchNavigation(query: $query,
                         scopeSelection: $scopeSelection,
                         isBusy: $viewModel.isBusy,
                         delegate: self) {
            CardsStoreView(setViewModel: nil,
                           cardsViewModel: viewModel)
                .navigationBarTitle("Cards")
        }
    }
}

struct CardsView_Previews: PreviewProvider {
    static var previews: some View {
        CardsView()
    }
}

// MARK: - SearchNavigation

extension CardsView: SearchNavigationDelegate {
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
        guard let query = query,
            query.count >= 3 else {
            return
        }
        
        viewModel.query = query
        viewModel.scopeSelection = scopeSelection
        viewModel.data.removeAll()
        viewModel.fetchRemoteData()
    }
    
    func scope() {
        
    }
    
    func cancel() {
        query =  nil
        viewModel.fetchLocalData()
    }
}
