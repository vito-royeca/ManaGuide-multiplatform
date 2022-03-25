//
//  SearchView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct SearchView: View {
    @StateObject var viewModel = SearchViewModel()
    @State var query: String?
    @State var scopeSelection: Int = 0
    
    init() {
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }
    
    var body: some View {
        SearchNavigation(query: $query,
                         scopeSelection: $scopeSelection,
                         isBusy: $viewModel.isBusy,
                         delegate: self) {
            CardsView(viewModel: viewModel)
                .navigationTitle("Search")
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        let view = SearchView()
//        view.viewModel.dataAPI = MockAPI()
        
        return view
    }
}

// MARK: - SearchNavigation

extension SearchView: SearchNavigationDelegate {
    var options: [SearchNavigationOptionKey : Any]? {
        return [
            .automaticallyShowsSearchBar: true,
            .obscuresBackgroundDuringPresentation: true,
            .hidesNavigationBarDuringPresentation: true,
            .hidesSearchBarWhenScrolling: false,
            .placeholder: "Search",
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
        viewModel.fetchData()
    }
    
    func scope() {
        
    }
    
    func cancel() {
        query =  nil
        viewModel.query = nil
    }
}
