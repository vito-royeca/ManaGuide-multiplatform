//
//  CardsStoreView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 5/5/22.
//

import SwiftUI
import CoreData
import ASCollectionView
import ManaKit

struct CardsStoreView: View {
    
    // MARK: - Variables
    @AppStorage("cardsSort") private var sort = CardsViewSort.name
    @StateObject var cardsViewModel: CardsViewModel
    @State private var showingSort = false
    @State private var showingDisplay = false
    var setViewModel: SetViewModel?

    // MARK: - Initializers
    
    init(setViewModel: SetViewModel?, cardsViewModel: CardsViewModel) {
        self.setViewModel = setViewModel
        _cardsViewModel = StateObject(wrappedValue: cardsViewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if cardsViewModel.isBusy {
                BusyView()
            } else if cardsViewModel.isFailed {
                ErrorView {
                    Task {
                        try await cardsViewModel.fetchRemoteData()
                    }
                } cancelAction: {
                    cardsViewModel.isFailed = false
                }
            } else {
                contentView
            }
        }
            .onAppear {
                Task {
                    cardsViewModel.sort = sort
                    try await cardsViewModel.fetchRemoteData()
                }
            }
    }
    
    private var contentView: some View {
        CardsStoreDataView(sort: sort,
                           setViewModel: setViewModel,
                           cardsViewModel: cardsViewModel)
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
                        .foregroundColor(.accentColor)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardsViewSort)) { (output) in
                cardsViewModel.fetchLocalData()
            }
    }

    private var sortActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sort by"),
            buttons: [
                .default(Text("\(sort == .name ? "\u{2713}" : "") Name")) {
                    sort = .name
                    cardsViewModel.sort = .name
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort,
                                                    object: nil)
                },
                .default(Text("\(sort == .rarity ? "\u{2713}" : "") Rarity")) {
                    sort = .rarity
                    cardsViewModel.sort = .rarity
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort,
                                                    object: nil)
                },
                .default(Text("\(sort == .type ? "\u{2713}" : "") Type")) {
                    sort = .type
                    cardsViewModel.sort = .type
                    NotificationCenter.default.post(name: NSNotification.CardsViewSort,
                                                    object: nil)
                },
                .cancel(Text("Cancel"))
            ]
        )
    }
}

// MARK: - Previews

#Preview {
    let cardsViewModel = SetViewModel(setCode: "snc",
                                      languageCode: "en")
    Task {
        try await cardsViewModel.fetchRemoteData()
    }

    return CardsStoreView(setViewModel: nil,
                   cardsViewModel: cardsViewModel)
//            .previewInterfaceOrientation(.landscapeRight)
}

// MARK: - CardsStoreDataView

struct CardsStoreDataView : View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var selectedCard: NSManagedObjectID? = nil
    private var sort: CardsViewSort
    private var setViewModel: SetViewModel?
    private var cardsViewModel: CardsViewModel
    
    init(sort: CardsViewSort,
         setViewModel: SetViewModel?,
         cardsViewModel: CardsViewModel) {
        self.sort = sort
        self.setViewModel = setViewModel
        self.cardsViewModel = cardsViewModel
    }
    
    var body: some View {
        ASCollectionView(sections: self.sections)
            .layout(self.layout)
            .contentInsets(.init(top: 10,
                                 left: 0,
                                 bottom: 10,
                                 right: 0))
            .shouldAttemptToMaintainScrollPositionOnOrientationChange(maintainPosition: false)
            .edgesIgnoringSafeArea(.all)
            .sheet(item: $selectedCard) { selectedCard in
                if let card = cardsViewModel.find(MGCard.self,
                                                  id: selectedCard) {
                    NavigationView {
                        CardView(newID: card.newIDCopy,
                                 relatedCards: [], withCloseButton: true)
                    }
                } else {
                    EmptyView()
                }
            }
    }
    
    var sections: [ASCollectionViewSection<Int>] {
        var array = [ASCollectionViewSection<Int>]()

        if let viewModel = setViewModel {
            array.append(ASCollectionViewSection(id: -1) {
                CardsStoreHeaderView(viewModel: viewModel)
            }
                .selfSizingConfig { _ in
                    ASSelfSizingConfig(canExceedCollectionWidth: true)
                })
        }

        array.append(contentsOf: cardsViewModel.sections.map { (section) -> ASCollectionViewSection<Int> in
            let sectionID = cardsViewModel.sections.firstIndex{$0 === section} ?? 0
            let cards = (section.objects as? [MGCard] ?? [])
            var clippedCards = [MGCard]()
            
            if cards.count > 20 {
                clippedCards = cards.dropLast(cards.count - 20)
            } else {
                clippedCards = cards
            }
            
            return ASCollectionViewSection(
                id: sectionID,
                data: clippedCards) { card, _ in
                    let tap = TapGesture()
                        .onEnded { _ in
                            self.selectedCard = card.objectID
                        }

                    if clippedCards.count < 3 {
                        CardsStoreLargeView(card: card)
                            .gesture(tap)
                    } else {
                        if sectionID % 3 == 0 {
                            CardsStoreFeatureView(card: card)
                                .gesture(tap)
                        } else if sectionID % 3 == 1  {
                            CardsStoreLargeView(card: card)
                                .gesture(tap)
                        } else {
                            CardsStoreCompactView(card: card)
                                .gesture(tap)
                        }
                    }
                }
                    .selfSizingConfig { _ in
                        ASSelfSizingConfig(canExceedCollectionWidth: false)
                    }
                    .sectionHeader {
                        header(sectionID: sectionID,
                               title: section.name,
                               cards: cards.map({ $0.objectID }))
                    }
        })
        
        return array
    }
    
    func header(sectionID: Int,
                title: String,
                cards: [NSManagedObjectID]) -> some View {
        HStack {
            Text(title)
                .font(.title)
            Spacer()
            if cards.count >= 10 {
                NavigationLink("See all",
                               destination: CardsStoreSeeAllView(title: title,
                                                                 cards: cards))
            }
        }
    }
}

