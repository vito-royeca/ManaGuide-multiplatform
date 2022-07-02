//
//  SetLanguagesView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 7/2/22.
//

import SwiftUI
import ManaKit

struct SetLanguagesView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @ObservedObject var viewModel: SetViewModel
    private var set: MGSet
        
    init(set: MGSet, viewModel: SetViewModel) {
        self.set = set
        self.viewModel = viewModel
    }
    
    var body: some View {
        LazyVGrid(columns: columns(), spacing: 10) {
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
                        viewModel.data.removeAll()
                        viewModel.fetchData()
                    })
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    func columns() -> [GridItem] {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            return [GridItem](repeating: GridItem(), count: 6)
        } else {
            return [GridItem](repeating: GridItem(), count: 12)
        }
        #else
        return [GridItem](repeating: GridItem(), count: 12)
        #endif
    }
}
