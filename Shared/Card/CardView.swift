//
//  CardView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import CoreData
import LinkPresentation
import SwiftUI
import ManaKit
import SwiftUIPager
import SwiftUIX

struct CardView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingShareSheet = false
    @StateObject var viewModel: CardViewModel
    
    init(newID: String,
         relatedCards: [NSManagedObjectID]) {
        _viewModel = StateObject(wrappedValue: CardViewModel(newID: newID,
                                                             relatedCards: relatedCards))
    }
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    viewModel.fetchRemoteData()
                }
            } else {
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
            viewModel.fetchRemoteData()
        }
    }
    
    var compactView: some View {
        GeometryReader { proxy in
            if let card = viewModel.card,
               let cardObject = viewModel.find(MGCard.self, id: card) {
                List {
                    Section {
                        let width = proxy.size.width * 0.7
                        let height = proxy.size.height * 0.65
                        carouselView(card: card,
                                     width: width,
                                     height: height)
                    }
                    
                    if let prices = cardObject.prices?.allObjects as? [MGCardPrice] {
                        Section {
                            CardPricingInfoView(prices: prices)
                        }
                    }
                    
                    if let faces = cardObject.sortedFaces {
                        ForEach(faces) { face in
                            Section {
                                CardCommonInfoView(card: face)
                            }
                        }
                    } else {
                        Section {
                            CardCommonInfoView(card: cardObject)
                        }
                    }
                    
                    Section {
                        CardOtherInfoView(card: cardObject)
                    }
                    Section {
                        CardExtraInfoView(card: cardObject)
                    }
                }
                    .navigationBarTitle(Text(cardObject.displayName ?? ""))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        CardToolbar(presentationMode: presentationMode,
                                    isShowingShareSheet: $isShowingShareSheet)
                    }
                    .sheet(isPresented: $isShowingShareSheet, content: {
                        activityView
                    })
            } else {
                EmptyView()
            }
        }
    }
    
    var regularView: some View {
        GeometryReader { proxy in
            if let card = viewModel.card,
               let cardObject = viewModel.find(MGCard.self, id: card) {
                
                HStack(alignment: .top) {
                    let width = proxy.size.width * 0.7
                    let height = proxy.size.height * 0.5
                    
                    List {
                        carouselView(card: card,
                                     width: width,
                                     height: height)
                        
                        if let prices = cardObject.prices?.allObjects as? [MGCardPrice] {
                            Section {
                                CardPricingInfoView(prices: prices)
                            }
                        }
                    }
                
                    List {
                        if let faces = cardObject.sortedFaces {
                            ForEach(faces) { face in
                                Section {
                                    CardCommonInfoView(card: face)
                                }
                            }
                        } else {
                            Section {
                                CardCommonInfoView(card: cardObject)
                            }
                        }
                        
                        Section {
                            CardOtherInfoView(card: cardObject)
                        }
                        Section {
                            CardExtraInfoView(card: cardObject)
                        }
                    }
                    
                }
                    .navigationBarTitle(Text(cardObject.displayName ?? ""))
                    .toolbar {
                        CardToolbar(presentationMode: presentationMode,
                                    isShowingShareSheet: $isShowingShareSheet)
                    }
                    .sheet(isPresented: $isShowingShareSheet) {
                        activityView
                    }
            } else {
                EmptyView()
            }
        }
    }

    func carouselView(card: NSManagedObjectID, width: CGFloat, height: CGFloat) -> some View {
        Pager(page: Page.withIndex(viewModel.relatedCards.firstIndex(of: card) ?? 0),
              data: viewModel.relatedCards) { card in
            if let cardObject = viewModel.find(MGCard.self,
                                               id: card) {
                CardImageRowView(card: cardObject,
                                 style: .oneLine)
            }
        }
            .onPageChanged({ pageNumber in
                let card = viewModel.relatedCards[pageNumber]
                
                if let cardObject = viewModel.find(MGCard.self,
                                                   id: card) {
                    viewModel.newID = cardObject.newIDCopy
                    viewModel.fetchRemoteData()
                }
            })
            .itemSpacing(10)
            .itemAspectRatio(0.8)
            .interactive(scale: 0.8)
            .pagingPriority(.high)
            .frame(height: height)
    }
    
    var activityView: some View {
        var itemSources = [UIActivityItemSource]()
        
        if let card = viewModel.card,
           let cardObject = viewModel.find(MGCard.self,
                                           id: card) {
            itemSources.append(CardViewItemSource(card: cardObject))
        }

        return AppActivityView(activityItems: itemSources)
            .excludeActivityTypes([])
            .onCancel { }
            .onComplete { result in
                return
            }
    }
    
    func shareAction() {
        guard let card = viewModel.card,
           let cardObject = viewModel.find(MGCard.self,
                                           id: card) else {
            return
        }
        
        let itemSource = CardViewItemSource(card: cardObject)
        let activityVC = UIActivityViewController(activityItems: [itemSource],
                                                  applicationActivities: nil)

        let connectedScenes = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
        let window = connectedScenes.first?.windows.first { $0.isKeyWindow }

        window?.rootViewController?.present(activityVC, animated: true, completion: nil)
    }
}

