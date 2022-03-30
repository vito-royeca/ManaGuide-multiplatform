//
//  CardSwipeView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/28/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI
import SwiftUIPager

//struct CardSwipeView<Content: View>: View {
//    @ObservedObject var viewModel: CardsViewModel
//    @State private var scrollOffset: CGFloat
//    @State private var dragOffset: CGFloat
//
//    let itemSpacing: CGFloat = 10
//    var content: () -> Content
//    var itemWidth: CGFloat
//    var screenWidth: CGFloat
//    var itemCount = 0
//
//
//    init(viewModel: CardsViewModel, itemWidth: CGFloat, screenWidth: CGFloat, @ViewBuilder content: @escaping () -> Content) {
//        self.viewModel = viewModel
//        self.itemWidth = itemWidth
//        self.screenWidth = screenWidth
//        self.content = content
//        itemCount = viewModel.cards.count
//
//        // Calculate Total Content Width
//        let contentWidth: CGFloat = CGFloat(itemCount) * itemWidth + CGFloat(itemCount - 1) * itemSpacing
//
//        // Set Initial Offset to first Item
//        let initialOffset = (contentWidth/2.0) - (screenWidth/2.0) + ((screenWidth - itemWidth) / 2.0)
//
//        self._scrollOffset = State(initialValue: initialOffset)
//        self._dragOffset = State(initialValue: 0)
//    }
//
//    var body: some View {
//            ScrollView(.horizontal, showsIndicators: true) {
//                LazyHGrid(rows: [GridItem(.fixed(itemWidth))], alignment: .top, content: content)
//            }
//                .content.frame(width: screenWidth, alignment: .leading)
//                .offset(x: scrollOffset + dragOffset, y: 0)
//                .gesture(DragGesture()
//                    .onChanged({ event in
//                        dragOffset = event.translation.width
//                    })
//                    .onEnded({ event in
////                         Scroll to where user dragged
//                        scrollOffset += event.translation.width
//                        dragOffset = 0
//
//                        // Now calculate which item to snap to
//                        let contentWidth: CGFloat = CGFloat(itemCount) * itemWidth + CGFloat(itemCount - 1) * itemSpacing
//
//                        // Center position of current offset
//                        let center = scrollOffset + (screenWidth / 2.0) + (contentWidth / 2.0)
//
//                        // Calculate which item we are closest to using the defined size
//                        var index = (center - (screenWidth / 2.0)) / (itemWidth + itemSpacing)
//
//                        // Should we stay at current index or are we closer to the next item...
//                        if index.remainder(dividingBy: 1) > 0.5 {
//                            index += 1
//                        } else {
//                            index = CGFloat(Int(index))
//                        }
//
//                        // Protect from scrolling out of bounds
//                        index = min(index, CGFloat(itemCount) - 1)
//                        index = max(index, 0)
//
//                        // Set final offset (snapping to item)
//                        let newOffset = index * itemWidth + (index - 1) * itemSpacing - (contentWidth / 2.0) + (screenWidth / 2.0) - ((screenWidth - itemWidth) / 2.0) + itemSpacing
//
//                        // Animate snapping
//                        withAnimation {
//                            scrollOffset = newOffset
//                        }
//
//                    })
//                )
//    }
//}

// orig
struct CardSwipeView<Content: View>: View {
    @ObservedObject var viewModel: CardsViewModel
    @State private var offset: CGFloat = 0
    @State private var index = 0

    let spacing: CGFloat = 10
    var itemWidth: CGFloat
    var screenWidth: CGFloat
    var content: () -> Content

    init(viewModel: CardsViewModel, itemWidth: CGFloat, screenWidth: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.viewModel = viewModel
        self.itemWidth = itemWidth
        self.screenWidth = screenWidth
        self.content = content
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHGrid(rows: [GridItem(.fixed(itemWidth))], alignment: .top, content: content)
        }
            .content.offset(x: offset)
            .frame(width: screenWidth, alignment: .leading)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        offset = value.translation.width - itemWidth * CGFloat(index)
                    })
                    .onEnded({ value in
                        if -value.predictedEndTranslation.width > itemWidth / 2,
                            index < viewModel.cards.count - 1 {
                            index += 1
                        }
                        if value.predictedEndTranslation.width > itemWidth / 2,
                           index > 0 {
                            index -= 1
                        }

                        withAnimation {
                            offset = -(itemWidth + spacing) * CGFloat(index)
                        }
                    })
            )
            .onAppear{
                withAnimation {
                    offset = -(itemWidth + spacing) * CGFloat(index)
                }
            }
    }
}

struct CardSwipeView_Previews: PreviewProvider {
    static var previews: some View {
        let model = SetViewModel(setCode: "ulg", languageCode: "en")

        GeometryReader { geometryReader in
            let screenWidth = geometryReader.size.width
            let itemWidth = screenWidth - (geometryReader.size.width / 10)

            NavigationView {
                CardSwipeView(viewModel: model, itemWidth: itemWidth, screenWidth: screenWidth) {
                    ForEach(model.cards) { card in
//                        NavigationLink(destination: CardView(newID: card.newIDCopy, cardsViewModel: model)) {
                            CardImageRowView(card: card, priceStyle: .oneLine)
//                        }
                    }
                }
                    .onAppear{
                        model.fetchData()
                    }
            }
        }
    }
}
