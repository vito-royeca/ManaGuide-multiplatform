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
        GeometryReader { proxy in
            VStack(spacing: 20) {
                Spacer()
                Text("An error has occured.")
                    .font(Font.custom(ManaKit.Fonts.magic2015.name,
                                      size: 30))
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
                            let random = Int.random(in: 1..<14)
                            imageName = "failure\(random < 10 ? "0" : "")\(random)"
                        }
                    Spacer()
                }
                Button(action: {
                    retryAction()
                }) {
                    Text("Try again")
                        .font(Font.custom(ManaKit.Fonts.magic2015.name,
                                          size: 20))
                        .padding(10)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor,
                                        lineWidth: 1)
                        )
                }
                    .foregroundColor(.accentColor)
                Spacer()
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
