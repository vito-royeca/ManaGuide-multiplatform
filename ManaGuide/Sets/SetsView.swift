//
//  SetsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//  Copyright © 2022 Jovito Royeca. All rights reserved.
//

import SwiftUI
import ManaKit

struct SetsView: View {
    @StateObject var viewModel = SetsViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.sets) { set in
                let setView = SetView(setCode: set.code, languageCode: "en")
                NavigationLink(destination: setView) {
                    SetsRowView(set: set)
                }
            }
        }
            .listStyle(.plain)
            .navigationBarTitle(viewModel.isBusy ? "Loading..." : "Sets")
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

struct SetsView_Previews: PreviewProvider {
    static var previews: some View {
        let view = SetsView()
//        view.viewModel.dataAPI = MockAPI()
        
        return view
    }
}

struct SetsRowView: View {
    private let set: MGSet
    
    init(set: MGSet) {
        self.set = set
    }
    
    var body: some View {
        HStack {
            Text(set.keyrune2Unicode())
                .scaledToFit()
                .font(Font.custom("Keyrune", size: 30))
            
            VStack(alignment: .leading) {
                Text(set.name ?? "")
                    .font(.headline)
                
                HStack {
                    Text("Code: \(set.code)")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                    
                    Text("\(set.cardCount) card\(set.cardCount > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.trailing)
                }
                
                Text("Release Date: \(set.releaseDate ?? "")")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
            }
        }
    }
}
