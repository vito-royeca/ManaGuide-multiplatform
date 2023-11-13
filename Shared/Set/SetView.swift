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
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("CardsViewSort") private var cardsSort = CardsViewSort.defaultValue
    @AppStorage("CardsViewDisplay") private var cardsDisplay = CardsViewDisplay.defaultValue
    @StateObject var viewModel: SetViewModel
    @State private var progress: CGFloat = 0
    @State private var showingSort = false
    @State private var selectedCard: MGCard?
    @State private var cardsPerRow = 0.5

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
                    Task {
                        try await viewModel.fetchRemoteData()
                    }
                }
            } else {
                ZStack {
                    scalingHeaderView
                    topButtons
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            cardsPerRow = UIDevice.current.orientation == .portrait ? 0.5 : 0.4

            Task {
                viewModel.sort = cardsSort
                try await viewModel.fetchRemoteData()
            }
        }
    }
    
    var scalingHeaderView: some View {
        ScalingHeaderScrollView {
            ZStack {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
                SetHeaderView(viewModel: viewModel,
                              progress: $progress)
//                    .frame(height: 200)
                    .padding(.top, 80)
            }
        } content: {
            if cardsDisplay == .image {
                imageContentView
                    .padding(.horizontal, 10)
            } else if cardsDisplay == .list {
                listContentView
                    .padding(.horizontal, 10)
            }
        }
        .collapseProgress($progress)
        .allowsHeaderCollapse()
        .height(min: hasLogo() ? 150 : 130,
                max: hasLogo() ? 300 : 260)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsStoreViewSort)) { output in
            if let sort = output.object as? CardsViewSort {
                viewModel.sort = sort
                viewModel.fetchLocalData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            cardsPerRow = UIDevice.current.orientation == .portrait ? 0.5 : 0.4
        }
        .sheet(item: $selectedCard) { card in
            NavigationView {
                CardView(newID: card.newIDCopy,
                         relatedCards: viewModel.cards,
                         withCloseButton: true)
            }
        }
    }

    var imageContentView: some View {
        let cardWidth = (UIScreen.main.bounds.size.width - 60 ) * cardsPerRow
        
        let columns = [
            GridItem(.adaptive(minimum: cardWidth))
        ]
        
        return LazyVGrid(columns: columns,
                         spacing: 20,
                         pinnedViews: [.sectionHeaders]) {
            ForEach(viewModel.sections, id: \.name) { section in
                Section(header: HStack {
                    Text(section.name)
                    Spacer()
                }) {
                    ForEach(section.objects as? [MGCard] ?? [], id: \.newIDCopy) { card in
                        VStack {
                            CardImageRowView(card: card,
                                             showPrice: true)
                        }
                        .onTapGesture {
                            selectedCard = card
                        }
                    }
                }
            }
        }
    }

    var listContentView: some View {
        ForEach(viewModel.sections, id: \.name) { section in
            Section(header: HStack {
                Text(section.name)
                Spacer()
            }) {
                ForEach(section.objects as? [MGCard] ?? [], id: \.newIDCopy) { card in
                    CardsStoreLargeView(card: card)
                        .padding(.bottom, 10)
                        .onTapGesture {
                            selectedCard = card
                        }
                }
            }
        }
    }

    private var topButtons: some View {
        VStack {
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                }
                    .padding(.top, 50)
                    .padding(.leading, 17)
                    .foregroundColor(.accentColor)
                Spacer()
                CardsMenuView()
                    .padding(.top, 50)
                    .padding(.trailing, 17)
                    .foregroundColor(.accentColor)
            }
            Spacer()
        }
        .ignoresSafeArea()
    }
    
    private func hasLogo() -> Bool {
        guard let set = viewModel.setObject,
            let _ = set.bigLogoURL else {
            return false
        }
        
        return true
    }
}

// MARK: - Previews

#Preview {
    NavigationView {
        SetView(setCode: "chk", languageCode: "en")
    }
        .previewInterfaceOrientation(.landscapeLeft)
}

