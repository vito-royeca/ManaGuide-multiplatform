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
    
    var card: MGCard

    var body: some View {
        LabeledContent {
            AttributedText(
                NSAttributedString(symbol: card.displayManaCost,
                                   pointSize: 16)
            )
            .multilineTextAlignment(.trailing)
        } label: {
            Text("Mana Cost")
        }
        
        LabeledContent {
            Text(card.displayTypeLine ?? "")
        } label: {
            Text("Type")
        }

        if let printedText = card.printedText,
           !printedText.isEmpty {
            LabeledContent {
                AttributedText(
                    addColor(to: NSAttributedString(symbol: printedText,
                                                    pointSize: 16),
                             colorScheme: colorScheme)
                )
            } label: {
                Text("Printed Text")
            }
            .labeledContentStyle(.vertical)
        }

        if let oracleText = card.oracleText,
           !oracleText.isEmpty {
            LabeledContent {
                AttributedText(
                    addColor(to: NSAttributedString(symbol: oracleText,
                                                    pointSize: 16),
                             colorScheme: colorScheme)
                )
            } label: {
                Text("Oracle Text")
            }
            .labeledContentStyle(.vertical)
        }
        
        if let flavorText = card.flavorText,
           !flavorText.isEmpty {
            LabeledContent {
                Text(flavorText)
                    .italic()
            } label: {
                Text("Flavor Text")
            }
            .labeledContentStyle(.vertical)
        }
        
        if let displayPowerToughness = card.displayPowerToughness {
            LabeledContent {
                Text(displayPowerToughness)
            } label: {
                Text("Power/Toughness")
            }
        }
        
        if let loyalty = card.loyalty,
           !loyalty.isEmpty {
            LabeledContent {
                Text(loyalty)
            } label: {
                Text("Loyalty")
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
