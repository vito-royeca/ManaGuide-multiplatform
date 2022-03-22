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
    @StateObject var viewModel = CardViewModel()
    var newID: String
    
    init(newID: String) {
        self.newID = newID
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                Section {
                    WebImage(url: viewModel.card?.imageURL(for: .normal))
                        .resizable()
                        .placeholder(Image(uiImage: ManaKit.shared.image(name: .cropBack)!))
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()
                        .frame(width: geometry.size.width/2,
                               height: geometry.size.height/2,
                               alignment: .center)
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
                    CardTextRowView(title: (viewModel.card?.cmc ?? 0) == 0 ? " " : "\(viewModel.card?.cmc ?? 0)", subtitle: "Converted Mana Cost")
                    CardTextRowView(title: viewModel.card?.frame?.name ?? " ", subtitle: "Frame")
                    CardTextRowView(title: viewModel.card?.language?.name ?? " ", subtitle: "Language")
                    CardTextRowView(title: viewModel.card?.layout?.name ?? " ", subtitle: "Layout")
                    CardTextRowView(title: viewModel.card?.watermark?.name ?? " ", subtitle: "Watermark")
                }
                
                Group {
                    Section(header: Text("Colors: \(viewModel.card?.sortedColors?.count ?? 0)")) {
                        if let colors = viewModel.card?.sortedColors {
                            ForEach(colors) { color in
                                Text(color.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Color Identities: \(viewModel.card?.sortedColorIdentities?.count ?? 0)")) {
                        if let colors = viewModel.card?.sortedColorIdentities {
                            ForEach(colors) { color in
                                Text(color.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Color Indicators: \(viewModel.card?.sortedColorIndicators?.count ?? 0)")) {
                        if let colors = viewModel.card?.sortedColorIndicators {
                            ForEach(colors) { color in
                                Text(color.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Component Parts: \(viewModel.card?.sortedComponentParts?.count ?? 0)")) {
                        if let componentParts = viewModel.card?.sortedComponentParts {
                            ForEach(componentParts) { componentPart in
                                CardTextRowView(title: componentPart.part?.name ?? " ",
                                                subtitle: componentPart.component?.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Legalities: \(viewModel.card?.sortedFormatLegalities?.count ?? 0)")) {
                        if let formatLegalities = viewModel.card?.sortedFormatLegalities {
                            ForEach(formatLegalities) { formatLegality in
                                CardTextRowView(title: formatLegality.format?.name ?? " ",
                                                subtitle: formatLegality.legality?.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }
                
                Group {
                    Section(header: Text("Frame Effects: \(viewModel.card?.sortedFrameEffects?.count ?? 0)")) {
                        if let frameEffects = viewModel.card?.sortedFrameEffects {
                            ForEach(frameEffects) { frameEffect in
                                Text(frameEffect.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Other Languages: \(viewModel.card?.sortedOtherLanguages?.count ?? 0)")) {
                        if let otherLanguages = viewModel.card?.sortedOtherLanguages {
                            ForEach(otherLanguages) { otherLanguage in
                                Text(otherLanguage.language?.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Other Printings: \(viewModel.card?.sortedOtherPrintings?.count ?? 0)")) {
                        if let otherPrintings = viewModel.card?.sortedOtherPrintings {
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
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Rulings: \(viewModel.card?.sortedRulings?.count ?? 0)")) {
                        if let rulings = viewModel.card?.sortedRulings {
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
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Subtypes: \(viewModel.card?.sortedSubtypes?.count ?? 0)")) {
                        if let subtypes = viewModel.card?.sortedSubtypes {
                            ForEach(subtypes) { subtype in
                                Text(subtype.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }
                
                Group {
                    Section(header: Text("Supertypes: \(viewModel.card?.sortedSupertypes?.count ?? 0)")) {
                        if let supertypes = viewModel.card?.sortedSupertypes {
                            ForEach(supertypes) { supertype in
                                Text(supertype.name ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                    Section(header: Text("Variations: \(viewModel.card?.sortedVariations?.count ?? 0)")) {
                        if let variations = viewModel.card?.sortedVariations {
                            ForEach(variations) { variation in
                                Text(variation.collectorNumber ?? " ")
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }
            }
                .listStyle(.insetGrouped)
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
                    viewModel.newID = newID
                    viewModel.fetchData()
                }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
//        let api = MockAPI()
        let view = CardView(newID: "api.newID")
//        view.viewModel.dataAPI = api
        
        return view
    }
}

enum CardTextRowViewStyle {
    case horizontal, vertical
}

struct CardCommonInfoView: View {
    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
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
