//
//  CardsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

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
            CardsView(viewModel: SetViewModel(setCode: "ice", languageCode: "en"))
        }
    }
}

// MARK: - CardsDataView

struct CardsDataView: View {
    private var sort: CardsViewSort
    private var display: CardsViewDisplay
    private var viewModel: CardsViewModel
    
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
        if display == .image {
            ScrollView {
                LazyVGrid(columns: gridConfig, pinnedViews: [.sectionHeaders]) {
                   switch sort {
                   case .collectorNumber:
                       ForEach(viewModel.cards) { card in
                           let newID = "\(card.set?.code ?? "")_\(card.language?.code ?? "")_\(card.collectorNumber ?? "")"
                           
                           NavigationLink(destination: CardView(newID: newID)) {
                               WebImage(url: card.imageURL(for: .png))
                                   .resizable()
                                   .placeholder(Image(uiImage: ManaKit.shared.image(name: .cardBack)!))
                                   .indicator(.activity)
                                   .transition(.fade(duration: 0.5))
                                   .aspectRatio(contentMode: .fill)
                                   .cornerRadius(5)
                                   .clipped()
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
                                   let newID = "\(card.set?.code ?? "")_\(card.language?.code ?? "")_\(card.collectorNumber ?? "")"
                                   
                                   NavigationLink(destination: CardView(newID: newID)) {
                                       WebImage(url: card.imageURL(for: .png))
                                           .resizable()
                                           .placeholder(Image(uiImage: ManaKit.shared.image(name: .cardBack)!))
                                           .indicator(.activity)
                                           .transition(.fade(duration: 0.5))
                                           .aspectRatio(contentMode: .fill)
                                           .cornerRadius(5)
                                           .clipped()
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
                        let newID = "\(card.set?.code ?? "")_\(card.language?.code ?? "")_\(card.collectorNumber ?? "")"
                        
                        switch display {
                        case .list:
                            CardListRowView(card: card)
                                .background(NavigationLink("", destination: CardView(newID: newID)).opacity(0))
                        case .image:
                            EmptyView()
                        case .summary:
                            CardSummaryRowView(card: card)
                                .background(NavigationLink("", destination: CardView(newID: newID)).opacity(0))
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
                                let newID = "\(card.set?.code ?? "")_\(card.language?.code ?? "")_\(card.collectorNumber ?? "")"
                                
                                switch display {
                                case .list:
                                    CardListRowView(card: card)
                                        .background(NavigationLink("", destination: CardView(newID: newID)).opacity(0))
                                case .image:
                                    EmptyView()
                                case .summary:
                                    CardSummaryRowView(card: card)
                                        .background(NavigationLink("", destination: CardView(newID: newID)).opacity(0))
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
                .default(Text("\(display == .image ? "\u{2713}" : "") Image")) {
                    display = .image
                    viewModel.display = .image
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
