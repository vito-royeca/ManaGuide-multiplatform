//
//  CardsSearchFormView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/24/23.
//

import SwiftUI
import ManaKit

struct CardsSearchFormView: View {
    @StateObject var viewModel = CardsSearchViewModel()
    
    @State private var isRaritiesExpanded = false
    @State private var isTypesExpanded = false
    @State private var isKeywordsExpanded = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        if viewModel.isBusy {
            BusyView()
        } else if viewModel.isFailed {
            ErrorView {
                performSearch()
            } cancelAction: {
                cancelSearch()
            }
        } else {
            contentView
        }
    }

    private var contentView: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                Section(footer: Text("Note: type a name to enable Search")) {
                    LabeledContent {
                        TextField("Title",
                                  text: $viewModel.nameFilter,
                                  prompt: Text("Name of card, at least 4 characters"),
                                  axis: .horizontal)
                            .submitLabel(.done)
                    } label: {
                        Text("Name")
                    }
                    .labeledContentStyle(.vertical)
                    
                    raritiesField
                    typesField
                    keywordsField
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.resetFilters()
                    }) {
                        Text("Clear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        performSearch()
                    }) {
                        Text("Submit")
                    }
                    .disabled(!viewModel.willFetch())
                    .navigationDestination(for: String.self) { view in
                        if view == CardsSearchResultsView.viewName {
                            CardsSearchResultsView()
                                .environmentObject(viewModel)
                        }
                    }
                }
            }
            .navigationTitle(Text("Search"))
            .sheet(isPresented: $isRaritiesExpanded) {
                NavigationView {
                    CardFilterSelectorView(viewModel: RaritiesViewModel(),
                                           type: MGRarity.self,
                                           selectedFilters: $viewModel.raritiesFilter,
                                           filterTitle: "Rarity")
                }
            }
            .sheet(isPresented: $isTypesExpanded) {
                NavigationView {
                    CardFilterSelectorView(viewModel: CardTypesViewModel(),
                                           type: MGCardType.self,
                                           selectedFilters: $viewModel.typesFilter,
                                           filterTitle: "Type")
                }
            }
            .sheet(isPresented: $isKeywordsExpanded) {
                NavigationView {
                    CardFilterSelectorView(viewModel: KeywordsViewModel(),
                                           type: MGKeyword.self,
                                           selectedFilters: $viewModel.keywordsFilter,
                                           filterTitle: "Keyword")
                }
            }
        }
    }

    private var raritiesField: some View {
        LabeledContent {
            ScrollView {
                FlexibleView(data: viewModel.raritiesFilter,
                             spacing: 8,
                             alignment: .leading) { rarity in
                    RemovableFilterButton(text: rarity.description) {
                        viewModel.raritiesFilter.removeAll(where: { $0 == rarity })
                    }
                }
            }
        } label: {
            HStack {
                Text("Rarity")
                Spacer()
                Button(action: {
                    isRaritiesExpanded.toggle()
                }, label: {
                    Image(systemName: "plus")
                })
            }
        }
        .labeledContentStyle(.vertical)
    }

    private var typesField: some View {
        LabeledContent {
            ScrollView {
                FlexibleView(data: viewModel.typesFilter,
                             spacing: 8,
                             alignment: .leading) { cardType in
                    RemovableFilterButton(text: cardType.description) {
                        viewModel.typesFilter.removeAll(where: { $0 == cardType })
                    }
                }
            }
        } label: {
            HStack {
                Text("Type")
                Spacer()
                Button(action: {
                    isTypesExpanded.toggle()
                }, label: {
                    Image(systemName: "plus")
                })
            }
        }
        .labeledContentStyle(.vertical)
    }
    
    private var keywordsField: some View {
        LabeledContent {
            ScrollView {
                FlexibleView(data: viewModel.keywordsFilter,
                             spacing: 8,
                             alignment: .leading) { keyword in
                    RemovableFilterButton(text: keyword.description) {
                        viewModel.keywordsFilter.removeAll(where: { $0 == keyword })
                    }
                }
            }
        } label: {
            HStack {
                Text("Keyword")
                Spacer()
                Button(action: {
                    isKeywordsExpanded.toggle()
                }, label: {
                    Image(systemName: "plus")
                })
            }
        }
        .labeledContentStyle(.vertical)
    }
    
    private func performSearch() {
        viewModel.isFailed = false
        viewModel.isBusy = false
        navigationPath.append(CardsSearchResultsView.viewName)
    }
    
    private func cancelSearch() {
        viewModel.isFailed = false
        viewModel.isBusy = false
        navigationPath = NavigationPath()
    }
}

#Preview {
    CardsSearchFormView()
}


// MARK: -  FilterButton

struct FilterButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .title) var paddingWidth = 15

    var body: some View {
        let button = Button(text) {
            action()
        }

        if isSelected {
            button
                .buttonStyle(.borderedProminent)
        } else {
            button
                .buttonStyle(.bordered)
        }
    }
}

// MARK: -  RemovableFilterButton

struct RemovableFilterButton: View {
    let text: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .title) var paddingWidth = 15

    var body: some View {
        Button(text, systemImage: "minus.circle") {
            action()
        }
        .buttonStyle(.bordered)
        .foregroundColor(.accentColor)
    }
}

// MARK: -  ColorFilterButton

struct ColorFilterButton: View {
    let color: MGColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let text = "{CI_\(color.symbol ?? "")}"
        let button = Button(action: {
            action()
        }) {
            HStack {
                AttributedText(
                    NSAttributedString(symbol: text,
                                       pointSize: 16)
                )
                Text(color.name ?? "")
            }
        }

        if isSelected {
            button
                .buttonStyle(.borderedProminent)
        } else {
            button
                .buttonStyle(.bordered)
        }
    }
}
