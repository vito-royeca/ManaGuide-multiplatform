//
//  BusyView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/8/22.
//

import SwiftUI
import ManaKit

struct BusyView: View {
    @State private var imageName: String
    
    init() {
        imageName = "busy01"
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 20) {
                Spacer()
                Text("Loading...")
                    .font(Font.custom(ManaKit.Fonts.magic2015.name, size: 30))
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
                HStack {
                    Spacer()
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: proxy.size.width * 0.8, alignment: .center)
                        .cornerRadius(16)
                        .clipped()
                        .onAppear {
                            let random = Int.random(in: 1..<21)
                            imageName = "busy\(random < 10 ? "0" : "")\(random)"
                        }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct BusyView_Previews: PreviewProvider {
    static var previews: some View {
        BusyView()
    }
}
