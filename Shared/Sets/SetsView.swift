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
    @AppStorage("setsTypeFilter") private var setsTypeFilter: String?
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
                    viewModel.typeFilter = setsTypeFilter
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
                        SetRowView(set: set,
                                   style: .listRow)
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.SetsViewSort)) { output in
                if let sort = output.object as? SetsViewSort {
                    viewModel.sort = sort
                    viewModel.fetchLocalData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.SetsViewTypeFilter)) { output in
                if let typeFilter = output.object as? String {
                    viewModel.typeFilter = typeFilter
                } else {
                    viewModel.typeFilter = nil
                }
                viewModel.fetchLocalData()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    SetsMenuView()
                        .environmentObject(viewModel)
                }
            }
            .navigationBarTitle("Sets")
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
//            .previewInterfaceOrientation(.landscapeRight)
    }
}

