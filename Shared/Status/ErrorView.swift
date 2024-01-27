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
    var cancelAction: () -> Void
    @State private var imageName: String
    
    init(retryAction: @escaping () -> Void,
         cancelAction: @escaping () -> Void) {
        self.retryAction = retryAction
        self.cancelAction = cancelAction
        imageName = "failure01"
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
                HStack {
                    retryButton
                    cancelButton
                }
                Spacer()
            }
        }
    }
    
    private var messageView: some View {
        Text("An error has occured.")
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
                let random = Int.random(in: 1..<14)
                imageName = "failure\(random < 10 ? "0" : "")\(random)"
            }
    }

    private var retryButton: some View {
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
    }
    
    private var cancelButton: some View {
        Button(action: {
            cancelAction()
        }) {
            Text("Cancel")
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
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView {
            print("Retry")
        } cancelAction: {
            print("Cancel")
        }
    }
}
