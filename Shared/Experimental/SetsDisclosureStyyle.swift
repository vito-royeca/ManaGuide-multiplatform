//
//  SetsDisclosureStyyle.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 1/27/24.
//

import SwiftUI

struct SetsDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Button(action: {
//                withAnimation {
                    configuration.isExpanded.toggle()
//                }
            }) {
                HStack(alignment: .firstTextBaseline) {
                    configuration.label
                    Spacer()
                    Image(systemName: configuration.isExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                        .foregroundColor(.accentColor)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if configuration.isExpanded {
                configuration
                    .content
                    .disclosureGroupStyle(self)
            }
        }
    }
}
