//
//  TinderCardView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/27/22.
//

import SwiftUI

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct TinderCardView: View {
    @State private var translation: CGSize = .zero
    
    private var user: User
    private var onRemove: (_ user: User) -> Void
    
    // when the user has draged 50% the width of the screen in either direction
    private var thresholdPercentage: CGFloat = 0.5
    
    init(user: User, onRemove: @escaping (_ user: User) -> Void) {
        self.user = user
        self.onRemove = onRemove
    }
    
    private func getGesturePercentage(_ geometry: GeometryProxy, from gesture: DragGesture.Value) -> CGFloat {
        gesture.translation.width / geometry.size.width
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                WebImage(url: URL(string: self.user.imageName))
                    .resizable()
                    .placeholder(Image(uiImage: ManaKit.shared.image(name: .cardBack)!))
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.75)
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(self.user.firstName) \(self.user.lastName), \(self.user.age)")
                            .font(.title)
                            .bold()
                        Text(self.user.occupation)
                            .font(.subheadline)
                            .bold()
                        Text("\(self.user.mutualFriends) Mutual Friends")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer() // Add a spacer to push our HStack to the left and the spacer fill the empty space
                    
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                }
                    .padding(.horizontal)
            }
                // Add padding, corner radius and shadow with blur radius
                .padding(.bottom)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .offset(x: self.translation.width, y: 0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            self.translation = value.translation
                        }.onEnded { value in
                            // 6
                            // determine snap distance > 0.5 aka half the width of the screen
                            if abs(self.getGesturePercentage(geometry, from: value)) > self.thresholdPercentage {
                                self.onRemove(self.user)
                            } else {
                                self.translation = .zero
                            }
                        }
                )
        }
    }
}

struct TinderCardView_Previews: PreviewProvider {
    static var previews: some View {
        TinderCardView(user: User(id: 1, firstName: "Mark", lastName: "Bennett", age: 27, mutualFriends: 0, imageName: "https://managuideapp.com/images/cards/w17/en/3/art_crop.jpg", occupation: "Insurance Agent"),
             onRemove: { _ in
                // do nothing
        })
            .frame(height: 400)
            .padding()
    }
}