// MARK: - Layouts

extension CardsStoreDataView {
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical,
                           interSectionSpacing: 20) { sectionID in
            if sectionID == -1 {
                return layoutContent
            } else {
                let section = cardsViewModel.sections[sectionID]
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
    }
    
    var layoutContent: ASCollectionLayoutSection {
        ASCollectionLayoutSection { environment in
            var height = CGFloat(120)
            if let setObject = setViewModel?.setObject {
                
                if let _ = setObject.smallLogoURL {
                    height += 100
                }
                if let sortedLanguages = setObject.sortedLanguages {
                    if sortedLanguages.count > 6 {
                        #if os(iOS)
                        if horizontalSizeClass == .compact {
                            height += 20
                        }
                        #endif
                    }
                }
            }
            
            let columnsToFit = CGFloat(1)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                   heightDimension: .absolute(height)),
                                                                subitem: item,
                                                                count: 1)

            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.95 / columnsToFit),
                                                                                                    heightDimension: .absolute(height)),
                                                                 subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10,
                                                                leading: 10,
                                                                bottom: 10,
                                                                trailing: 10)

            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: 20,
                                                            bottom: 0,
                                                            trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells
            return section
        }
    }
    
    var layoutFeature: ASCollectionLayoutSection {
        ASCollectionLayoutSection { environment in
            let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8 / columnsToFit),
                                                                                                 heightDimension: .absolute(280)),
                                                              subitem: item, count: 1)
            
            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9 / columnsToFit),
                                                                                                    heightDimension: .absolute(280)),
                                                                 subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10,
                                                                leading: 8,
                                                                bottom: 10,
                                                                trailing: 8)

            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                        heightDimension: .absolute(34)),
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            header.contentInsets.leading = nestedGroup.contentInsets.leading
            header.contentInsets.trailing = nestedGroup.contentInsets.trailing
            
            let section = NSCollectionLayoutSection(group: itemsGroup)
            section.interGroupSpacing = 20
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: 20,
                                                            bottom: 0,
                                                            trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

            return section
        }
    }
    
    var layoutLarge: ASCollectionLayoutSection {
        ASCollectionLayoutSection { environment in
            let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                 heightDimension: .fractionalHeight(1.0)),
                                                              subitem: item, count: 2)
            itemsGroup.interItemSpacing = .fixed(10)

            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9 / columnsToFit),
                                                                                                    heightDimension: .absolute(180)),
                                                                 subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10,
                                                                leading: 8,
                                                                bottom: 10,
                                                                trailing: 8)

            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                        heightDimension: .absolute(34)),
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            header.contentInsets.leading = nestedGroup.contentInsets.leading
            header.contentInsets.trailing = nestedGroup.contentInsets.trailing

            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: 20,
                                                            bottom: 0,
                                                            trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

            return section
        }
    }
    
    func layoutLargeFew(itemCount: Int) -> ASCollectionLayoutSection {
        return ASCollectionLayoutSection { environment in
            let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                 heightDimension: .fractionalHeight(1.0)),
                                                              subitem: item,
                                                              count: itemCount)
            itemsGroup.interItemSpacing = .fixed(10)

            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9 / columnsToFit),
                                                                                                    heightDimension: .absolute(CGFloat(itemCount * 90))),
                                                                 subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10,
                                                                leading: 8,
                                                                bottom: 10,
                                                                trailing: 8)

            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                        heightDimension: .absolute(34)),
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            header.contentInsets.leading = nestedGroup.contentInsets.leading
            header.contentInsets.trailing = nestedGroup.contentInsets.trailing

            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: 20,
                                                            bottom: 0,
                                                            trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

            return section
        }
    }
    
    var layoutCompact: ASCollectionLayoutSection {
        ASCollectionLayoutSection { environment in
            let columnsToFit = floor(environment.container.effectiveContentSize.width / 320)
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                 heightDimension: .fractionalHeight(1.0)),
                                                              subitem: item, count: 3)
            itemsGroup.interItemSpacing = .fixed(10)

            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9 / columnsToFit),
                                                                                                    heightDimension: .absolute(240)),
                                                                 subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10,
                                                                leading: 8,
                                                                bottom: 10,
                                                                trailing: 8)

            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                        heightDimension: .absolute(34)),
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            header.contentInsets.leading = nestedGroup.contentInsets.leading
            header.contentInsets.trailing = nestedGroup.contentInsets.trailing

            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: 20,
                                                            bottom: 0,
                                                            trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

            return section
        }
    }
}
