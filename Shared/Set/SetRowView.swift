//
//  SetRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/1/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct SetRowView: View {
    @ObservedObject var set: MGSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(set.name ?? "")
                    .font(.headline)
            }
            HStack {
                VStack {
                    Text("Symbol")
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                    Text(set.keyrune2Unicode)
//                        .scaledToFit()
                        .font(Font.custom("Keyrune", size: 20))
                }
                Spacer()
                VStack {
                    Text("Code")
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                    Text((set.code).uppercased())
                        .font(.subheadline)
                }
                Spacer()
                VStack {
                    Text("Release Date")
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                    Text(set.displayReleaseDate ?? "")
                        .font(.subheadline)
                }
                Spacer()
                VStack {
                    Text("Cards")
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                    Text("\(set.cardCount)")
                        .font(.subheadline)
                }
            }
        }
    }
}

#Preview {
    let viewModel = SetViewModel(setCode: "lea", languageCode: "en")
    viewModel.fetchRemoteData()
    
    return VStack {
        if let set = viewModel.setObject {
            SetRowView(set: set)
        } else {
            Text("Loading...")
        }
    }
}
