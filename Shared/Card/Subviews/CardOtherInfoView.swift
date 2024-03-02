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
    
    @State private var isArtistsExpanded = true
    private let cmcFormatter = NumberFormatter()

    init(card: MGCard) {
        self.card = card
        
        cmcFormatter.minimumFractionDigits = 0
        cmcFormatter.maximumFractionDigits = 2
        cmcFormatter.numberStyle = .decimal
    }
    
    var body: some View {
        Group {
            LabeledContent {
                Text("#\(card.collectorNumber ?? String.emdash)")
            } label: {
                Text("Collector Number")
            }

            if let artists = card.sortedArtists {
                if artists.count > 1 {
                    DisclosureGroup("Artists:",
                                    isExpanded: $isArtistsExpanded) {
                        ForEach(artists) { artist in
                            Text(artist.name ?? " ")
                        }
                    }
                } else {
                    LabeledContent {
                        Text(artists.first?.name ?? "")
                    } label: {
                        Text("Artist")
                    }
                }
            }
            
            LabeledContent {
                Text(cmcFormatter.string(from: card.cmc as NSNumber) ?? " ")
            } label: {
                Text("Converted Mana Cost")
            }

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
