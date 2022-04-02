//
//  SetsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//  Copyright © 2022 Jovito Royeca. All rights reserved.
//

import SwiftUI
import ManaKit

struct SetsView: View {
    @StateObject var viewModel = SetsViewModel()
    @State var query: String?
    @State var scopeSelection: Int = 0
    
    var body: some View {
        SearchNavigation(query: $query,
                         scopeSelection: $scopeSelection,
                         isBusy: $viewModel.isBusy,
                         delegate: self) {
            SetsDataView(viewModel: viewModel)
                .navigationBarTitle("Sets")
        }
        
    }
}

// MARK: - Previews

struct SetsView_Previews: PreviewProvider {
    static var previews: some View {
        SetsView()
    }
}

// MARK: - SearchNavigation

extension SetsView: SearchNavigationDelegate {
    var options: [SearchNavigationOptionKey : Any]? {
        return [
            .automaticallyShowsSearchBar: true,
            .obscuresBackgroundDuringPresentation: true,
            .hidesNavigationBarDuringPresentation: true,
            .hidesSearchBarWhenScrolling: false,
            .placeholder: "Search for Magic sets...",
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
        viewModel.query = query
        viewModel.fetchData()
    }
}

struct SetsDataView: View {
    @StateObject var viewModel: SetsViewModel
    @State private var showingSort = false
    @AppStorage("setsSort") private var sort = SetsViewSort.releaseDate
    
    // MARK: - Initializers
    
    init(viewModel: SetsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            ForEach(viewModel.sections, id: \.name) { section in
                Section(header: Text(section.name)) {
                    ForEach(section.objects as? [MGSet] ?? []) { set in
                        NavigationLink(destination: SetView(setCode: set.code, languageCode: "en")) {
                            SetRowView(set: set)
                        }
                    }
                }
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
                            sortActionSheet
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
                viewModel.sort = sort
                viewModel.fetchData()
            }
    }
}

// MARK: - Action Sheets

extension SetsDataView {
    var sortActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sort by"),
            buttons: [
                .default(Text("\(sort == .name ? "\u{2713}" : "") Name")) {
                    sort = .name
                    viewModel.sort = .name
                    viewModel.fetchData()
                },
                .default(Text("\(sort == .releaseDate ? "\u{2713}" : "") Release Date")) {
                    sort = .releaseDate
                    viewModel.sort = .releaseDate
                    viewModel.fetchData()
                },
                .default(Text("\(sort == .type ? "\u{2713}" : "") Type")) {
                    sort = .type
                    viewModel.sort = .type
                    viewModel.fetchData()
                },
                .cancel(Text("Cancel"))
            ]
        )
    }
}
