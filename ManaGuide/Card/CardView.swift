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
    @StateObject var viewModel: CardViewModel
    
    init(newID: String) {
        _viewModel = StateObject(wrappedValue: CardViewModel(newID: newID))
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                HStack(alignment: .center) {
                    Spacer()
                    WebImage(url: viewModel.card?.imageURL(for: .normal))
                        .resizable()
                        .placeholder(Image(uiImage: ManaKit.shared.image(name: .cardBack)!))
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()
                        .frame(width: geometry.size.width - (geometry.size.width / 4))
                    Spacer()
                }
                
                if let faces = viewModel.card?.sortedFaces,
                   faces.count > 1 {
                    ForEach(faces) { face in
                        Section {
                                CardCommonInfoView(card: face)
                        }
                    }
                } else {
                    if let card = viewModel.card {
                        Section {
                            CardCommonInfoView(card: card)
                        }
                    }
                }

                Section {
                    CardTextRowView(title: viewModel.card?.set?.name ?? " ", subtitle: "Set")
                    HStack {
                        Text("Set Symbol")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.card?.displayKeyrune ?? "")
                            .scaledToFit()
                            .font(Font.custom("Keyrune", size: 20))
                            .foregroundColor(Color(viewModel.card?.keyruneColor() ?? .black))
                    }
                    CardTextRowView(title: viewModel.card?.rarity?.name ?? " ", subtitle: "Rarity")
                    CardTextRowView(title: "#\(viewModel.card?.collectorNumber ?? " ")", subtitle: "Collector Number")
                    CardTextRowView(title: viewModel.card?.frame?.name ?? " ", subtitle: "Frame")
                    CardTextRowView(title: viewModel.card?.language?.name ?? " ", subtitle: "Language")
                    CardTextRowView(title: viewModel.card?.layout?.name ?? " ", subtitle: "Layout")
                    CardTextRowView(title: viewModel.card?.watermark?.name ?? " ", subtitle: "Watermark")
                }

                Group {
                    ColorRowView(title: "Colors", colors: viewModel.card?.sortedColors)
                    ColorRowView(title: "Color Identities", colors: viewModel.card?.sortedColorIdentities)
                    ColorRowView(title: "Color Indicators", colors: viewModel.card?.sortedColorIndicators)

                    if let count = viewModel.card?.sortedComponentParts?.count,
                        count > 0,
                        let componentParts = viewModel.card?.sortedComponentParts {
                        
                        Section(header: Text("Component Parts: \(count)")) {
                            ForEach(componentParts) { componentPart in
                                CardTextRowView(title: componentPart.part?.name ?? " ",
                                                subtitle: componentPart.component?.name ?? " ")
                            }
                        }
                    }
                    
                    if let count = viewModel.card?.sortedFormatLegalities?.count ?? 0,
                        count > 0,
                        let formatLegalities = viewModel.card?.sortedFormatLegalities {

                        Section(header: Text("Legalities: \(count)")) {
                            ForEach(formatLegalities) { formatLegality in
                                CardTextRowView(title: formatLegality.format?.name ?? " ",
                                                subtitle: formatLegality.legality?.name ?? " ")
                            }
                        }
                    }
                }

                Group {
                    if let count = viewModel.card?.sortedFrameEffects?.count ?? 0,
                        count > 0,
                        let frameEffects = viewModel.card?.sortedFrameEffects {
                        
                        Section(header: Text("Frame Effects: \(count)")) {
                            ForEach(frameEffects) { frameEffect in
                                Text(frameEffect.name ?? " ")
                            }
                        }
                    }
                    
                    if let count = viewModel.card?.sortedOtherLanguages?.count ?? 0,
                        count > 0,
                        let otherLanguages = viewModel.card?.sortedOtherLanguages {
                        
                        Section(header: Text("Other Languages: \(count)")) {
                            ForEach(otherLanguages) { otherLanguage in
                                Text(otherLanguage.language?.name ?? " ")
                            }
                        }
                    }
                    
                    if let count = viewModel.card?.sortedOtherPrintings?.count ?? 0,
                        count > 0,
                        let otherPrintings = viewModel.card?.sortedOtherPrintings {
                        
                        Section(header: Text("Other Printings: \(count)")) {
                            ForEach(otherPrintings) { otherPrinting in
                                HStack {
                                    Text(otherPrinting.set?.name ?? " ")
                                    Spacer()
                                    Text(otherPrinting.displayKeyrune)
                                        .scaledToFit()
                                        .font(Font.custom("Keyrune", size: 20))
                                        .foregroundColor(Color(otherPrinting.keyruneColor()))
                                }
                            }
                        }
                    }
                    
                    if let count = viewModel.card?.sortedRulings?.count ?? 0,
                        count > 0,
                        let rulings = viewModel.card?.sortedRulings {
                        
                        Section(header: Text("Rulings: \(count)")) {
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
                }

                Group {
                    if let count = viewModel.card?.sortedSubtypes?.count ?? 0,
                        count > 0,
                        let subtypes = viewModel.card?.sortedSubtypes {

                        Section(header: Text("Subtypes: \(count)")) {
                            ForEach(subtypes) { subtype in
                                Text(subtype.name ?? " ")
                            }
                        }
                    }
                    
                    if let count = viewModel.card?.sortedSupertypes?.count ?? 0,
                        count > 0,
                        let supertypes = viewModel.card?.sortedSupertypes {

                        Section(header: Text("Supertypes: \(count)")) {
                            ForEach(supertypes) { supertype in
                                Text(supertype.name ?? " ")
                            }
                        }
                    }
                    
                    if let count = viewModel.card?.sortedVariations?.count ?? 0,
                        count > 0,
                        let variations = viewModel.card?.sortedVariations {
                    
                        Section(header: Text("Variations: \(count)")) {
                            ForEach(variations) { variation in
                                Text(variation.collectorNumber ?? " ")
                            }
                        }
                    }
                }
            }
                .navigationBarTitle("Card Details")
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

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardView(newID: "unh_en_16")
        }
    }
}

enum CardTextRowViewStyle {
    case horizontal, vertical
}

struct CardCommonInfoView: View {
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
            Text(card.displayName)
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
            Text(card.displayTypeLine)
                .font(.subheadline)
        }
        HStack {
            Text("Power/Toughness")
                .font(.headline)
            Spacer()
            Text(card.displayPowerToughness)
                .font(.subheadline)
        }
        HStack {
            Text("Loyalty")
                .font(.headline)
            Spacer()
            Text(card.loyalty ?? "")
                .font(.subheadline)
        }
        VStack(alignment: .leading) {
            Text("Oracle Text")
                .font(.headline)
            Spacer()
            AttributedText(
                NSAttributedString(symbol: card.oracleText ?? " ", pointSize: 16)
            )
                .font(.subheadline)
        }
        VStack(alignment: .leading) {
            Text("Printed Text")
                .font(.headline)
            Spacer()
            AttributedText(
                NSAttributedString(symbol: card.printedText ?? " ", pointSize: 16)
            )
                .font(.subheadline)
        }
        VStack(alignment: .leading) {
            Text("Flavor Text")
                .font(.headline)
            Spacer()
            Text(card.displayFlavorText)
                .font(.subheadline)
                .italic()
        }
        HStack {
            Text("Artist")
                .font(.headline)
            Spacer()
            Text(card.artist?.name ?? "")
                .font(.subheadline)
        }
    }
}

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
