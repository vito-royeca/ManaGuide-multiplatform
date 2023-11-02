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
    @StateObject var viewModel: SetViewModel
    @State var progress: CGFloat = 0
    
    init(setCode: String, languageCode: String) {
        _viewModel = StateObject(wrappedValue: SetViewModel(setCode: setCode,
                                                            languageCode: languageCode))
        
//        UITableView.appearance().allowsSelection = false
//        UITableViewCell.appearance().selectionStyle = .none
    }
    
    var body: some View {
//        CardsStoreView(set: viewModel.set, setViewModel: viewModel, cardsViewModel: viewModel)
//             .navigationBarTitleDisplayMode(.inline)
        
//        listView
        ZStack {
            scalingHeaderView
                .onAppear {
                    viewModel.fetchRemoteData()
                }
            topButtons
        }
        .ignoresSafeArea()
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

    var listView: some View {
        List {
            SetHeaderView(viewModel: viewModel,
                          progress: $progress)
                .listRowSeparator(.hidden)
            contentView
        }
            .listStyle(.plain)
//            .sheet(item: $selectedCard) { selectedCard in
//                NavigationView {
//                    if let card = viewModel.find(MGCard.self, id: selectedCard) {
//                        CardView(newID: card.newIDCopy, relatedCards: cards)
//                    } else {
//                        EmptyView()
//                    }
//                }
//            }
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

                }) {
                    Image(systemName: "ellipsis")
                }
                    .padding(.top, 50)
                    .padding(.trailing, 17)
                    .foregroundColor(.accentColor)
            }
            Spacer()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Previews

#Preview {
    NavigationView {
        SetView(setCode: "twho", languageCode: "en")
    }
//        .previewInterfaceOrientation(.landscapeLeft)
}

