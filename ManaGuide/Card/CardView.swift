//
//  CardView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct CardView: View {
    @ObservedObject var cardsViewModel: CardsViewModel
    @StateObject var viewModel: CardViewModel
    
    init(newID: String, cardsViewModel: CardsViewModel) {
        _viewModel = StateObject(wrappedValue: CardViewModel(newID: newID))
        self.cardsViewModel = cardsViewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                if let card = viewModel.card {
                    Section {
                        WebImage(url: card.imageURL(for: .normal), options: [SDWebImageOptions.lowPriority])
                            .resizable()
                            .placeholder(Image(uiImage: ManaKit.shared.image(name: .cardBack)!))
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .aspectRatio(contentMode: .fill)
                            .cornerRadius(10)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.clear, lineWidth: 0)
                            )
                    }
                    
                    if let prices = card.prices?.allObjects as? [MGCardPrice] {
                        Section {
                            CardPricingInfoView(prices: prices)
                        }
                    }
                    
                    if let faces = card.sortedFaces,
                       faces.count > 1 {
                        ForEach(faces) { face in
                            Section {
                                CardCommonInfoView(card: face)
                            }
                        }
                    } else {
                        Section {
                            CardCommonInfoView(card: card)
                        }
                    }
                    
                    Section {
                        CardOtherInfoView(card: card)
                    }
                    Section {
                        CardExtraInfoView(card: card, cardsViewModel: cardsViewModel)
                    }
                } else {
                    EmptyView()
                }
            }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: {
                            print("button pressed")
                        }) {
                            Image(systemName: "ellipsis")
                                .renderingMode(.original)
                        }
                    }
                }
                .overlay(
                    Group {
                        if viewModel.isBusy {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            EmptyView()
                        }
                })
                .onAppear {
                    viewModel.fetchData()
                }
        }
    }
}

// MARK: - Previews

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            let model = SetViewModel(setCode: "ulg", languageCode: "en")
            CardView(newID: "lea_en_46",
                     cardsViewModel: model)
                .onAppear {
                    model.fetchData()
                }
        }
    }
}

// MARK: - CardPricingInfoView

struct CardPricingInfoView: View {
    @State var isPricingExpanded = false
    var prices: [MGCardPrice]
    
    var body: some View {
        
        CardPricingRowView(title: "Market",
                           normal: prices.filter({ !$0.isFoil }).map{ $0.market}.first ?? 0,
                           foil: prices.filter({ $0.isFoil }).map{ $0.market}.first ?? 0)
        
        DisclosureGroup("Other TCGPlayer Prices", isExpanded: $isPricingExpanded) {
            CardPricingRowView(title: "Low",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.low}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.low}.first ?? 0)
            CardPricingRowView(title: "Median",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.median}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.median}.first ?? 0)
            CardPricingRowView(title: "High",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.high}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.high}.first ?? 0)
            CardPricingRowView(title: "Direct Low",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.directLow}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.directLow}.first ?? 0)
        }
    }
}

// MARK: - CardPricingRowView

struct CardPricingRowView: View {
    var title: String
    var normal: Double
    var foil: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            VStack(alignment: .trailing) {
                Text("Normal \(normal > 0 ? String(format: "$%.2f", normal) : "\u{2014}")")
                    .font(.subheadline)
                    .foregroundColor(Color.blue)
                Spacer()
                Text("Foil \(foil > 0 ? String(format: "$%.2f", foil) : "\u{2014}")")
                    .font(.subheadline)
                    .foregroundColor(Color.green)
            }
        }
    }
}

// MARK: - CardCommonInfoView

enum CardTextRowViewStyle {
    case horizontal, vertical
}

