//
//  CardCommonInfoView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import SwiftUI
import ManaKit

struct CardCommonInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var isPrintedTextExpanded = false
    @State var isOracleTextExpanded = false
    let cmcFormatter = NumberFormatter()
    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
        
        cmcFormatter.minimumFractionDigits = 0
        cmcFormatter.maximumFractionDigits = 2
        cmcFormatter.numberStyle = .decimal
    }
    
    var body: some View {
        HStack {
            Text("Mana Cost")
//                .font(.headline)
            Spacer()
            AttributedText(
                NSAttributedString(symbol: card.displayManaCost,
                                   pointSize: 16)
            )
                .multilineTextAlignment(.trailing)
        }
        
        HStack {
            Text("Converted Mana Cost")
//                .font(.headline)
            Spacer()
            Text(cmcFormatter.string(from: card.cmc as NSNumber) ?? " ")
//                .font(.subheadline)
        }
        
        HStack {
            Text("Type")
//                .font(.headline)
            Spacer()
            Text(card.displayTypeLine ?? "")
//                .font(.subheadline)
        }
        
        if let displayPowerToughness = card.displayPowerToughness {
            HStack {
                Text("Power/Toughness")
//                    .font(.headline)
                Spacer()
                Text(displayPowerToughness)
//                    .font(.subheadline)
            }
        }
        
        if let loyalty = card.loyalty,
           !loyalty.isEmpty {
            HStack {
                Text("Loyalty")
//                    .font(.headline)
                Spacer()
                Text(loyalty)
//                    .font(.subheadline)
            }
        }

        if let printedText = card.printedText,
           !printedText.isEmpty {
            DisclosureGroup("Printed Text", isExpanded: $isPrintedTextExpanded) {
                AttributedText(
                    addColor(to: NSAttributedString(symbol: printedText, pointSize: 16), colorScheme: colorScheme)
                )
            }
        }

        if let oracleText = card.oracleText,
           !oracleText.isEmpty {
            DisclosureGroup("Oracle Text", isExpanded: $isOracleTextExpanded) {
                AttributedText(
                    addColor(to: NSAttributedString(symbol: oracleText,
                                                    pointSize: 16),
                             colorScheme: colorScheme)
                )
            }
        }
        
        if let flavorText = card.flavorText,
           !flavorText.isEmpty {
            VStack(alignment: .leading) {
                Text("Flavor Text")
//                    .font(.headline)
                Spacer()
                Text(flavorText)
//                    .font(.subheadline)
                    .italic()
            }
        }
    }
}

#Preview {
    let model = CardViewModel(newID: "isd_en_51",
                              relatedCards: [])
    Task {
        try await model.fetchRemoteData()
    }
    
    if let card = model.cardObject {
        return CardCommonInfoView(card: card)
    } else {
        return Text("Loading...")
    }
}
