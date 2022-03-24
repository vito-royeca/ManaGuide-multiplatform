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
    @StateObject var viewModel: SetViewModel
    
    init(setCode: String, languageCode: String) {
        _viewModel = StateObject(wrappedValue: SetViewModel(setCode: setCode, languageCode: languageCode))
                                 
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }
    
    var body: some View {
        List {
            ForEach(viewModel.cards) { card in
                let newID = "\(card.set?.code ?? "")_\(card.language?.code ?? "")_\(card.collectorNumber ?? "")"
                CardRowView(card: card)
                    .background(NavigationLink("", destination: CardView(newID: newID)).opacity(0))
                    .listRowSeparator(.hidden)
            }
        }
            .listStyle(.plain)
            .navigationBarTitle(viewModel.set?.name ?? "")
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
                print("onAppear... \(viewModel.setCode): \(viewModel.cards.count)")
                viewModel.fetchData()
            }
    }
}

struct SetView_Previews: PreviewProvider {
    static var previews: some View {
        let view = NavigationView {
            SetView(setCode: "all", languageCode: "en")
        }

        return view
    }
}
