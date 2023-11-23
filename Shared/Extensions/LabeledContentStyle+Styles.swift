//
//  LabeledContentStyle+Styles.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/23/23.
//

import SwiftUI

struct VerticalLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
            configuration.content.foregroundColor(.systemGray2)
        }
    }
}

extension LabeledContentStyle where Self == VerticalLabeledContentStyle {
    static var vertical: VerticalLabeledContentStyle { .init() }
}
