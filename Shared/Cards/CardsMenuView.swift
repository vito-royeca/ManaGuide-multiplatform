//
//  CardsMenuView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import SwiftUI

struct CardsMenuView: View {
    @AppStorage("CardsViewSort") private var cardsSort = CardsViewSort.defaultValue
    @AppStorage("CardsViewDisplay") private var cardsDisplay = CardsViewDisplay.defaultValue
    
    var body: some View {
        Menu {
            Menu {
                Button(action: {
                    cardsSort = .name
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort,
                                                    object: cardsSort)
                }) {
                    if cardsSort == .name {
                        Label("Name",
                              systemImage: "checkmark")
                    } else {
                        Text("Name")
                    }
                }
                Button(action: {
                    cardsSort = .collectorNumber
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort,
                                                    object: cardsSort)
                }) {
                    if cardsSort == .collectorNumber {
                        Label("Collector Number",
                              systemImage: "checkmark")
                    } else {
                        Text("Collector Number")
                    }
                }
                Button(action: {
                    cardsSort = .rarity
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort,
                                                    object: cardsSort)
                }) {
                    if cardsSort == .rarity {
                        Label("Rarity",
                              systemImage: "checkmark")
                    } else {
                        Text("Rarity")
                    }
                }
                Button(action: {
                    cardsSort = .type
                    NotificationCenter.default.post(name: NSNotification.CardsStoreViewSort,
                                                    object: cardsSort)
                }) {
                    if cardsSort == .type {
                        Label("Type",
                              systemImage: "checkmark")
                    } else {
                        Text("Type")
                    }
                }
            } label: {
                Text("Sort by")
            }

            Menu {
                Button(action: {
                    cardsDisplay = .image
                }) {
                    Label("Image",
                          systemImage: cardsDisplay == .image ? "photo.circle.fill" : "photo")
                }
                Button(action: {
                    cardsDisplay = .list
                }) {
                    Label("List",
                          systemImage: cardsDisplay == .list ? "list.bullet.circle.fill": "list.bullet")
                }
            } label: {
                Text("View as")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}

#Preview {
    CardsMenuView()
}
