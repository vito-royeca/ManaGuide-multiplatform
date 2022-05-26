//
//  ErrorView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/8/22.
//

import SwiftUI
import ManaKit

struct ErrorView: View {
    var retryAction: () -> Void
    @State private var imageName: String
    
    init(_ retryAction: @escaping () -> Void) {
        self.retryAction = retryAction
        imageName = "failure01"
    }
    
    var body: some View {
        GeometryReader { reader in
            VStack {
                Spacer()
                Text("An error has occured.")
                    .font(Font.custom(ManaKit.Fonts.magic2015.name, size: 30))
                Spacer()
                Image(imageName)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: reader.size.width)
                    .clipped()
                Spacer()
                Button(action: {
                    retryAction()
                }) {
                    Text("Try again")
                        .font(Font.custom(ManaKit.Fonts.magic2015.name, size: 20))
                        .padding(10)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor, lineWidth: 1)
                        )
                }
                    .foregroundColor(Color.accentColor)
                Spacer()
            }
                .onAppear {
                    let random = Int.random(in: 1..<14)
                    imageName = "failure\(random < 10 ? "0" : "")\(random)"
                }
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView {
            print("Retry")
        }
    }
}
