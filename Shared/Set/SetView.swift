//
//  SetView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit

struct SetView: View {
    @StateObject var viewModel: SetViewModel
    
    init(setCode: String, languageCode: String) {
        _viewModel = StateObject(wrappedValue: SetViewModel(setCode: setCode, languageCode: languageCode))
        
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }
    
    var body: some View {
        CardsStoreView(set: viewModel.set, setViewModel: viewModel, cardsViewModel: viewModel)
             .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews
struct SetView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetView(setCode: "isd", languageCode: "en")
        }
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

