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
        VStack {
            Spacer()
            Text("Loading...")
                .font(Font.custom(ManaKit.Fonts.magic2015.name, size: 30))
            ProgressView()
                .progressViewStyle(.circular)
                .padding()
            Image(imageName)
                .aspectRatio(contentMode: .fit)
                .clipped()
            Spacer()
        }
            .onAppear {
                let random = Int.random(in: 1..<21)
                imageName = "busy\(random < 10 ? "0" : "")\(random)"
            }
    }
}

struct BusyView_Previews: PreviewProvider {
    static var previews: some View {
        BusyView()
    }
}
