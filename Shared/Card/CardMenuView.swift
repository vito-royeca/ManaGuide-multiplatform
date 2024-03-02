//
//  CardMenuView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 2/25/24.
//

import SwiftUI

struct CardMenuView: View {
    @AppStorage("CardMenu") private var cardMenu = CardMenu.pricing.description
    
    var body: some View {
        Menu {
            menuView
        } label: {
            Text(cardMenu)
        }
    }
    
    private var menuView: some View {
        Group {
            ForEach(CardMenu.allCases, id:\.self) { menu in
                Button(action: {
                    cardMenu = menu.description
                    NotificationCenter.default.post(name: NSNotification.CardMenu,
                                                    object: cardMenu)
                }) {
                    if cardMenu == menu.description {
                        Label(menu.description,
                              systemImage: "checkmark")
                    } else {
                        Text(menu.description)
                    }
                }
            }
        }
    }
}

// MARK: - CardView

enum CardMenu: CaseIterable {
    case pricing, info, extraInfo, variations, parts, printings, languages
    
    var description: String {
        get {
            switch self {
            case .pricing:
                "Pricing"
            case .info:
                "Info"
            case .extraInfo:
                "Extra Info"
            case .variations:
                "Variations"
            case .parts:
                "Parts"
            case .printings:
                "Printings"
            case .languages:
                "Languages"
            }
        }
    }
    
    var imageName: String {
        get {
            switch self {
            case .pricing:
                "dollarsign"
            case .info:
                "info.circle"
            case .extraInfo:
                "info.circle"
            case .variations:
                "photo.on.rectangle.angled"
            case .parts:
                "puzzlepiece.extension"
            case .printings:
                "rectangle.3.group"
            case .languages:
                "character"
            }
        }
    }
}

#Preview {
    CardMenuView()
}
