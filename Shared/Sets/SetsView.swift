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
    @AppStorage("setsSort") private var sort = SetsViewSort.releaseDate
    
    @StateObject var viewModel = SetsViewModel()
    @State private var showingSort = false
    @State private var selectedSet: MGSet?
    @State var query = ""
    
    var body: some View {
        NavigationView {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    Task {
                        try await viewModel.fetchRemoteData()
                    }
                }
            } else {
                bodyData
            }
        }
            .onAppear {
                Task {
                    viewModel.sort = sort
                    try await viewModel.fetchRemoteData()
                }
            }
            .onChange(of: query) { _ in
                search()
            }
            .onSubmit(of: .search) {
                search()
            }
    }
    
    var bodyData: some View {
        List {
            ForEach(viewModel.sections, id: \.name) { section in
                Section(header: Text(section.name)) {
                    OutlineGroup(section.objects as? [MGSet] ?? [], children: \.sortedChildren) { set in
                        SetRowView(set: set)
                            .onTapGesture {
                                selectedSet = set
                            }
                    }
                }
            }
        }
            .listStyle(.plain)
            .fullScreenCover(item: $selectedSet) { set in
                SetView(setCode: set.code, languageCode: "en")
            }
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search for Magic sets...")
            .modifier(SectionIndex(sections: viewModel.sections,
                                   sectionIndexTitles: viewModel.sectionIndexTitles))
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
                        .foregroundColor(.accentColor)
                }
            }
            .navigationBarTitle("Sets")
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
    
    func search() {
        viewModel.query = query
        viewModel.fetchLocalData()
    }
}

// MARK: - Previews

struct SetsView_Previews: PreviewProvider {
    static var previews: some View {
        SetsView()
            .previewInterfaceOrientation(.landscapeRight)
    }
}

