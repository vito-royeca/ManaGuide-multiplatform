//
//  CardsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI
import SwiftUIPager

struct CardsView<Content> : View where Content : View {
    
    // MARK: - Variables
    
    @StateObject var viewModel: CardsViewModel
    @State private var showingSort = false
    @State private var showingDisplay = false
    @AppStorage("cardsSort") private var sort = CardsViewSort.name
    @AppStorage("cardsDisplay") private var display = CardsViewDisplay.list

    private var content: Content
    
    // MARK: - Initializers
    
    init(viewModel: CardsViewModel, @ViewBuilder content: @escaping () -> Content) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    viewModel.fetchData()
                }
            } else {
                bodyData
            }
        }
            .onAppear {
                viewModel.sort = sort
                viewModel.display = display
                viewModel.fetchData()
            }
    }
    
    var bodyData: some View {
        CardsDataView(sort: sort, display: display, viewModel: viewModel) {
            content
        }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSort.toggle()
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                        .actionSheet(isPresented: $showingSort) {
                            sortActionSheet
                        }
                        .foregroundColor(Color.accentColor)

                    Button(action: {
                        showingDisplay.toggle()
                    }) {
                        Image(systemName: "list.bullet.below.rectangle")
                    }
                        .actionSheet(isPresented: $showingDisplay) {
                            displayActionSheet
                        }
                        .foregroundColor(Color.accentColor)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewSort)) { (output) in
                viewModel.fetchLocalData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewDisplay)) { (output) in
                viewModel.fetchLocalData()
            }
            .modifier(SectionIndex(sections: viewModel.sections, sectionIndexTitles: viewModel.sectionIndexTitles))
    }
}

// MARK: - Previews

struct CardsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardsView(viewModel: SetViewModel(setCode: "afr", languageCode: "en")) {
                EmptyView()
            }
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}

// MARK: - CardsDataView

