//
//  CardExtraInfoView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import SwiftUI
import CoreData
import ManaKit

struct CardExtraInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var isColorsExpanded         = true
    @State var isFrameEffectsExpanded   = true
    @State var isLegalitiesExpanded     = true
    @State var isRulingsExpanded        = true

    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        Group {
            DisclosureGroup("Colors",
                            isExpanded: $isColorsExpanded) {
                ColorRowView(title: "Colors", 
                             colors: card.sortedColors)
                ColorRowView(title: "Color Identities",
                             colors: card.sortedColorIdentities)
                ColorRowView(title: "Color Indicators",
                             colors: card.sortedColorIndicators)
            }
            
            if let frameEffects = card.sortedFrameEffects {
                DisclosureGroup("Frame Effects: \(frameEffects.count)",
                                isExpanded: $isFrameEffectsExpanded) {
                    ForEach(frameEffects) { frameEffect in
                        Text(frameEffect.name ?? " ")
                    }
                }
            }

            if let rulings = card.sortedRulings {
                DisclosureGroup("Rulings: \(rulings.count)",
                                isExpanded: $isRulingsExpanded) {
                    ForEach(rulings) { ruling in
                        LabeledContent {
                            AttributedText(
                                addColor(to: NSAttributedString(symbol: ruling.text ?? " ",
                                                                pointSize: 16),
                                         colorScheme: colorScheme)
                            )
                        } label: {
                            Text(ruling.displayDatePublished ?? " ")
                        }
                        .labeledContentStyle(.vertical)
                    }
                }
            }

            if let formatLegalities = card.sortedFormatLegalities {
                DisclosureGroup("Legalities: \(formatLegalities.count)",
                                isExpanded: $isLegalitiesExpanded) {
                    ForEach(formatLegalities) { formatLegality in
                        LabeledContent {
                            Text(formatLegality.legality?.name ?? String.emdash)
                        } label: {
                            Text(formatLegality.format?.name ?? String.emdash)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ColorRowView

struct ColorRowView: View {
    @Environment(\.colorScheme) var colorScheme
    var title: String
    var colors: [MGColor]?
    private var colorSymbols: String?
    
    init(title: String, colors: [MGColor]?) {
        self.title = title
        self.colors = colors
        
        if let colors = colors {
            colorSymbols = colors.map{ "{CI_\($0.symbol ?? "")}" }.joined(separator: "")
        } else {
            colorSymbols = String.emdash
        }
    }
    
    var body: some View {
        LabeledContent {
            if let colorSymbols = colorSymbols {
                AttributedText(
                    addColor(to: NSAttributedString(symbol: colorSymbols,
                                                    pointSize: 16),
                             colorScheme: colorScheme)
                )
                .multilineTextAlignment(.trailing)
            }
        } label: {
            Text(title)
        }
    }
}

