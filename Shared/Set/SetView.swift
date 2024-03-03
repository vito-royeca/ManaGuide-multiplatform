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

    @AppStorage("SetLanguageFilter") private var setLanguageFilter = "en"

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
                    update(languageCode: "en")
                } cancelAction: {
                    viewModel.isFailed = false
                }
            } else {
                scalingHeaderView
                    .ignoresSafeArea()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.SetViewLanguageFilter)) { displayCode in
            let languageCode = (displayCode.object as? String ?? "en").lowercased()
            update(languageCode: languageCode)
        }
        .onAppear {
            update(languageCode: "en")
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
        .height(min: 175,
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
                SetLanguageMenuView()
                    .environmentObject(viewModel)
                CardsMenuView()
                    .environmentObject(viewModel as CardsViewModel)
            }
        }
    }

    // MARK: - Private methods

    private func update(languageCode: String) {
        Task {
            viewModel.findSet()
            
            guard let setObject = viewModel.setObject else {
                return
            }
            
            if let _ = (setObject.sortedLanguages ?? []).first(where: { $0.code == languageCode }) {
                viewModel.languageCode = languageCode
                setLanguageFilter = languageCode
            } else if let firstLanguage = (setObject.sortedLanguages ?? []).first {
                viewModel.languageCode = firstLanguage.code
                setLanguageFilter = firstLanguage.code
            }
            
            try await viewModel.fetchRemoteData()
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationView {
        SetView(setCode: "pmda",
                languageCode: "en")
    }
//        .previewInterfaceOrientation(.landscapeLeft)
}