struct CardsDataView<Content> : View where Content : View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @StateObject var page1: Page = .first()
    @State private var selectedCard: MGCard? = nil
    
    private var sort: CardsViewSort
    private var display: CardsViewDisplay
    private var viewModel: CardsViewModel
    private var content: Content
    
    init(sort: CardsViewSort, display: CardsViewDisplay, viewModel: CardsViewModel, @ViewBuilder content: @escaping () -> Content) {
        self.sort = sort
        self.display = display
        self.viewModel = viewModel
        self.content = content()
    }
    
    var body: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            listView
        } else {
            gridView
        }
        #else
        gridView
        #endif
    }
    
    func stickyHeaderView(_ text: String) -> some View {
        VStack(alignment: .leading) {
            Text(text)
                .foregroundColor(Color.gray)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
                .multilineTextAlignment(.leading)
            
        }
    }
    
    // MARK: - listView
    
    var listView: some View {
        GeometryReader { geometryProxy in
            switch display {
            case .imageCarousel:
                let width = min(geometryProxy.size.height, geometryProxy.size.width)
                let height = geometryProxy.size.height
                listCarouselView(width: width, height: height)
            case .imageGrid:
                listImageView()
            default:
                List {
                    content
                        .listRowSeparator(.hidden)
                    switch sort {
                    case .collectorNumber:
                        ForEach(viewModel.cards) { card in
                            let tap = TapGesture()
                                .onEnded { _ in
                                    self.selectedCard = card
                                }

                            switch display {
                            case .list:
                                CardListRowView(card: card)
                                    .gesture(tap)
                            case .summary:
                                CardSummaryRowView(card: card)
                                    .gesture(tap)
                                    .listRowSeparator(.hidden)
                                    .padding(.bottom)
                            default:
                                EmptyView()
                            }
                        }

                    case .name,
                         .rarity,
                         .setName,
                         .setReleaseDate,
                         .type:
                        ForEach(viewModel.sections, id: \.name) { section in
                            Section(header: Text(section.name)) {
                                ForEach(section.objects as? [MGCard] ?? []) { card in
                                    let tap = TapGesture()
                                        .onEnded { _ in
                                            self.selectedCard = card
                                        }

                                    switch display {
                                    case .list:
                                        CardListRowView(card: card)
                                            .gesture(tap)
                                    case .summary:
                                        CardSummaryRowView(card: card)
                                            .gesture(tap)
                                            .listRowSeparator(.hidden)
                                            .padding(.bottom)
                                    default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                }
                    .listStyle(.plain)
                    .sheet(item: $selectedCard) { selectedCard in
                        NavigationView {
                            CardView(newID: selectedCard.newIDCopy)
                        }
                    }
            }
        }
    }
    
    func listCarouselView(width: CGFloat, height: CGFloat) -> some View {
        ScrollView {
            content
                .padding()
            Pager(page: page1,
                  data: viewModel.cards,
                  id: \.newIDCopy) { card in
                CardImageRowView(card: card, style: .oneLine)
            }
                .itemSpacing(10)
                .itemAspectRatio(0.8, alignment: .start(50))
                .pagingPriority(.high)
                .frame(width: width, height: height)
        }
    }
    
    func listImageView() -> some View {
        ScrollView() {
            content
                .padding()
            LazyVGrid(columns: [GridItem](repeating: GridItem(), count: 2), spacing: 10, pinnedViews: [.sectionHeaders]) {
                switch sort {
                case .collectorNumber:
                    ForEach(viewModel.cards) { card in
                        CardImageRowView(card: card, style: .twoLines)
                    }
                case .name,
                     .rarity,
                     .setName,
                     .setReleaseDate,
                     .type:
                    ForEach(viewModel.sections, id: \.name) { section in
                        Section(header: stickyHeaderView(section.name)) {
                            ForEach(section.objects as? [MGCard] ?? []) { card in
                                CardImageRowView(card: card, style: .twoLines)
                           }
                       }
                   }
               }
           }
              .padding()
        }
    }
    
    // MARK: - gridView

    var gridView: some View {
        GeometryReader { geometryProxy in
            switch display {
            case .imageCarousel:
                let width = geometryProxy.size.width
                let height = geometryProxy.size.height * 0.8
                gridCarouselView(width: width, height: height)
            case .imageGrid:
                let width = geometryProxy.size.width
                let height = geometryProxy.size.height / 3
                gridImageView(width: width, height: height)
            default:
                List {
                    content
                        .listRowSeparator(.hidden)
                    switch sort {
                    case .collectorNumber:
                        ForEach(viewModel.cards) { card in
                            let tap = TapGesture()
                                .onEnded { _ in
                                    self.selectedCard = nil
                                }

                            switch display {
                            case .list:
                                CardListRowView(card: card)
                                    .gesture(tap)
                            case .summary:
                                CardSummaryRowView(card: card)
                                    .gesture(tap)
                                    .listRowSeparator(.hidden)
                                    .padding(.bottom)
                            default:
                                EmptyView()
                            }
                        }

                    case .name,
                         .rarity,
                         .setName,
                         .setReleaseDate,
                         .type:
                        ForEach(viewModel.sections, id: \.name) { section in
                            Section(header: Text(section.name)) {
                                switch display {
                                case .list:
                                    gridListView(cards: section.objects as? [MGCard] ?? [])
                                case .summary:
                                    let width = geometryProxy.size.width
                                    let height = geometryProxy.size.height / 3
                                    let cards = section.objects as? [MGCard] ?? []

                                    gridSummaryView(cards: cards, width: width, height: height)
                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
                    .listStyle(.plain)
                    .sheet(item: $selectedCard) { selectedCard in
                        NavigationView {
                            CardView(newID: selectedCard.newIDCopy)
                        }
                    }
            }
        }
    }
    
    func gridCarouselView(width: CGFloat, height: CGFloat) -> some View {
        return ScrollView {
            content
                .padding()
            Pager(page: page1,
                  data: viewModel.cards,
                  id: \.newIDCopy) { card in
                CardImageRowView(card: card, style: .oneLine)
            }
                  .preferredItemSize(CGSize(width: width * 0.25, height: height))
//                .itemAspectRatio(0.6)
                .itemSpacing(20)
                .alignment(.start(20))
                .pagingPriority(.high)
                .frame(width: width, height: height)
        }
    }
    
    func gridImageView(width: CGFloat, height: CGFloat) -> some View {
        List {
            content
                .listRowSeparator(.hidden)
            switch sort {
            case .collectorNumber:
                gridListView(cards: viewModel.cards)
            case .name,
                 .rarity,
                 .setName,
                 .setReleaseDate,
                 .type:
                ForEach(viewModel.sections, id: \.name) { section in
                    Section(header: Text(section.name)) {
                        ForEach(section.objects as? [MGCard] ?? []) { card in
                            CardImageRowView(card: card, style: .twoLines)
                       }
                    }
                }
            }
        }
            .listStyle(.plain)
            .sheet(item: $selectedCard) { selectedCard in
                NavigationView {
                    CardView(newID: selectedCard.newIDCopy)
                }
            }
        
//        ScrollView() {
//            content
//                .padding()
//            LazyVGrid(columns: [GridItem](repeating: GridItem(), count: 4), spacing: 10, pinnedViews: [.sectionHeaders]) {
//                switch sort {
//                case .collectorNumber:
//                    ForEach(viewModel.cards) { card in
//                        CardImageRowView(card: card, style: .twoLines, viewModel: viewModel)
//                    }
//                case .name,
//                     .rarity,
//                     .setName,
//                     .setReleaseDate,
//                     .type:
//                    ForEach(viewModel.sections, id: \.name) { section in
//                        Section(header: stickyHeaderView(section.name)) {
//                            ForEach(section.objects as? [MGCard] ?? []) { card in
//                                CardImageRowView(card: card, style: .twoLines, viewModel: viewModel)
//                           }
//                       }
//                   }
//               }
//           }
//            .padding()
//        }
    }
    
    func gridListView(cards: [MGCard]) -> some View {
        ScrollView() {
            LazyVGrid(columns: [GridItem](repeating: GridItem(), count: 3), spacing: 10, pinnedViews: [.sectionHeaders]) {
                ForEach(cards) { card in
                    let tap = TapGesture()
                        .onEnded { _ in
                            self.selectedCard = card
                        }
                    CardListRowView(card: card)
                        .gesture(tap)

                }
           }
               .padding()
        }
            .listRowSeparator(.hidden)
    }
    
    func gridSummaryView(cards: [MGCard], width: CGFloat, height: CGFloat) -> some View {
        Pager(page: .first(),
              data: cards,
              id: \.newIDCopy) { card in
            let tap = TapGesture()
                .onEnded { _ in
                    self.selectedCard = card
                }
            CardSummaryRowView(card: card)
                .gesture(tap)
        }
            .alignment(.start(1))
            .itemSpacing(10)
            .itemAspectRatio(2.0)
            .pagingPriority(.high)
            .frame(width: width, height: height)
            .listRowSeparator(.hidden)
    }
    
    
}

// MARK: - Action Sheets

extension CardsView {
    var sortActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sort by"),
            buttons: [
                .default(Text("\(sort == .collectorNumber ? "\u{2713}" : "") Collector Number")) {
                    sort = .collectorNumber
                    viewModel.sort = .collectorNumber
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort, object: nil)
                },
                .default(Text("\(sort == .name ? "\u{2713}" : "") Name")) {
                    sort = .name
                    viewModel.sort = .name
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort, object: nil)
                },
                .default(Text("\(sort == .rarity ? "\u{2713}" : "") Rarity")) {
                    sort = .rarity
                    viewModel.sort = .rarity
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort, object: nil)
                },
                .default(Text("\(sort == .setName ? "\u{2713}" : "") Set Name")) {
                    sort = .setName
                    viewModel.sort = .setName
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort, object: nil)
                },
                .default(Text("\(sort == .setReleaseDate ? "\u{2713}" : "") Set Release Date")) {
                    sort = .setReleaseDate
                    viewModel.sort = .setReleaseDate
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort, object: nil)
                },
                .default(Text("\(sort == .type ? "\u{2713}" : "") Type")) {
                    sort = .type
                    viewModel.sort = .type
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort, object: nil)
                },
                .cancel(Text("Cancel"))
            ]
        )
    }
    
    var displayActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Display by"),
            buttons: [
                .default(Text("\(display == .imageCarousel ? "\u{2713}" : "") Carousel")) {
                    display = .imageCarousel
                    viewModel.display = .imageCarousel
                    NotificationCenter.default.post(name: NSNotification.CardsViewDisplay, object: nil)
                },
                .default(Text("\(display == .imageGrid ? "\u{2713}" : "") Grid")) {
                    display = .imageGrid
                    viewModel.display = .imageGrid
                    NotificationCenter.default.post(name: NSNotification.CardsViewDisplay, object: nil)
                },
                .default(Text("\(display == .list ? "\u{2713}" : "") List")) {
                    display = .list
                    viewModel.display = .list
                    NotificationCenter.default.post(name: NSNotification.CardsViewDisplay, object: nil)
                },
                .default(Text("\(display == .summary ? "\u{2713}" : "") Summary")) {
                    display = .summary
                    viewModel.display = .summary
                    NotificationCenter.default.post(name: NSNotification.CardsViewDisplay, object: nil)
                },
                .cancel(Text("Cancel"))
            ]
        )
    }
}

// MARK: - NSNotifications

extension NSNotification {
    static let CardsViewSort = Notification.Name.init("CardsViewSort")
    static let CardsViewDisplay = Notification.Name.init("CardsViewDisplay")
}
