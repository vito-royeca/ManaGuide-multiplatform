//
//  CardRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI


struct CardRowView: View {
    private let card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        let font = card.nameFont()

        VStack {
            VStack(alignment: .leading) {
                if let manaCost = card.manaCost {
                    ZStack(alignment: .leading) {
                        Text(card.displayName)
                            .font(Font.custom(font.name, size: font.size))
                        Spacer()
                        AttributedText(
                            NSAttributedString(symbol: manaCost, pointSize: 16)
                        )
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    Text(card.displayName)
                        .font(Font.custom(font.name, size: font.size))
                }

                HStack(spacing: 20) {
                    WebImage(url: card.imageURL(for: .artCrop))
                        .resizable()
                        .placeholder(Image(uiImage: ManaKit.shared.image(name: .cropBack)!))
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100, alignment: .center)
                        .clipped()
                    
                    VStack(alignment: .leading) {
                        Text(card.displayTypeLine)
                            .font(.footnote)

                        Spacer()
                        
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
                }
                
                Divider()
                    .background(Color.secondary)
                
                HStack() {
                    Text(card.displayKeyrune)
                        .font(Font.custom("Keyrune", size: 20))
                        .foregroundColor(Color(card.keyruneColor()))
                    Text("\u{2022} #\(card.collectorNumber ?? "") \u{2022}")
                        .font(.footnote)
                    Text(card.rarity?.name ?? "")
                        .font(.footnote)
                    Spacer()
                    Text(card.displayPowerToughness)
                        .font(.footnote)
                }
            }
                .padding()
        }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary, lineWidth: 1)
            )
    }
}

//struct CardRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        let card = MCard()
//        let view = CardRowView(card: card)
//
//        return view
//    }
//}
