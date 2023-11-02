//
//  SetView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI
import ScalingHeaderScrollView

struct SetView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("cardsSort") private var sort = CardsViewSort.name
    @StateObject var viewModel: SetViewModel
    @State private var progress: CGFloat = 0
    @State private var showingSort = false
    
    init(setCode: String, languageCode: String) {
        _viewModel = StateObject(wrappedValue: SetViewModel(setCode: setCode,
                                                            languageCode: languageCode))
    }
    
    var body: some View {
//        CardsStoreView(set: viewModel.set, setViewModel: viewModel, cardsViewModel: viewModel)
//             .navigationBarTitleDisplayMode(.inline)
        
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    viewModel.fetchRemoteData()
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
            viewModel.sort = sort
            viewModel.fetchRemoteData()
        }
    }
    
    var scalingHeaderView: some View {
        ScalingHeaderScrollView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                SetHeaderView(viewModel: viewModel,
                              progress: $progress)
                    .frame(height: 200)
                    .padding(.top, 50)
            }
        } content: {
            contentView
                .padding(.horizontal, 5)
        }
        .collapseProgress($progress)
        .allowsHeaderCollapse()
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsStoreViewSort)) { (output) in
            viewModel.fetchLocalData()
        }
    }
    
    var contentView: some View {
        ForEach(viewModel.data) { card in
            let tap = TapGesture()
                .onEnded { _ in
                    //                        self.selectedCard = card
                }
            
            if let card = viewModel.find(MGCard.self,
                                         id: card) {
                CardsStoreLargeView(card: card)
                    .gesture(tap)
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
                Button(action: {
                    showingSort.toggle()
                }) {
                    Image(systemName: "arrow.up.arrow.down")
                }
                    .actionSheet(isPresented: $showingSort) {
                        sortActionSheet
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 17)
                    .foregroundColor(.accentColor)
            }
            Spacer()
        }
        .ignoresSafeArea()
    }
    
    private var sortActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sort by"),
            buttons: [
                .default(Text("\(sort == .name ? "\u{2713}" : "") Name")) {
                    sort = .name
                    viewModel.sort = .name
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort,
                                                    object: nil)
                },
                .default(Text("\(sort == .collectorNumber ? "\u{2713}" : "") Collector Number")) {
                    sort = .collectorNumber
                    viewModel.sort = .collectorNumber
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort,
                                                    object: nil)
                },
                .default(Text("\(sort == .rarity ? "\u{2713}" : "") Rarity")) {
                    sort = .rarity
                    viewModel.sort = .rarity
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort,
                                                    object: nil)
                },
                .default(Text("\(sort == .type ? "\u{2713}" : "") Type")) {
                    sort = .type
                    viewModel.sort = .type
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort,
                                                    object: nil)
                },
                .cancel(Text("Cancel"))
            ]
        )
    }
}

// MARK: - Previews

#Preview {
    NavigationView {
        SetView(setCode: "isd", languageCode: "en")
    }
//        .previewInterfaceOrientation(.landscapeLeft)
}