// MARK: - CardToolbar
struct CardToolbar: ToolbarContent {
    @Binding var presentationMode: PresentationMode
    @Binding var isShowingShareSheet: Bool
    
    init(presentationMode: Binding<PresentationMode>,
         isShowingShareSheet: Binding<Bool>) {
        _presentationMode = presentationMode
        _isShowingShareSheet = isShowingShareSheet
    }
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button(action: {
                $presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .renderingMode(.original)
            }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: {
                isShowingShareSheet.toggle()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .renderingMode(.original)
            }
        }
    }
}

// MARK: - UIActivityItemSource

class CardViewItemSource: NSObject, UIActivityItemSource {
    let card: MGCard
    
    init(card: MGCard) {
        self.card = card
        super.init()
        
        // MARK: FIXME
//        if let url = card.imageURL(for: .artCrop),
//           SDImageCache.shared.imageFromCache(forKey: url.absoluteString) == nil {
//            SDWebImageDownloader.shared.downloadImage(with: url)
//        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return card.displayName ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // MARK: FIXME
//        guard let url = card.imageURL(for: .png),
//           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) else {
//            return nil
//        }
//        
//        return image
        
        return nil
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return card.displayName ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                thumbnailImageForActivityType activityType: UIActivity.ActivityType?,
                                suggestedSize size: CGSize) -> UIImage? {
        // MARK: FIXME
//        guard let url = card.imageURL(for: .artCrop),
//           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) else {
//            return nil
//        }
//        
//        return image
        return nil
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        
        // MARK: FIXME
//        if let url = card.imageURL(for: .artCrop),
//           let image = SDImageCache.shared.imageFromCache(forKey: url.absoluteString) {
//            metadata.iconProvider = NSItemProvider(object: image)
//        }
        metadata.title = card.displayName ?? ""
        
        return metadata
    }
}

// MARK: - Previews

#Preview {
    return NavigationView {
        CardView(newID: "rvr_en_273", relatedCards: [])
    }
    .previewInterfaceOrientation(.portraitUpsideDown)
}

// MARK: - CardPricingInfoView

struct CardPricingInfoView: View {
    @State var isPricingExpanded = false
    var prices: [MGCardPrice]
    
