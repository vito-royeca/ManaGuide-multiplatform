//
//  CardTextRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/8/23.
//

import SwiftUI

enum CardTextRowViewStyle {
    case horizontal, vertical
}

struct CardTextRowView: View {
    var title: String
    var subtitle: String
    var style: CardTextRowViewStyle
    
    init(title: String, subtitle: String, style: CardTextRowViewStyle = .horizontal) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .horizontal:
            HStack {
                Text(subtitle)
//                    .font(.headline)
                Spacer()
                Text(title)
//                    .font(.subheadline)
            }
        case .vertical:
            VStack(alignment: .leading) {
                Text(subtitle)
//                    .font(.headline)
                Spacer()
                Text(title)
//                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    CardTextRowView(title: "Title",
                    subtitle: "Subtitle")
}