struct CardCommonInfoView: View {
    @Environment(\.colorScheme) var colorScheme
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
            Text("Name")
                .font(.headline)
            Spacer()
            Text(card.displayName ?? "")
                .font(.subheadline)
        }

        HStack {
            Text("Mana Cost")
                .font(.headline)
            Spacer()
            AttributedText(
                NSAttributedString(symbol: card.manaCost ?? " ", pointSize: 16)
            )
                .multilineTextAlignment(.trailing)
        }
        
        HStack {
            Text("Converted Mana Cost")
                .font(.headline)
            Spacer()
            Text(cmcFormatter.string(from: card.cmc as NSNumber) ?? " ")
                .font(.subheadline)
        }
        
        HStack {
            Text("Type")
                .font(.headline)
            Spacer()
            Text(card.displayTypeLine ?? "")
                .font(.subheadline)
        }
        
        if let displayPowerToughness = card.displayPowerToughness {
            HStack {
                Text("Power/Toughness")
                    .font(.headline)
                Spacer()
                Text(displayPowerToughness)
                    .font(.subheadline)
            }
        }
        
        if let loyalty = card.loyalty,
           !loyalty.isEmpty {
            HStack {
                Text("Loyalty")
                    .font(.headline)
                Spacer()
                Text(loyalty)
                    .font(.subheadline)
            }
        }

        if let printedText = card.printedText,
           !printedText.isEmpty {
            VStack(alignment: .leading) {
                Text("Printed Text")
                    .font(.headline)
                Spacer()
                AttributedText(
                    addColor(to: NSAttributedString(symbol: printedText, pointSize: 16))
                )
                    .font(.subheadline)
            }
        }

        if let oracleText = card.oracleText,
           !oracleText.isEmpty {
            VStack(alignment: .leading) {
                Text("Oracle Text")
                    .font(.headline)
                Spacer()
                AttributedText(
                    addColor(to: NSAttributedString(symbol: oracleText, pointSize: 16))
                )
                    .font(.subheadline)
            }
        }
        
        if let flavorText = card.flavorText,
           !flavorText.isEmpty {
            VStack(alignment: .leading) {
                Text("Flavor Text")
                    .font(.headline)
                Spacer()
                Text(flavorText)
                    .font(.subheadline)
                    .italic()
            }
        }
        
        HStack {
            Text("Artist")
                .font(.headline)
            Spacer()
            Text(card.artist?.name ?? "")
                .font(.subheadline)
        }
    }
    
    func addColor(to attributedString: NSAttributedString) -> NSAttributedString {
        let newAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        let range = NSRange(location: 0, length: newAttributedString.string.count)
        let color = colorScheme == .dark ? UIColor.white : UIColor.black
        newAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        
        return newAttributedString
    }
}

// MARK: - CardOtherInfoView

struct CardOtherInfoView: View {
    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        Group {
            CardTextRowView(title: card.set?.name ?? " ", subtitle: "Set")
            
            HStack {
                Text("Set Symbol")
                    .font(.headline)
                Spacer()
                Text(card.displayKeyrune)
                    .scaledToFit()
                    .font(Font.custom("Keyrune", size: 20))
                    .foregroundColor(Color(card.keyruneColor()))
            }
            
            CardTextRowView(title: card.rarity?.name ?? " ", subtitle: "Rarity")
            
            CardTextRowView(title: "#\(card.collectorNumber ?? " ")", subtitle: "Collector Number")
            
            if let frame = card.frame {
                CardTextRowView(title: frame.name ?? " ", subtitle: "Frame")
            }

            if let language = card.language {
                CardTextRowView(title: language.name ?? " ", subtitle: "Language")
            }
            
            if let layout = card.layout {
                CardTextRowView(title: layout.name ?? " ", subtitle: "Layout")
            }

            if let watermark = card.watermark {
                CardTextRowView(title: watermark.name ?? " ", subtitle: "Watermark")
            }
        }
    }
}

// MARK: - CardExtraInfoView

struct CardExtraInfoView: View {
    @ObservedObject var cardsViewModel: CardsViewModel
    @State var isColorsExpanded         = false
    @State var isComponentPartsExpanded = false
    @State var isFrameEffectsExpanded   = false
    @State var isLegalitiesExpanded     = false
    @State var isOtherLanguagesExpanded = true
    @State var isOtherPrintingsExpanded = true
    @State var isRulingsExpanded        = false
    @State var isSubtypesExpanded       = false
    @State var isSupertypesExpanded     = false
    @State var isVariationsExpanded     = true
    
    var card: MGCard
    
    init(card: MGCard, cardsViewModel: CardsViewModel) {
        self.card = card
        self.cardsViewModel = cardsViewModel
    }
    
