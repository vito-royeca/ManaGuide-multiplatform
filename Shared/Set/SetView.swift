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
        CardsStoreView(viewModel: viewModel) {
            if let set = viewModel.set {
                VStack(spacing: 0) {
                    SetRowView(set: set)
                    SetLanguagesView(set: set, viewModel: viewModel)
                }
            } else {
                EmptyView()
            }
        }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        if let set = viewModel.set,
                           let logoImage = set.logoImage {
                            Image(uiImage: logoImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipped()
                        } else {
                            EmptyView()
                        }
                    }
                }
             }
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

// MARK: - SetLanguagesView

struct SetLanguagesView: View {
    @ObservedObject var viewModel: SetViewModel
    private var set: MGSet
    private let columns = [
        GridItem(),
        GridItem(),
        GridItem(),
        GridItem(),
        GridItem(),
        GridItem()
    ]
    
    init(set: MGSet, viewModel: SetViewModel) {
        self.set = set
        self.viewModel = viewModel
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            Image("language")
                .resizable()
                .frame(width: 20, height: 20)
            ForEach(set.sortedLanguages ?? [], id:\.code) { language in
                if viewModel.languageCode == language.code {
                    Text(language.displayCode ?? "")
                        .foregroundColor(Color.gray)
                } else {
                    Button(language.displayCode ?? "", action: {
                        viewModel.languageCode = language.code ?? ""
                        viewModel.cards.removeAll()
                        viewModel.fetchData()
                    })
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(Color.accentColor)
                }
            }
        }
    }
}
