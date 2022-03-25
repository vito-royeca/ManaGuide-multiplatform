//
//  CardsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import SwiftUI
import ManaKit

struct CardsView: View {
    @StateObject var viewModel: CardsViewModel

    init(viewModel: CardsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                viewModel.fetchData()
            }
    }
}

struct CardsView_Previews: PreviewProvider {
    static var previews: some View {
        CardsView(viewModel: CardsViewModel())
    }
}