    var body: some View {
        Group {
            DisclosureGroup("Colors", isExpanded: $isColorsExpanded) {
                ColorRowView(title: "Colors", colors: card.sortedColors)
                ColorRowView(title: "Color Identities", colors: card.sortedColorIdentities)
                ColorRowView(title: "Color Indicators", colors: card.sortedColorIndicators)
            }
            
            if let count = card.sortedComponentParts?.count,
                count > 0,
                let componentParts = card.sortedComponentParts {

                DisclosureGroup("Component Parts: \(count)", isExpanded: $isComponentPartsExpanded) {
                    ForEach(componentParts) { componentPart in
                        NavigationLink(destination: CardView(newID: componentPart.part?.newIDCopy ?? "", cardsViewModel: cardsViewModel)) {
                            CardTextRowView(title: componentPart.part?.name ?? " ",
                                            subtitle: componentPart.component?.name ?? " ")
                        }
                    }
                }
            }

            if let count = card.sortedFrameEffects?.count ?? 0,
                count > 0,
                let frameEffects = card.sortedFrameEffects {

                DisclosureGroup("Frame Effects: \(count)", isExpanded: $isFrameEffectsExpanded) {
                    ForEach(frameEffects) { frameEffect in
                        Text(frameEffect.name ?? " ")
                    }
                }
            }

            if let count = card.sortedFormatLegalities?.count ?? 0,
                count > 0,
                let formatLegalities = card.sortedFormatLegalities {

                DisclosureGroup("Legalities: \(count)", isExpanded: $isLegalitiesExpanded) {
                    ForEach(formatLegalities) { formatLegality in
                        CardTextRowView(title: formatLegality.format?.name ?? " ",
                                        subtitle: formatLegality.legality?.name ?? " ")
                    }
                }
            }

            if let count = card.sortedOtherLanguages?.count ?? 0,
                count > 0,
                let otherLanguages = card.sortedOtherLanguages {

                DisclosureGroup("Other Languages: \(count)", isExpanded: $isOtherLanguagesExpanded) {
                    ForEach(otherLanguages) { otherLanguage in
                        CardListRowView(card: otherLanguage)
                            .background(NavigationLink("", destination: CardView(newID: otherLanguage.newIDCopy, cardsViewModel: cardsViewModel)).opacity(0))
                    }
                }
            }

            if let count = card.sortedOtherPrintings?.count ?? 0,
                count > 0,
                let otherPrintings = card.sortedOtherPrintings {

                DisclosureGroup("Other Printings: \(count)", isExpanded: $isOtherPrintingsExpanded) {
                    ForEach(otherPrintings) { otherPrinting in
                        CardListRowView(card: otherPrinting)
                            .background(NavigationLink("", destination: CardView(newID: otherPrinting.newIDCopy, cardsViewModel: cardsViewModel)).opacity(0))
                    }
                }
            }

            if let count = card.sortedRulings?.count ?? 0,
                count > 0,
                let rulings = card.sortedRulings {

                DisclosureGroup("Rulings: \(count)", isExpanded: $isRulingsExpanded) {
                    ForEach(rulings) { ruling in
                        VStack(alignment: .leading) {
                            Text(ruling.datePublished ?? " ")
                            Spacer()
                            AttributedText(
                                NSAttributedString(symbol: ruling.text ?? " ", pointSize: 16)
                            )
                                .font(.subheadline)
                        }
                    }
                }
            }

            if let count = card.sortedSubtypes?.count ?? 0,
                count > 0,
                let subtypes = card.sortedSubtypes {

                DisclosureGroup("Subtypes: \(count)", isExpanded: $isSubtypesExpanded) {
                    ForEach(subtypes) { subtype in
                        Text(subtype.name ?? " ")
                    }
                }
            }

            if let count = card.sortedSupertypes?.count ?? 0,
                count > 0,
                let supertypes = card.sortedSupertypes {

                DisclosureGroup("Supertypes: \(count)", isExpanded: $isSupertypesExpanded) {
                    ForEach(supertypes) { supertype in
                        Text(supertype.name ?? " ")
                    }
                }
            }

            if let count = card.sortedVariations?.count ?? 0,
                count > 0,
                let variations = card.sortedVariations {

                DisclosureGroup("Variations: \(count)", isExpanded: $isVariationsExpanded) {
                    ForEach(variations) { variation in
                        CardListRowView(card: variation)
                            .background(NavigationLink("", destination: CardView(newID: variation.newIDCopy, cardsViewModel: cardsViewModel)).opacity(0))
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
                .font(.headline)
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

struct CardTextRowView: View {
    var title: String
    var subtitle: String
    var style: CardTextRowViewStyle
    
    init(title: String, subtitle: String, style: CardTextRowViewStyle = .horizontal) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .horizontal:
            HStack {
                Text(subtitle)
                    .font(.headline)
                Spacer()
                Text(title)
                    .font(.subheadline)
            }
        case .vertical:
            VStack(alignment: .leading) {
                Text(subtitle)
                    .font(.headline)
                Spacer()
                Text(title)
                    .font(.subheadline)
            }
        }
    }
}