    var body: some View {
        CardPricingRowView(title: "Market Price",
                           normal: prices.filter({ !$0.isFoil }).map{ $0.market}.first ?? 0,
                           foil: prices.filter({ $0.isFoil }).map{ $0.market}.first ?? 0)
        DisclosureGroup("All TCGPlayer Prices", isExpanded: $isPricingExpanded) {
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
//                .font(.headline)
            Spacer()
            VStack(alignment: .trailing) {
                Text("Normal \(normal > 0 ? String(format: "$%.2f", normal) : "\u{2014}")")
//                    .font(.subheadline)
                    .foregroundColor(Color.blue)
                Spacer()
                Text("Foil \(foil > 0 ? String(format: "$%.2f", foil) : "\u{2014}")")
//                    .font(.subheadline)
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
//                    .font(.headline)
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
            DisclosureGroup("Colors", isExpanded: $isColorsExpanded) {
                ColorRowView(title: "Colors", colors: card.sortedColors)
                ColorRowView(title: "Color Identities", colors: card.sortedColorIdentities)
                ColorRowView(title: "Color Indicators", colors: card.sortedColorIndicators)
            }
            
            if let componentParts = card.sortedComponentParts {
                DisclosureGroup("Component Parts: \(componentParts.count)", isExpanded: $isComponentPartsExpanded) {
                    ForEach(componentParts) { componentPart in
                        if let part = componentPart.part,
                           let component = componentPart.component {

                            let newIDCopy = part.newIDCopy
                            let name = component.name
                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.headline)
                                CardListRowView(card: part)
                                    .background(NavigationLink("", destination: CardView(newID: newIDCopy, relatedCards: [])).opacity(0))
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }
            }

            if let frameEffects = card.sortedFrameEffects {
                DisclosureGroup("Frame Effects: \(frameEffects.count)", isExpanded: $isFrameEffectsExpanded) {
                    ForEach(frameEffects) { frameEffect in
                        Text(frameEffect.name ?? " ")
                    }
                }
            }

            if let formatLegalities = card.sortedFormatLegalities {
                DisclosureGroup("Legalities: \(formatLegalities.count)", isExpanded: $isLegalitiesExpanded) {
                    ForEach(formatLegalities) { formatLegality in
                        CardTextRowView(title: formatLegality.format?.name ?? " ",
                                        subtitle: formatLegality.legality?.name ?? " ")
                    }
                }
            }

            if let otherLanguages = card.sortedOtherLanguages {
                DisclosureGroup("Other Languages: \(otherLanguages.count)", isExpanded: $isOtherLanguagesExpanded) {
                    ForEach(otherLanguages) { otherLanguage in
                        CardListRowView(card: otherLanguage)
                            .background(NavigationLink("", destination: CardView(newID: otherLanguage.newIDCopy, relatedCards: [])).opacity(0))
                    }
                }
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
            }

            if let variations = card.sortedVariations {
                DisclosureGroup("Variations: \(variations.count)", isExpanded: $isVariationsExpanded) {
                    ForEach(variations) { variation in
                        CardListRowView(card: variation)
                            .background(NavigationLink("", destination: CardView(newID: variation.newIDCopy, relatedCards: [])).opacity(0))
                    }
                }
            }
            
            if let otherPrintings = card.sortedOtherPrintings {
                CardOtherPrintingsListView(card: card, otherPrintings: otherPrintings)
            }
        }
    }
}

// MARK: - CardPricingInfoView

struct CardOtherPrintingsListView: View {
    @State var isExpanded = false
    var card: MGCard
    var otherPrintings: [MGCard]

    var body: some View {
        DisclosureGroup("Other Printings", isExpanded: $isExpanded) {
            ForEach(otherPrintings) { otherPrinting in
                CardListRowView(card: otherPrinting)
                    .background(NavigationLink("", destination: CardView(newID: otherPrinting.newIDCopy,
                                                                         relatedCards: [])).opacity(0))
            }
            if otherPrintings.count >= 10 {
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
//                    .font(.headline)
                Spacer()
                Text(title)
//                    .font(.subheadline)
            }
        case .vertical:
            VStack(alignment: .leading) {
                Text(subtitle)
//                    .font(.headline)
                Spacer()
                Text(title)
//                    .font(.subheadline)
            }
        }
    }
}
