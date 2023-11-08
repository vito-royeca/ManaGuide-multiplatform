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
    @State var isColorsExpanded         = false
    @State var isComponentPartsExpanded = false
    @State var isFrameEffectsExpanded   = false
    @State var isLegalitiesExpanded     = false
    @State var isOtherLanguagesExpanded = false
    @State var isOtherPrintingsExpanded = false
    @State var isRulingsExpanded        = false
    @State var isVariationsExpanded     = false

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
            
            if let componentParts = card.sortedComponentParts {
                DisclosureGroup("Component Parts: \(componentParts.count)",
                                isExpanded: $isComponentPartsExpanded) {
                    ForEach(componentParts) { componentPart in
                        if let part = componentPart.part,
                           let component = componentPart.component {

                            let newIDCopy = part.newIDCopy
                            let name = component.name
                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.headline)
                                CardListRowView(card: part)
                                    .background(NavigationLink("",
                                                               destination: CardView(newID: newIDCopy,
                                                                                     relatedCards: [],
                                                                                     withCloseButton: false)).opacity(0))
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }
            }

            if let frameEffects = card.sortedFrameEffects {
                DisclosureGroup("Frame Effects: \(frameEffects.count)",
                                isExpanded: $isFrameEffectsExpanded) {
                    ForEach(frameEffects) { frameEffect in
                        Text(frameEffect.name ?? " ")
                    }
                }
            }

            if let formatLegalities = card.sortedFormatLegalities {
                DisclosureGroup("Legalities: \(formatLegalities.count)",
                                isExpanded: $isLegalitiesExpanded) {
                    ForEach(formatLegalities) { formatLegality in
                        CardTextRowView(title: formatLegality.format?.name ?? " ",
                                        subtitle: formatLegality.legality?.name ?? " ")
                    }
                }
            }

            if let otherLanguages = card.sortedOtherLanguages {
                DisclosureGroup("Other Languages: \(otherLanguages.count)",
                                isExpanded: $isOtherLanguagesExpanded) {
                    ForEach(otherLanguages) { otherLanguage in
                        CardListRowView(card: otherLanguage)
                            .background(NavigationLink("", destination: CardView(newID: otherLanguage.newIDCopy,
                                                                                 relatedCards: [],
                                                                                 withCloseButton: false)).opacity(0))
                    }
                }
            }

            if let rulings = card.sortedRulings {
                DisclosureGroup("Rulings: \(rulings.count)",
                                isExpanded: $isRulingsExpanded) {
                    ForEach(rulings) { ruling in
                        VStack(alignment: .leading) {
                            Text(ruling.displayDatePublished ?? " ")
                            Spacer()
                            AttributedText(
                                addColor(to: NSAttributedString(symbol: ruling.text ?? " ",
                                                                pointSize: 16),
                                         colorScheme: colorScheme)
                            )
                                .font(.subheadline)
                        }
                    }
                }
            }

            if let variations = card.sortedVariations {
                DisclosureGroup("Variations: \(variations.count)",
                                isExpanded: $isVariationsExpanded) {
                    ForEach(variations) { variation in
                        CardListRowView(card: variation)
                            .background(NavigationLink("",
                                                       destination: CardView(newID: variation.newIDCopy,
                                                                             relatedCards: variations.map { $0.objectID },
                                                                             withCloseButton: false)).opacity(0))
                    }
                }
            }
            
            if let otherPrintings = card.sortedOtherPrintings {
                let firstTen = otherPrintings.count >= 10 ?
                Array(otherPrintings[0...9]) : otherPrintings
                DisclosureGroup("Other Printings",
                                isExpanded: $isOtherPrintingsExpanded) {
                    ForEach(firstTen) { otherPrinting in
                        CardListRowView(card: otherPrinting)
                            .background(NavigationLink("",
                                                       destination: CardView(newID: otherPrinting.newIDCopy,
                                                                             relatedCards: firstTen.map { $0.objectID },
                                                                             withCloseButton: false)).opacity(0))
                    }
                    if firstTen.count >= 10 {
                        NavigationLink {
                            CardOtherPrintingsView(newID: card.newIDCopy,
                                                   languageCode: card.language?.code ?? "en")
                        } label: {
                            Text("View All")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ColorRowView

struct ColorRowView: View {
    var title: String
    var colors: [MGColor]?
    private var colorSymbols: String?
    
    init(title: String, colors: [MGColor]?) {
        self.title = title
        self.colors = colors
        
        if let colors = colors {
            colorSymbols = colors.map{ "{CI_\($0.symbol ?? "")}" }.joined(separator: "")
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
//                .font(.headline)
            Spacer()
            if let colorSymbols = colorSymbols {
                AttributedText(
                    NSAttributedString(symbol: colorSymbols, pointSize: 16)
                )
                .multilineTextAlignment(.trailing)
            }
        }
    }
}

