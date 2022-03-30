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

struct CardsView: View {
    @StateObject var viewModel: CardsViewModel
    @State private var showingSort = false
    @State private var showingDisplay = false
    @AppStorage("cardsSort") private var sort = CardsViewSort.name
    @AppStorage("cardsDisplay") private var display = CardsViewDisplay.list

    // MARK: - Initializers
    
    init(viewModel: CardsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        CardsDataView(sort: sort, display: display, viewModel: viewModel)
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

                    Button(action: {
                        showingDisplay.toggle()
                    }) {
                        Image(systemName: "list.bullet.below.rectangle")
                    }
                        .actionSheet(isPresented: $showingDisplay) {
                            displayActionSheet
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
                viewModel.sort = sort
                viewModel.display = display
                viewModel.fetchData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewSort)) { (output) in
                viewModel.fetchData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewDisplay)) { (output) in
                viewModel.fetchData()
            }

    }
}

// MARK: - Previews

struct CardsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardsView(viewModel: SetViewModel(setCode: "leb", languageCode: "en"))
        }
    }
}

// MARK: - CardsDataView

struct CardsDataView: View {
    @StateObject var page1: Page = .first()
    @State private var isShowingDetailView = false
    
    private var sort: CardsViewSort
    private var display: CardsViewDisplay
    private var viewModel: CardsViewModel
    
    private let carouselConfig = [
        GridItem()
    ]
    private let gridConfig = [
        GridItem(),
        GridItem()
    ]
    
    init(sort: CardsViewSort, display: CardsViewDisplay, viewModel: CardsViewModel) {
        self.sort = sort
        self.display = display
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometryReader in
            if display == .imageCarousel {
                ScrollView() {
                    VStack {
                        let width = min(geometryReader.size.height, geometryReader.size.width)
                        let height = geometryReader.size.height - 50

                        Pager(page: page1,
                              data: viewModel.cards,
                              id: \.newIDCopy) { card in
                            NavigationLink(destination: CardView(newID: card.newIDCopy, cardsViewModel: viewModel)) {
                            CardImageRowView(card: card, priceStyle: .oneLine)
                            }
                        }
                            .interactive(scale: 0.6)
                            .interactive(opacity: 0.5)
                            .itemSpacing(10)
                            .itemAspectRatio(0.8, alignment: .center)
                            .pagingPriority(.high)
                            .frame(width: width, height: height)
                    }
                }
                
            } else if display == .imageGrid {
                ScrollView() {
                    LazyVGrid(columns: gridConfig, pinnedViews: [.sectionHeaders]) {
                       switch sort {
                       case .collectorNumber:
                           ForEach(viewModel.cards) { card in
                               NavigationLink(destination: CardView(newID: card.newIDCopy, cardsViewModel: viewModel)) {
                                   CardImageRowView(card: card, priceStyle: .twoLines)
                               }
                           }
                       case .name,
                            .rarity,
                            .setName,
                            .setReleaseDate,
                            .type:
                           ForEach(viewModel.sections, id: \.name) { section in
                               Section(header: stickyHeaderView(section.name)) {
                                   ForEach(section.objects as? [MGCard] ?? []) { card in
                                       NavigationLink(destination: CardView(newID: card.newIDCopy, cardsViewModel: viewModel)) {
                                           CardImageRowView(card: card, priceStyle: .twoLines)
                                       }
                                   }
                               }
                           }
                       }
                   }
                    .padding()
                }

            } else {
                List {
                    switch sort {
                    case .collectorNumber:
                        ForEach(viewModel.cards) { card in
                            switch display {
                            case .imageCarousel,
                                 .imageGrid:
                                EmptyView()
                            case .list:
                                CardListRowView(card: card)
                                    .background(NavigationLink("", destination: CardView(newID: card.newIDCopy, cardsViewModel: viewModel)).opacity(0))
                            case .summary:
                                CardSummaryRowView(card: card)
                                    .background(NavigationLink("", destination: CardView(newID: card.newIDCopy, cardsViewModel: viewModel)).opacity(0))
                                    .listRowSeparator(.hidden)
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
                                    switch display {
                                    case .imageCarousel,
                                         .imageGrid:
                                        EmptyView()
                                    case .list:
                                        CardListRowView(card: card)
                                            .background(NavigationLink("", destination: CardView(newID: card.newIDCopy, cardsViewModel: viewModel)).opacity(0))
                                    case .summary:
                                        CardSummaryRowView(card: card)
                                            .background(NavigationLink("", destination: CardView(newID: card.newID, cardsViewModel: viewModel)).opacity(0))
                                            .listRowSeparator(.hidden)
                                    }
                                }
                            }
                        }
                    }
                }
                    .listStyle(.plain)
            }
        }
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