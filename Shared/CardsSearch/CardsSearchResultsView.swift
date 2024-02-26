//
//  CardsSearchResultsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/25/23.
//

import SwiftUI
import ManaKit

struct CardsSearchResultsView: View {
    static let viewName = "CardsSearchResultsView"

    @EnvironmentObject var viewModel: CardsSearchViewModel

    @State private var selectedCard: MGCard?

    var body: some View {
        Group {
            if viewModel.isBusy {
                if viewModel.isLoadingNextPage {
                    contentView
                } else {
                    BusyView()
                }
            } else if viewModel.isFailed {
                ErrorView {
                    fetchRemoteData()
                } cancelAction: {
                    viewModel.isFailed = false
                }
            } else {
                if viewModel.cards.isEmpty {
                    EmptyResultView()
                } else {
                    contentView
                }
            }
        }
        .onAppear {
            fetchRemoteData()
        }
        .onDisappear {
            viewModel.resetPagination()
        }
    }
    
    private var contentView: some View {
        listView
            .navigationTitle(Text(viewModel.cards.isEmpty ? "" : "Results"))
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
    }

    private var listView: some View {
        List {
            CardsView(selectedCard: $selectedCard)
                .environmentObject(viewModel as CardsViewModel)
            if viewModel.hasMoreData {
                Text("Loading...")
                    .font(Font.custom(ManaKit.Fonts.magic2015.name,
                                      size: 15))
//                    .onAppear {
//                        fetchRemoteNextPage()
//                    }
//                lastRowView
//                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    var lastRowView: some View {
        Group {
            if viewModel.isBusy {
                ProgressView("Loading...")
                    .progressViewStyle(.circular)
                    .font(Font.custom(ManaKit.Fonts.magic2015.name,
                                      size: 20))
            } else if viewModel.isFailed {
                ErrorView {
                    fetchRemoteData()
                } cancelAction: {
                    viewModel.isFailed = false
                }
            } else {
                EmptyView()
            }
        }
        .frame(height: 60)
        .onAppear {
            fetchRemoteNextPage()
        }
    }

    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchRemoteData()
        }
    }
    
    private func fetchRemoteNextPage() {
        Task {
            try await viewModel.fetchRemoteNextPage()
        }
    }
}

#Preview {
    let viewModel = CardsSearchViewModel()

    return CardsSearchResultsView()
        .environmentObject(viewModel)
}
