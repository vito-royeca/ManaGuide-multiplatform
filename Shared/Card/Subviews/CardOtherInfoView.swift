//
//  CardOtherInfoView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import SwiftUI
import ManaKit

struct CardOtherInfoView: View {
    var card: MGCard
    
    init(card: MGCard) {
        self.card = card
    }
    
    var body: some View {
        Group {
            LabeledContent {
                Text(card.set?.name ?? String.emdash)
            } label: {
                Text("Set")
            }
            
            LabeledContent {
                Text(card.displayKeyrune)
                    .scaledToFit()
                    .font(Font.custom("Keyrune", size: 20))
                    .foregroundColor(Color(card.keyruneColor))
            } label: {
                Text("Set Symbol")
            }
            
            LabeledContent {
                Text(card.rarity?.name ?? String.emdash)
            } label: {
                Text("Rarity")
            }
            
            LabeledContent {
                Text("#\(card.collectorNumber ?? String.emdash)")
            } label: {
                Text("Collector Number")
            }
            
//            LabeledContent {
//                Text(card.artist?.name ?? String.emdash)
//            } label: {
//                Text("Artist")
//            }
            
            if let frame = card.frame {
                LabeledContent {
                    Text(frame.name ?? String.emdash)
                } label: {
                    Text("Frame")
                }
            }

            if let language = card.language {
                LabeledContent {
                    Text(language.name ?? String.emdash)
                } label: {
                    Text("Language")
                }
            }
            
            if let layout = card.layout {
                LabeledContent {
                    Text(layout.name ?? String.emdash)
                } label: {
                    Text("Layout")
                }
            }

            if let releaseDate = card.displayReleaseDate {
                LabeledContent {
                    Text(releaseDate)
                } label: {
                    Text("Release Date")
                }
            }
            
            if let watermark = card.watermark {
                LabeledContent {
                    Text(watermark.name ?? String.emdash)
                } label: {
                    Text("Watermark")
                }
            }
        }
    }
}

#Preview {
    let model = CardViewModel(newID: "isd_en_51",
                              relatedCards: [])
    Task {
        try await model.fetchRemoteData()
    }
    
    if let card = model.cardObject {
        return CardOtherInfoView(card: card)
    } else {
        return Text("Loading...")
    }
}
