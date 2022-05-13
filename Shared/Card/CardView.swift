//
//  CardView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import LinkPresentation
import SwiftUI
import ManaKit
import SDWebImage
import SDWebImageSwiftUI
import SwiftUIX

struct CardView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: CardViewModel
    @State private var isShowingShareSheet = false
    
    init(newID: String) {
        _viewModel = StateObject(wrappedValue: CardViewModel(newID: newID))
    }
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    viewModel.fetchData()
                }
            } else {
//                bodyData
                #if os(iOS)
                if horizontalSizeClass == .compact {
                    compactView
                } else {
                    regularView
                }
                #else
                regularView
                #endif
            }
        }
            .onAppear {
                viewModel.fetchData()
            }
    }
    
    var compactView: some View {
        List {
            if let card = viewModel.card {
                Section {
                    CardImageRowView(card: card, style: .oneLine)
                }
                
                if let prices = card.prices?.allObjects as? [MGCardPrice] {
                    Section {
                        CardPricingInfoView(prices: prices)
                    }
                }
                
                if let faces = card.sortedFaces {
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
                    CardExtraInfoView(card: card)
                }
            } else {
                EmptyView()
            }
        }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .renderingMode(.original)
                            .foregroundColor(Color.accentColor)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isShowingShareSheet.toggle()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .renderingMode(.original)
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .sheet(isPresented: $isShowingShareSheet, onDismiss: {
                print("Dismiss")
            }, content: {
                let itemSource = CardViewItemSource(card: viewModel.card!)

                AppActivityView(activityItems: [itemSource])
                    .excludeActivityTypes([])
                    .onCancel { }
                    .onComplete { result in
                        return
                    }
            })
    }
    
    var regularView: some View {
        HStack(alignment: .top) {
            if let card = viewModel.card {
                CardImageRowView(card: card, style: .oneLine)
                    .padding()

                List {
                    if let prices = card.prices?.allObjects as? [MGCardPrice] {
                        Section {
                            CardPricingInfoView(prices: prices)
                        }
                    }
                    
                    if let faces = card.sortedFaces {
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
                        CardExtraInfoView(card: card)
                    }
                }
            } else {
                EmptyView()
            }
        }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .renderingMode(.original)
                            .foregroundColor(Color.accentColor)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isShowingShareSheet.toggle()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .renderingMode(.original)
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .sheet(isPresented: $isShowingShareSheet, onDismiss: {
                print("Dismiss")
            }, content: {
                let itemSource = CardViewItemSource(card: viewModel.card!)

                AppActivityView(activityItems: [itemSource])
                    .excludeActivityTypes([])
                    .onCancel { }
                    .onComplete { result in
                        return
                    }
            })
    }

    func shareAction() {
        guard let card = viewModel.card else {
            return
        }
        
        let itemSource = CardViewItemSource(card: card)
        let activityVC = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)

        let connectedScenes = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
        let window = connectedScenes.first?.windows.first { $0.isKeyWindow }

        window?.rootViewController?.present(activityVC, animated: true, completion: nil)
    }
}

// MARK: - UIActivityItemSource

class CardViewItemSource: NSObject, UIActivityItemSource {
    let card: MGCard
    
    init(card: MGCard) {
        self.card = card
        super.init()
        
        if let url = card.imageURL(for: .artCrop),
           SDImageCache.shared.imageFromCache(forKey: url.absoluteString) == nil {
            SDWebImageDownloader.shared.downloadImage(with: url)
        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        
        return card.displayName ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        
        guard let url = card.imageURL(for: .png),
           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) else {
            return nil
        }
        
        return image
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return card.displayName ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        guard let url = card.imageURL(for: .artCrop),
           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) else {
            return nil
        }
        
        return image
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        
        if let url = card.imageURL(for: .artCrop),
           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) {
            metadata.iconProvider = NSItemProvider(object: image)
        }
        metadata.title = card.displayName ?? ""
        
        return metadata
    }
}

