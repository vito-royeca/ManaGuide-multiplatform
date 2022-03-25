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
                HStack(spacing: 20) {
                    WebImage(url: card.imageURL(for: .artCrop))
                        .resizable()
                        .placeholder(Image(uiImage: ManaKit.shared.image(name: .cropBack)!))
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100, alignment: .center)
                        .cornerRadius(10)
                        .clipped()
                    
                    VStack(alignment: .leading) {
                        Text(card.displayName)
                            .font(Font.custom(font.name, size: font.size))
                        
                        if let manaCost = card.manaCost {
                            AttributedText(
                                NSAttributedString(symbol: manaCost, pointSize: 16)
                            )
                        }
                        
                        if !card.displayPowerToughness.isEmpty {
                            HStack {
                                Text(card.displayTypeLine)
                                    .font(.subheadline)
                                Spacer()
                                Text(card.displayPowerToughness)
                                    .font(.subheadline)
                            }
                        } else {
                            Text(card.displayTypeLine)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Text("Normal")
                                .font(.subheadline)
                                .foregroundColor(Color.blue)
                            Spacer()
                            Text(card.displayNormalPrice)
                                .font(.subheadline)
                                .foregroundColor(Color.blue)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("Foil")
                                .font(.subheadline)
                                .foregroundColor(Color.green)
                            Spacer()
                            Text(card.displayFoilPrice)
                                .font(.subheadline)
                                .foregroundColor(Color.green)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                    .padding(10)
                
                Divider()
                    .background(Color.secondary)
                
                HStack {
                    Text(card.displayKeyrune)
                        .font(Font.custom("Keyrune", size: 20))
                        .foregroundColor(Color(card.keyruneColor()))
                    Text("\u{2022} #\(card.collectorNumber ?? "") \u{2022} \(card.rarity?.name ?? "") \u{2022} \(card.language?.displayCode ?? "")")
                        .font(.footnote)
                    Spacer()
                    Button(action: {
                        print("button pressed")
                    }) {
                        Image(systemName: "ellipsis")
                            .renderingMode(.original)
                            .foregroundColor(Color(.systemBlue))
                    }
                        .buttonStyle(PlainButtonStyle())
                }
                    .padding(5)
            }
        }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary, lineWidth: 1)
            )
    }
}

struct CardRowView_Previews: PreviewProvider {
    static var previews: some View {
//        let viewModel = CardViewModel(newID: "sld_en_89")
//        viewModel.fetchData()

//        while viewModel.card == nil {
//            sleep(1)
//        }

//        if let card = viewModel.card {
//            return CardRowView(card: card)
//        }

        return Text("card not found")
    }
}
