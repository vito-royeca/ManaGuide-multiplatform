//
//  CardImageRowView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/26/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct CardImageRowView: View {
    @State var degrees : Double = 0
    @State var url : URL?
    private let card: MGCard
    private let style: CardImageRowPriceStyle
    
    init(card: MGCard, style: CardImageRowPriceStyle) {
        self.card = card
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: 2) {
            let webImage = WebImage(url: url)
                .resizable()
                .placeholder(Image(uiImage: ManaKit.shared.image(name: .cardBack)!))
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .aspectRatio(contentMode: .fill)
                .cornerRadius(10)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.clear, lineWidth: 0)
                )
            
            if card.layout?.name == "Flip" ||
                card.layout?.name == "Planar" ||
                card.layout?.name == "Split" {
                webImage
                    .rotationEffect(Angle(degrees: degrees))
            } else if card.layout?.name == "Art Series" ||
                card.layout?.name == "Double Faced Token" ||
                card.layout?.name == "Modal Dfc" ||
                card.layout?.name == "Transform" {
                webImage
                    .rotation3DEffect(.degrees(degrees), axis: (x: 0, y: 0, z: 0))
            } else {
                webImage
            }
            CardImageRowPriceView(card: card, style: style, degrees: $degrees, url: $url)
        }
            .onAppear {
                url = card.imageURL(for: .png)
            }
    }
}

// MARK: - Previews

struct CardImageRowView_Previews: PreviewProvider {
    static var previews: some View {
        Text("card not found")
    }
}

enum CardImageRowPriceStyle {
    case oneLine, twoLines
}

struct CardImageRowPriceView: View {
    private let card: MGCard
    private let style: CardImageRowPriceStyle
    @Binding var degrees : Double
    @Binding var url : URL?
    
    init(card: MGCard, style: CardImageRowPriceStyle, degrees: Binding<Double>, url: Binding<URL?>) {
        self.card = card
        self.style = style
        _degrees = degrees
        _url = url
    }
    
    var body: some View {
        if style == .oneLine {
            VStack {
                HStack {
                    Text("Normal")
                        .font(.footnote)
                        .foregroundColor(Color.blue)
                    Spacer()
                    Text(card.displayNormalPrice)
                        .font(.footnote)
                        .foregroundColor(Color.blue)
                        .multilineTextAlignment(.trailing)
                    Spacer()
                    CardImageRowButtonView(card: card, degrees: $degrees, url: $url)
                    Spacer()
                    Text("Foil")
                        .font(.footnote)
                        .foregroundColor(Color.green)
                    Spacer()
                    Text(card.displayFoilPrice)
                        .font(.footnote)
                        .foregroundColor(Color.green)
                        .multilineTextAlignment(.trailing)
                }
            }
                .padding(5)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color.secondary, lineWidth: 1)
//                )
        } else {
            HStack {
                VStack(alignment: .leading) {
                    Text("Normal")
                        .font(.footnote)
                        .foregroundColor(Color.blue)
                    Spacer()
                    Text("Foil")
                        .font(.footnote)
                        .foregroundColor(Color.green)
                    
                }
                Spacer()
                CardImageRowButtonView(card: card, degrees: $degrees, url: $url)
                Spacer()
                VStack {
                    Text(card.displayNormalPrice)
                        .font(.footnote)
                        .foregroundColor(Color.blue)
                        .multilineTextAlignment(.trailing)
                    Spacer()
                    Text(card.displayFoilPrice)
                        .font(.footnote)
                        .foregroundColor(Color.green)
                        .multilineTextAlignment(.trailing)
                    }
            }
                .padding(5)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color.secondary, lineWidth: 1)
//                )
        }
    }
}

struct CardImageRowButtonView: View {
    @Binding var degrees : Double
    @Binding var url : URL?
    private let card: MGCard
    private var imageName = ""
    private var url1: URL?
    private var url2: URL?
    
    init(card: MGCard, degrees: Binding<Double>, url: Binding<URL?>) {
        self.card = card
        _degrees = degrees
        _url = url
        
        if card.layout?.name == "Flip" {
            imageName = "goforward"
        } else if card.layout?.name == "Planar" ||
            card.layout?.name == "Split" {
            imageName = "rotate.right"
        } else if card.layout?.name == "Art Series" ||
            card.layout?.name == "Double Faced Token" ||
            card.layout?.name == "Modal Dfc" ||
            card.layout?.name == "Transform" {
            imageName = "arrow.left.and.right.righttriangle.left.righttriangle.right"
        }
        
        url1 = card.imageURL(for: .png)
        url2 = card.imageURL(for: .png, faceOrder: 1)
    }
    
    var body: some View {
        if card.layout?.name == "Flip" ||
           card.layout?.name == "Planar" ||
           card.layout?.name == "Split" ||
           card.layout?.name == "Art Series" ||
           card.layout?.name == "Double Faced Token" ||
           card.layout?.name == "Modal Dfc" ||
           card.layout?.name == "Transform" {
        
            Button(action: {
                action()
            }) {
                Image(systemName: imageName)
                    .renderingMode(.original)
                    .foregroundColor(Color.accentColor)
            }
//                .frame(width: 20, height: 20)
//                .background(
//                    RoundedRectangle(cornerRadius: 50, style: .continuous).fill(Color.white)
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 50, style: .continuous)
//                        .strokeBorder(Color.black, lineWidth: 1)
//                )
                .buttonStyle(PlainButtonStyle())
        } else {
            EmptyView()
        }
    }
    
    func action() {
        if card.layout?.name == "Flip" {
            withAnimation {
                self.degrees = self.degrees == 0 ? 180 : 0
            }
        } else if card.layout?.name == "Planar" ||
            card.layout?.name == "Split" {
            withAnimation {
                self.degrees = self.degrees == 0 ? 90 : 0
            }
        } else if card.layout?.name == "Art Series" ||
            card.layout?.name == "Double Faced Token" ||
            card.layout?.name == "Modal Dfc" ||
            card.layout?.name == "Transform" {
            withAnimation {
                self.degrees = self.degrees == 0 ? 180 : 0
                self.url = self.url == self.url1 ? self.url2 : self.url1
            }
        }
    }
}
