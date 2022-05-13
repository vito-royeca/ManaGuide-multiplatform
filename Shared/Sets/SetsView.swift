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
                .modifier(SectionIndex(sections: viewModel.sections, sectionIndexTitles: viewModel.sectionIndexTitles))
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
        viewModel.fetchLocalData()
    }
    
    func scope() {
        
    }
    
    func cancel() {
        query =  nil
        viewModel.query = query
        viewModel.fetchLocalData()
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
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    viewModel.fetchData()
                }
            } else {
                bodyData
            }
        }
            .onAppear {
                viewModel.sort = sort
                viewModel.fetchData()
            }
    }
    
    var bodyData: some View {
        List {
            ForEach(viewModel.sections, id: \.name) { section in
                Section(header: Text(section.name)) {
                    OutlineGroup(section.objects as? [MGSet] ?? [], children: \.sortedChildren) { set in
                        SetRowView(set: set)
                            .background(NavigationLink("", destination: SetView(setCode: set.code, languageCode: "en")).opacity(0))
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
                        .foregroundColor(Color.accentColor)
                }
            }
    }

    var sortActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sort by"),
            buttons: [
                .default(Text("\(sort == .name ? "\u{2713}" : "") Name")) {
                    sort = .name
                    viewModel.sort = .name
                    viewModel.fetchLocalData()
                },
                .default(Text("\(sort == .releaseDate ? "\u{2713}" : "") Release Date")) {
                    sort = .releaseDate
                    viewModel.sort = .releaseDate
                    viewModel.fetchLocalData()
                },
                .default(Text("\(sort == .type ? "\u{2713}" : "") Type")) {
                    sort = .type
                    viewModel.sort = .type
                    viewModel.fetchLocalData()
                },
                .cancel(Text("Cancel"))
            ]
        )
    }
}
