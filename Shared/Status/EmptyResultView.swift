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
                messageView
                HStack {
                    Spacer()
                    imageView
                        .frame(width: proxy.size.width * 0.8,
                               alignment: .center)
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    private var messageView: some View {
        Text("No results found")
            .font(Font.custom(ManaKit.Fonts.magic2015.name,
                              size: 30))
    }
    
    private var imageView: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            
            .cornerRadius(16)
            .clipped()
            .onAppear {
                let random = Int.random(in: 1..<5)
                imageName = "empty\(random < 5 ? "0" : "")\(random)"
            }
    }
}

#Preview {
    EmptyResultView()
}
