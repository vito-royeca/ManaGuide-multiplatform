//
//  CardsStoreView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 5/5/22.
//

import SwiftUI
import ASCollectionView
import ManaKit

struct CardsStoreView: View {
    
    // MARK: - Variables
    var set: MGSet?
    var setViewModel: SetViewModel?
    @StateObject var cardsViewModel: CardsViewModel
    @State private var showingSort = false
    @State private var showingDisplay = false
    @AppStorage("cardsSort") private var sort = CardsViewSort.name
    @AppStorage("cardsDisplay") private var display = CardsViewDisplay.list

    // MARK: - Initializers
    
    init(set: MGSet?, setViewModel: SetViewModel?, cardsViewModel: CardsViewModel) {
        self.set = set
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
                    cardsViewModel.fetchData()
                }
            } else {
                bodyData
            }
        }
            .onAppear {
                cardsViewModel.sort = sort
                cardsViewModel.display = display
                cardsViewModel.fetchData()
            }
    }
    
    var bodyData: some View {
        CardsStoreDataView(sort: sort, display: display, set: set, setViewModel: setViewModel, cardsViewModel: cardsViewModel)
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
                cardsViewModel.fetchLocalData()
            }
    }

    var sortActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Sort by"),
            buttons: [
                .default(Text("\(sort == .name ? "\u{2713}" : "") Name")) {
                    sort = .name
                    cardsViewModel.sort = .name
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort, object: nil)
                },
                .default(Text("\(sort == .rarity ? "\u{2713}" : "") Rarity")) {
                    sort = .rarity
                    cardsViewModel.sort = .rarity
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort, object: nil)
                },
                .default(Text("\(sort == .type ? "\u{2713}" : "") Type")) {
                    sort = .type
                    cardsViewModel.sort = .type
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
        CardsStoreView(set: nil, setViewModel: nil, cardsViewModel: SetViewModel(setCode: "snc", languageCode: "en"))
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

// MARK: - CardsStoreDataView

struct CardsStoreDataView : View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @State private var selectedCard: MGCard? = nil
    private var sort: CardsViewSort
    private var display: CardsViewDisplay
    private var set: MGSet?
    private var setViewModel: SetViewModel?
    private var cardsViewModel: CardsViewModel
    
    init(sort: CardsViewSort, display: CardsViewDisplay, set: MGSet?, setViewModel: SetViewModel?, cardsViewModel: CardsViewModel) {
        self.sort = sort
        self.display = display
        self.set = set
        self.setViewModel = setViewModel
        self.cardsViewModel = cardsViewModel
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
        var array = [ASCollectionViewSection<Int>]()

        if let set = set,
            let viewModel = setViewModel {
            array.append(ASCollectionViewSection(id: -1) {
                CardsStoreHeaderView(set: set, viewModel: viewModel)
            }
                .selfSizingConfig { _ in
                    ASSelfSizingConfig(canExceedCollectionWidth: false)
                })
        }

        array.append(contentsOf: cardsViewModel.sections.map { (section) -> ASCollectionViewSection<Int> in
            let sectionID = cardsViewModel.sections.firstIndex{$0 === section} ?? 0
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
                        header(sectionID: sectionID,  title: section.name, cards: data)
                    }
        })
        
        return array
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
            if let set = set {
                if let _ = set.logoURL {
                    height += 100
                }
                if let sortedLanguages = set.sortedLanguages {
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
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)))

            let itemsGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(height)),
                subitem: item, count: 1)

            let nestedGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9 / columnsToFit),
                    heightDimension: .absolute(height)),
                subitems: [itemsGroup])
            nestedGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8)

            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            section.orthogonalScrollingBehavior = .groupPaging
            section.visibleItemsInvalidationHandler = { _, _, _ in } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells
            return section
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

class AlignedFlowLayout: UICollectionViewFlowLayout
{
    override init()
    {
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
    {
        true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        let attributes = super.layoutAttributesForElements(in: rect)

        attributes?.forEach
        { layoutAttribute in
            switch layoutAttribute.representedElementCategory
            {
            case .cell:
                layoutAttributesForItem(at: layoutAttribute.indexPath).map { layoutAttribute.frame = $0.frame }
            default: break
            }
        }

        return attributes
    }

    private var leftEdge: CGFloat
    {
        guard let insets = collectionView?.adjustedContentInset
        else
        {
            return sectionInset.left
        }
        return insets.left + sectionInset.left
    }

    private var contentWidth: CGFloat?
    {
        guard let collectionViewWidth = collectionView?.frame.size.width,
            let insets = collectionView?.adjustedContentInset
        else
        {
            return nil
        }
        return collectionViewWidth - insets.left - insets.right - sectionInset.left - sectionInset.right
    }

    override var collectionViewContentSize: CGSize
    {
        CGSize(width: contentWidth ?? super.collectionViewContentSize.width, height: super.collectionViewContentSize.height)
    }

    fileprivate func isFrame(for firstItemAttributes: UICollectionViewLayoutAttributes, inSameLineAsFrameFor secondItemAttributes: UICollectionViewLayoutAttributes) -> Bool
    {
        guard let lineWidth = contentWidth
        else
        {
            return false
        }
        let firstItemFrame = firstItemAttributes.frame
        let lineFrame = CGRect(
            x: leftEdge,
            y: firstItemFrame.origin.y,
            width: lineWidth,
            height: firstItemFrame.size.height)
        return lineFrame.intersects(secondItemAttributes.frame)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)
        else
        {
            return nil
        }
        guard
            indexPath.item > 0,
            let previousAttributes = layoutAttributesForItem(at: IndexPath(item: indexPath.item - 1, section: indexPath.section))
        else
        {
            attributes.frame.origin.x = leftEdge // first item of the section should always be left aligned
            return attributes
        }

        if isFrame(for: attributes, inSameLineAsFrameFor: previousAttributes)
        {
            attributes.frame.origin.x = previousAttributes.frame.maxX + minimumInteritemSpacing
        }
        else
        {
            attributes.frame.origin.x = leftEdge
        }

        return attributes
    }
}
