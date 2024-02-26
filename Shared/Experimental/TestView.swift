//
//  TestView.swift
//  ManaGuide (iOS)
//
//  Created by Miguel Ponce de Monio III on 1/29/24.
//

import SwiftUI
import ManaKit

struct TestView: View {
    var body: some View {
        ProgressView("Loading...")
            .progressViewStyle(.circular)
            .font(Font.custom(ManaKit.Fonts.magic2015.name,
                              size: 20))
    }
}

#Preview {
    TestView()
}
