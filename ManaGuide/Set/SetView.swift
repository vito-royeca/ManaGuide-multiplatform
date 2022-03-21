//
//  SetView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct SetView: View {
    @StateObject var viewModel = SetViewModel()
    var setCode: String
    var languageCode: String
    
    init(setCode: String, languageCode: String) {
        self.setCode = setCode
        self.languageCode = languageCode
        
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }
    
    var body: some View {
        List {
            ForEach(viewModel.cards) { card in
//                let card = viewModel.card(with: cardID)
//                let cardView = CardView(newID: card.newID)
//                let lazyView = LazyView(cardView)
                let cardView = Text(card.displayName)
                CardRowView(card: card)
                    .background(NavigationLink("", destination: cardView).opacity(0))
                    .listRowSeparator(.hidden)
            }
        }
            .listStyle(.plain)
            .navigationBarTitle(viewModel.isBusy ? "Loading..." : viewModel.set?.name ?? "")
            .overlay(
                Group {
                    if viewModel.isBusy {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        EmptyView()
                    }
                })
            .onAppear {
                viewModel.setCode = setCode
                viewModel.languageCode = languageCode
                viewModel.fetchData()
            }
//            .onDisappear {
//                viewModel.clearData()
//            }
    }
}

struct SetView_Previews: PreviewProvider {
    static var previews: some View {
//        let api = MockAPI()
        let view = SetView(setCode: "api.setCode", languageCode: "en")
//        view.viewModel.dataAPI = api
        
        return view
    }
}
