//
//  CardComponentPartsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 2/20/24.
//

import SwiftUI
import ManaKit

struct CardComponentPartsView: View {
    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        contentView
    }
    
    var contentView: some View {
        let componentParts = card.sortedComponentParts ?? []

        return List {
            ForEach(componentParts) { componentPart in
                if let part = componentPart.part,
                   let component = componentPart.component {

                    let newIDCopy = part.newIDCopy
                    let name = component.name
                    VStack(alignment: .leading) {
                        Text(name)
                            .font(.headline)
                        CardListRowView(card: part)
                            .background(NavigationLink("",
                                                       destination: CardView(newID: newIDCopy,
                                                                             relatedCards: [],
                                                                             withCloseButton: false)).opacity(0))
                    }
                } else {
                    EmptyView()
                }
            }
        }
    }
}
