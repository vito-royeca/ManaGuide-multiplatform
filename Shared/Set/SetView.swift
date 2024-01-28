//
//  SetView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit
import ScalingHeaderScrollView

struct SetView: View {
    @StateObject var viewModel: SetViewModel
    @State private var progress: CGFloat = 0
    @State private var selectedCard: MGCard?

    init(setCode: String, languageCode: String) {
        _viewModel = StateObject(wrappedValue: SetViewModel(setCode: setCode,
                                                            languageCode: languageCode))
    }
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    fetchRemoteData()
                } cancelAction: {
                    viewModel.isFailed = false
                }
            } else {
                scalingHeaderView
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            fetchRemoteData()
        }
    }
    
    // MARK: - Private variables

    private var scalingHeaderView: some View {
        ScalingHeaderScrollView {
            ZStack {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
                SetHeaderView(viewModel: viewModel,
                              progress: $progress)
                    .padding(.top, 80)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
        } content: {
            CardsView(selectedCard: $selectedCard)
                .environmentObject(viewModel as CardsViewModel)
                .padding(.horizontal, 10)
        }
        .collapseProgress($progress)
        .allowsHeaderCollapse()
        .height(min: 160,
                max: 320)
        .sheet(item: $selectedCard) { card in
            NavigationView {
                CardView(newID: card.newIDCopy,
                         relatedCards: viewModel.cards,
                         withCloseButton: true)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                CardsMenuView()
                    .environmentObject(viewModel as CardsViewModel)
            }
        }
    }

    // MARK: - Private methods

    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchRemoteData()
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationView {
        SetView(setCode: "clu",
                languageCode: "en")
    }
//        .previewInterfaceOrientation(.landscapeLeft)
}