// MARK: - Previews

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            let model = SetViewModel(setCode: "isd", languageCode: "en")
            CardView(newID: "isd_en_51"/*,
                     cardsViewModel: model*/)
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
        DisclosureGroup("TCGPlayer Prices", isExpanded: $isPricingExpanded) {
            CardPricingRowView(title: "Market",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.market}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.market}.first ?? 0)
            CardPricingRowView(title: "Direct Low",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.directLow}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.directLow}.first ?? 0)
            CardPricingRowView(title: "Low",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.low}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.low}.first ?? 0)
            CardPricingRowView(title: "Median",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.median}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.median}.first ?? 0)
            CardPricingRowView(title: "High",
                               normal: prices.filter({ !$0.isFoil }).map{ $0.high}.first ?? 0,
                               foil: prices.filter({ $0.isFoil }).map{ $0.high}.first ?? 0)
        }
            .accentColor(Color.accentColor)
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
    @State var isTypesExpanded = false
    let cmcFormatter = NumberFormatter()
    var card: MGCard
    private let font: ManaKit.Font
    
    init(card: MGCard) {
        self.card = card
        font = card.nameFont
        
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
                .font(Font.custom(font.name, size: font.size))
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
                    addColor(to: NSAttributedString(symbol: printedText, pointSize: 16), colorScheme: colorScheme)
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
                    addColor(to: NSAttributedString(symbol: oracleText, pointSize: 16), colorScheme: colorScheme)
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
                    .foregroundColor(Color(card.keyruneColor))
            }
            
            CardTextRowView(title: card.rarity?.name ?? " ", subtitle: "Rarity")
            
            CardTextRowView(title: "#\(card.collectorNumber ?? " ")", subtitle: "Collector Number")
            
            CardTextRowView(title: card.artist?.name ?? " ", subtitle: "Artist")
            
            if let frame = card.frame {
                CardTextRowView(title: frame.name ?? " ", subtitle: "Frame")
            }

            if let language = card.language {
                CardTextRowView(title: language.name ?? " ", subtitle: "Language")
            }
            
            if let layout = card.layout {
                CardTextRowView(title: layout.name ?? " ", subtitle: "Layout")
            }

            if let releaseDate = card.displayReleaseDate {
                CardTextRowView(title: releaseDate, subtitle: "Release Date")
            }
            
            if let watermark = card.watermark {
                CardTextRowView(title: watermark.name ?? " ", subtitle: "Watermark")
            }
        }
    }
}

// MARK: - CardExtraInfoView

struct CardExtraInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var isColorsExpanded         = true
    @State var isComponentPartsExpanded = false
    @State var isFrameEffectsExpanded   = true
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
            DisclosureGroup("Colors", isExpanded: $isColorsExpanded) {
                ColorRowView(title: "Colors", colors: card.sortedColors)
                ColorRowView(title: "Color Identities", colors: card.sortedColorIdentities)
                ColorRowView(title: "Color Indicators", colors: card.sortedColorIndicators)
            }
                .accentColor(Color.accentColor)
            
            if let componentParts = card.sortedComponentParts {
                DisclosureGroup("Component Parts: \(componentParts.count)", isExpanded: $isComponentPartsExpanded) {
                    ForEach(componentParts) { componentPart in
                        if let part = componentPart.part,
                           let newIDCopy = part.newIDCopy,
                           let component = componentPart.component,
                           let name = component.name {
                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.headline)
                                CardListRowView(card: part)
                                    .background(NavigationLink("", destination: CardView(newID: newIDCopy)).opacity(0))
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }
                    .accentColor(Color.accentColor)
            }

            if let frameEffects = card.sortedFrameEffects {
                DisclosureGroup("Frame Effects: \(frameEffects.count)", isExpanded: $isFrameEffectsExpanded) {
                    ForEach(frameEffects) { frameEffect in
                        Text(frameEffect.name ?? " ")
                    }
                }
                    .accentColor(Color.accentColor)
            }

            if let formatLegalities = card.sortedFormatLegalities {
                DisclosureGroup("Legalities: \(formatLegalities.count)", isExpanded: $isLegalitiesExpanded) {
                    ForEach(formatLegalities) { formatLegality in
                        CardTextRowView(title: formatLegality.format?.name ?? " ",
                                        subtitle: formatLegality.legality?.name ?? " ")
                    }
                }
                    .accentColor(Color.accentColor)
            }

            if let otherLanguages = card.sortedOtherLanguages {
                DisclosureGroup("Other Languages: \(otherLanguages.count)", isExpanded: $isOtherLanguagesExpanded) {
                    ForEach(otherLanguages) { otherLanguage in
                        CardListRowView(card: otherLanguage)
                            .background(NavigationLink("", destination: CardView(newID: otherLanguage.newIDCopy)).opacity(0))
                    }
                }
                    .accentColor(Color.accentColor)
            }

            if let otherPrintings = card.sortedOtherPrintings {
                DisclosureGroup("Other Printings: \(otherPrintings.count)", isExpanded: $isOtherPrintingsExpanded) {
                    ForEach(otherPrintings) { otherPrinting in
                        CardListRowView(card: otherPrinting)
                            .background(NavigationLink("", destination: CardView(newID: otherPrinting.newIDCopy)).opacity(0))
                    }
                }
                    .accentColor(Color.accentColor)
            }

            if let rulings = card.sortedRulings {
                DisclosureGroup("Rulings: \(rulings.count)", isExpanded: $isRulingsExpanded) {
                    ForEach(rulings) { ruling in
                        VStack(alignment: .leading) {
                            Text(ruling.displayDatePublished ?? " ")
                            Spacer()
                            AttributedText(
                                addColor(to: NSAttributedString(symbol: ruling.text ?? " ", pointSize: 16), colorScheme: colorScheme)
                            )
                                .font(.subheadline)
                        }
                    }
                }
                    .accentColor(Color.accentColor)
            }

            if let variations = card.sortedVariations {
                DisclosureGroup("Variations: \(variations.count)", isExpanded: $isVariationsExpanded) {
                    ForEach(variations) { variation in
                        CardListRowView(card: variation)
                            .background(NavigationLink("", destination: CardView(newID: variation.newIDCopy)).opacity(0))
                    }
                }
                    .accentColor(Color.accentColor)
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

// MARK: - CardTextRowView

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
