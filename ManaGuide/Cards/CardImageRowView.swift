//
//  CardImageRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/26/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

enum CardImageRowPriceStyle {
    case oneLine, twoLines
}

struct CardImageRowView: View {
    private let card: MGCard
    private let priceStyle: CardImageRowPriceStyle
    
    init(card: MGCard, priceStyle: CardImageRowPriceStyle) {
        self.card = card
        self.priceStyle = priceStyle
    }
    
    var body: some View {
        VStack(spacing: 0) {
            WebImage(url: card.imageURL(for: .png))
                .resizable()
                .placeholder(Image(uiImage: ManaKit.shared.image(name: .cardBack)!))
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fill)
                .cornerRadius(10)
                .shadow(radius: 10)
                .clipped()
//            Spacer()
            if priceStyle == .oneLine {
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
            } else {
                VStack {
                    HStack {
                        Text("Normal")
                            .font(.footnote)
                            .foregroundColor(Color.blue)
                        Spacer()
                        Text(card.displayNormalPrice)
                            .font(.footnote)
                            .foregroundColor(Color.blue)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Foil")
                            .font(.footnote)
                            .foregroundColor(Color.green)
                        Spacer()
                        Text(card.displayFoilPrice)
                            .font(.footnote)
                            .foregroundColor(Color.green)
                            .multilineTextAlignment(.trailing)
                    }
                }
                    .padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
            }
        }
    }
}

struct CardImageRowView_Previews: PreviewProvider {
    static var previews: some View {
//        CardImageRowView()
        return Text("card not found")
    }
}
