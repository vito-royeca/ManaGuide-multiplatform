//
//  CardImageRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/26/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct CardImageRowView: View {
    private let card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        VStack(spacing: 0) {
            WebImage(url: card.imageURL(for: .png))
                .resizable()
                .placeholder(Image(uiImage: ManaKit.shared.image(name: .cardBack)!))
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fill)
                .cornerRadius(5)
                .clipped()
            HStack {
                    Text("Normal")
                        .font(.footnote)
                        .foregroundColor(Color.blue)
                    Spacer()
                    Text(card.displayNormalPrice)
                        .font(.footnote)
                        .foregroundColor(Color.blue)
                        .multilineTextAlignment(.trailing)
                    Spacer()
                    Text("Foil")
                        .font(.footnote)
                        .foregroundColor(Color.green)
                    Spacer()
                    Text(card.displayFoilPrice)
                        .font(.footnote)
                        .foregroundColor(Color.green)
                        .multilineTextAlignment(.trailing)
            }
            .padding(5)
        }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary, lineWidth: 1)
            )
    }
}

struct CardImageRowView_Previews: PreviewProvider {
    static var previews: some View {
//        CardImageRowView()
        return Text("card not found")
    }
}
