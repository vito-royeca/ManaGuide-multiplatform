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
    @State var query = ""

    @AppStorage("SetsViewSort") private var setsSort = SetsViewSort.defaultValue
    @AppStorage("SetsTypeFilter") private var setsTypeFilter: String?
    @State private var showingSort = false
    
    var body: some View {
        NavigationView {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    fetchRemoteData()
                } cancelAction: {
                    viewModel.isFailed = false
                }
            } else {
                contentView
            }
        }
            .onAppear {
                fetchRemoteData()
            }
            .onChange(of: query) { _ in
                search()
            }
            .onSubmit(of: .search) {
                search()
            }
    }

    // MARK: - Private variables

    private var contentView: some View {
        List {
            ForEach(viewModel.sections, id: \.name) { section in
                Section(header: Text(section.name)) {
                    OutlineGroup(section.objects as? [MGSet] ?? [],
                                 children: \.sortedChildren) { set in
                        
                        rowView(for: set)
                    }
                }
            }
        }
            .listStyle(.plain)
            .modifier(SectionIndex(sections: viewModel.sections,
                                   sectionIndexTitles: viewModel.sectionIndexTitles))
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.SetsViewSort)) { output in
                sortBy(sorter: output.object as? SetsViewSort ?? SetsViewSort.defaultValue)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.SetsViewTypeFilter)) { output in
                filterBy(type: output.object as? String ?? nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.SetsViewClear)) { _ in
                resetToDefaults()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    SetsMenuView()
                        .environmentObject(viewModel)
                }
            }
            .navigationTitle(Text("Sets"))
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search for Magic sets...")
    }

    private func rowView(for set: MGSet) -> some View {
        let language = set.sortedLanguages?.first(where: {
            $0.code == "en"
        }) ?? set.sortedLanguages?.first
        let languageCode = language?.code ?? "en"

        let destinationView = SetView(setCode: set.code,
                                      languageCode: languageCode)
        let navigationLink = NavigationLink(destination: destinationView) {
            EmptyView()
        }
        
        return ZStack {
            SetRowView(set: set,
                       style: .listRow)
            navigationLink
                .opacity(0)
        }
    }

    // MARK: - Private methods

    private func search() {
        setsTypeFilter = nil

        viewModel.query = query
        viewModel.typeFilter = setsTypeFilter
        viewModel.fetchLocalData()
    }
    
    private func fetchRemoteData() {
        Task {
            viewModel.sort = setsSort
            viewModel.typeFilter = setsTypeFilter
            try await viewModel.fetchRemoteData()
        }
    }
    
    private func sortBy(sorter: SetsViewSort) {
        setsSort = sorter
        viewModel.sort = sorter
        viewModel.fetchLocalData()
    }
    
    private func filterBy(type: String?) {
        setsTypeFilter = type
        viewModel.typeFilter = type
        viewModel.fetchLocalData()
    }
    
    private func resetToDefaults() {
        viewModel.sort = setsSort
        viewModel.typeFilter = setsTypeFilter
        viewModel.fetchLocalData()
    }
}

// MARK: - Previews

struct SetsView_Previews: PreviewProvider {
    static var previews: some View {
        SetsView()
//            .previewInterfaceOrientation(.landscapeRight)
    }
}
