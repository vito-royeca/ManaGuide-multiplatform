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
    
    @State private var isColorsExpanded = false
    @State private var isRaritiesExpanded = false
    @State private var isTypesExpanded = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        if viewModel.isBusy {
            BusyView()
        } else if viewModel.isFailed {
            ErrorView {
                fetchRemoteData()
            }
        } else {
            contentView
        }
    }

    private var contentView: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                Section(footer: Text("Note: type a name or select at least any 2 filters.")) {
                    LabeledContent {
                        TextField("Title",
                                  text: $viewModel.name,
                                  prompt: Text("Name of card, at least 4 characters"),
                                  axis: .horizontal)
                    } label: {
                        Text("Name")
                    }
                    .labeledContentStyle(.vertical)
                    
//                    colorsField
                    raritiesField
                    typesField
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.resetFilters()
                        viewModel.updateWillFetch()
                    } label: {
                        Text("Clear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        fetchRemoteData()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .disabled(!viewModel.willFetch)
                    .navigationDestination(for: String.self) { view in
                        if view == "CardsSearchResultsView" {
                            CardsSearchResultsView()
                                .environmentObject(viewModel)
                        }
                    }
                }
            }
            .navigationBarTitle("Search")
            .sheet(isPresented: $isRaritiesExpanded) {
                NavigationView {
                    CardFilterSelectorView(viewModel: RaritiesViewModel(),
                                           type: MGRarity.self,
                                           selectedFilters: $viewModel.raritiesFilter)
                    .navigationTitle("Rarity")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                isRaritiesExpanded.toggle()
                            } label: {
                                Text("Close")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isTypesExpanded) {
                NavigationView {
                    CardFilterSelectorView(viewModel: CardTypesViewModel(),
                                           type: MGCardType.self,
                                           selectedFilters: $viewModel.typesFilter)
                    .navigationTitle("Type")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                isTypesExpanded.toggle()
                            } label: {
                                Text("Close")
                            }
                        }
                    }
                }
            }
        }
    }

//    private var colorsField: some View {
//        let flexibleView = ScrollView {
//            FlexibleView(data: viewModel.colors,
//                         spacing: 5,
//                         alignment: .leading) { color in
//                if viewModel.colorsFilter.contains(where: { $0 == color }) {
//                    ColorFilterButton(color: color,
//                                      isSelected: true) {
//                        viewModel.colorsFilter.removeAll(where: { $0 == color })
//                        viewModel.updateWillFetch()
//                    }
//                } else {
//                    ColorFilterButton(color: color,
//                                      isSelected: false) {
//                        viewModel.colorsFilter.append(color)
//                        viewModel.updateWillFetch()
//                    }
//                }
//            }
//        }
//        
//        return DisclosureGroup("Color",
//                        isExpanded: $isColorsExpanded) {
//            VStack(alignment: .leading) {
//                Text("Select / deselect an item")
//                    .foregroundStyle(.gray)
//                flexibleView
//            }
//        }
//    }

    private var raritiesField: some View {
        LabeledContent {
            ScrollView {
                FlexibleView(data: viewModel.raritiesFilter,
                             spacing: 8,
                             alignment: .leading) { rarity in
                    RemovableFilterButton(text: rarity.description) {
                        viewModel.raritiesFilter.removeAll(where: { $0 == rarity })
                        viewModel.updateWillFetch()
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
                    Image(systemName: "pencil")
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
                        viewModel.updateWillFetch()
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
                    Image(systemName: "pencil")
                })
            }
        }
        .labeledContentStyle(.vertical)
    }
    
    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchRemoteData()
            navigationPath.append("CardsSearchResultsView")
        }
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
        let button = Button {
            action()
        } label: {
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
