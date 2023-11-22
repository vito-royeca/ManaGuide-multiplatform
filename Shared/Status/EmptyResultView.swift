//
//  EmptyResultView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/20/23.
//

import SwiftUI
import ManaKit

struct EmptyResultView: View {
    @State private var imageName: String
    
    init() {
        imageName = "empty01"
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 20) {
                Spacer()
                HStack {
                    Spacer()
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: proxy.size.width * 0.8,
                               alignment: .center)
                        .cornerRadius(16)
                        .clipped()
                        .onAppear {
                            let random = Int.random(in: 1..<6)
                            imageName = "empty\(random < 5 ? "0" : "")\(random)"
                        }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    EmptyResultView()
}
