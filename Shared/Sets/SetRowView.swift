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
    private let set: MGSet
    
    init(set: MGSet) {
        self.set = set
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Text(set.keyrune2Unicode)
                    .scaledToFit()
                    .font(Font.custom("Keyrune", size: 30))
                Text(set.name ?? "")
                    .font(.headline)
            }
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
            Text("Release Date: \(set.displayReleaseDate ?? "")")
                .font(.subheadline)
                .foregroundColor(Color.gray)
            Spacer()
        }
    }
}

struct SetRowView_Previews: PreviewProvider {
    static var previews: some View {
        Text("set not found")
    }
}
