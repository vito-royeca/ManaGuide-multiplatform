//
//  CardsStoreView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 5/5/22.
//

import SwiftUI
import ASCollectionView
import ManaKit

struct CardsStoreView<Content> : View where Content : View {
    
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
        CardsStoreDataView(sort: sort, display: display, viewModel: viewModel) {
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
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsStoreViewSort)) { (output) in
                viewModel.fetchLocalData()
            }
    }
}

// MARK: - Action Sheets

extension CardsStoreView {
    var sortActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sort by"),
            buttons: [
                .default(Text("\(sort == .name ? "\u{2713}" : "") Name")) {
                    sort = .name
                    viewModel.sort = .name
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort, object: nil)
                },
                .default(Text("\(sort == .rarity ? "\u{2713}" : "") Rarity")) {
                    sort = .rarity
                    viewModel.sort = .rarity
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort, object: nil)
                },
                .default(Text("\(sort == .type ? "\u{2713}" : "") Type")) {
                    sort = .type
                    viewModel.sort = .type
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort, object: nil)
                },
                .cancel(Text("Cancel"))
            ]
        )
    }
}

// MARK: - NSNotifications

extension NSNotification {
    static let CardsStoreViewSort = Notification.Name.init("CardsStoreViewSort")
}

// MARK: - Previews

struct CardsStoreView_Previews: PreviewProvider {
    static var previews: some View {
        CardsStoreView(viewModel: SetViewModel(setCode: "snc", languageCode: "en")) {
            EmptyView()
        }
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

// MARK: - CardsStoreDataView

struct CardsStoreDataView<Content> : View where Content : View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
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
        ASCollectionView(sections: self.sections)
            .layout(self.layout)
            .contentInsets(.init(top: 10, left: 0, bottom: 10, right: 0))
            .shouldAttemptToMaintainScrollPositionOnOrientationChange(maintainPosition: false)
            .edgesIgnoringSafeArea(.all)
            .sheet(item: $selectedCard) { selectedCard in
                NavigationView {
                    CardView(newID: selectedCard.newIDCopy)
                }
            }
    }
    
    var sections: [ASCollectionViewSection<Int>] {
        viewModel.sections.map { (section) -> ASCollectionViewSection<Int> in
            let sectionID = viewModel.sections.firstIndex{$0 === section} ?? 0
            var data = (section.objects as? [MGCard] ?? [])
            
            if data.count > 20 {
                data = data.dropLast(data.count - 20)
            }
            
            return ASCollectionViewSection(
                id: sectionID,
                data: data) { card, _ in
                    let tap = TapGesture()
                        .onEnded { _ in
                            self.selectedCard = card
                        }

                    if data.count < 3 {
                        CardsStoreViewLarge(card: card)
                            .gesture(tap)
                    } else {
                        if sectionID % 3 == 0 {
                            CardsStoreViewFeature(card: card)
                                .gesture(tap)
                        } else if sectionID % 3 == 1  {
                            CardsStoreViewLarge(card: card)
                                .gesture(tap)
                        } else {
                            CardsStoreViewCompact(card: card)
                                .gesture(tap)
                        }
                    }
                }
                    .selfSizingConfig { _ in
                        ASSelfSizingConfig(canExceedCollectionWidth: false)
                    }
                    .sectionHeader {
                        header(sectionID: sectionID,  title: section.name, cards: data)
                    }
        }
    }
    
    func header(sectionID: Int, title: String, cards: [MGCard]) -> some View {
        HStack {
            Text(title)
                .font(.title)
            Spacer()
            
            if sectionID % 3 == 0 {
                if cards.count > 2 {
                    NavigationLink("See all", destination: CardsStoreSeeAllView(title: title, cards: cards))
                }
            } else if sectionID % 3 == 1  {
                if cards.count > 4 {
                    NavigationLink("See all", destination: CardsStoreSeeAllView(title: title, cards: cards))
                }
            } else {
                if cards.count > 6 {
                    NavigationLink("See all", destination: CardsStoreSeeAllView(title: title, cards: cards))
                }
            }
        }
    }
}

// MARK: - Layout

extension CardsStoreDataView {
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 20) { sectionID in
            let section = viewModel.sections[sectionID]
            let data = section.objects as? [MGCard] ?? []
            
            if data.count < 3 {
                return layoutLargeFew(itemCount: data.count)
            } else {
                switch sectionID % 3 {
                case 0:
                    return layoutFeature
                case 1:
                    return layoutLarge
                default:
                    return layoutCompact
                }
            }
        }
    }
    
    var layoutFeature: ASCollectionLayoutSection {
        ASCollectionLayoutSection { environment in
            let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.8 / columnsToFit),
                    heightDimension: .absolute(280)),
                subitem: item, count: 1)
            
            let nestedGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9 / columnsToFit),
                    heightDimension: .absolute(280)),
                subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)

            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(34)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            header.contentInsets.leading = nestedGroup.contentInsets.leading
            header.contentInsets.trailing = nestedGroup.contentInsets.trailing
            
            let section = NSCollectionLayoutSection(group: itemsGroup)
            section.interGroupSpacing = 20
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

            return section
        }
    }
    
    var layoutLarge: ASCollectionLayoutSection {
        ASCollectionLayoutSection { environment in
            let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)),
                subitem: item, count: 2)
            itemsGroup.interItemSpacing = .fixed(10)

            let nestedGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9 / columnsToFit),
                    heightDimension: .absolute(180)),
                subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)

            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(34)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            header.contentInsets.leading = nestedGroup.contentInsets.leading
            header.contentInsets.trailing = nestedGroup.contentInsets.trailing

            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

            return section
        }
    }
    
    func layoutLargeFew(itemCount: Int) -> ASCollectionLayoutSection {
        return ASCollectionLayoutSection { environment in
            let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)),
                subitem: item, count: itemCount)
            itemsGroup.interItemSpacing = .fixed(10)

            let nestedGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9 / columnsToFit),
                    heightDimension: .absolute(CGFloat(itemCount * 90))),
                subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)

            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(34)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            header.contentInsets.leading = nestedGroup.contentInsets.leading
            header.contentInsets.trailing = nestedGroup.contentInsets.trailing

            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

            return section
        }
    }
    
    var layoutCompact: ASCollectionLayoutSection {
        ASCollectionLayoutSection { environment in
            let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)),
                subitem: item, count: 3)
            itemsGroup.interItemSpacing = .fixed(10)

            let nestedGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9 / columnsToFit),
                    heightDimension: .absolute(240)),
                subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)

            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(34)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            header.contentInsets.leading = nestedGroup.contentInsets.leading
            header.contentInsets.trailing = nestedGroup.contentInsets.trailing

            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

            return section
        }
    }
}

