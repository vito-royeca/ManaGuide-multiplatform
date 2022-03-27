//
//  TinderCardContentView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/27/22.
//

import SwiftUI

struct User: Hashable, CustomStringConvertible {
    var id: Int
    
    let firstName: String
    let lastName: String
    let age: Int
    let mutualFriends: Int
    let imageName: String
    let occupation: String
    
    var description: String {
        return "\(firstName), id: \(id)"
    }
}

struct TinderCardContentView: View {
    @State var users: [User] = [
            User(id: 0, firstName: "Cindy", lastName: "Jones", age: 23, mutualFriends: 4, imageName: "http://managuideapp.com/images/cards/w17/en/3/art_crop.jpg", occupation: "Coach"),
            User(id: 1, firstName: "Mark", lastName: "Bennett", age: 27, mutualFriends: 0, imageName: "http://managuideapp.com/images/cards/10e/en/39star/art_crop.jpg", occupation: "Insurance Agent"),
            User(id: 2, firstName: "Clayton", lastName: "Delaney", age: 20, mutualFriends: 1, imageName: "http://managuideapp.com/images/cards/2ed/en/40/art_crop.jpg", occupation: "Food Scientist"),
            User(id: 3, firstName: "Brittni", lastName: "Watson", age: 19, mutualFriends: 4, imageName: "http://managuideapp.com/images/cards/3ed/en/40/art_crop.jpg", occupation: "Historian"),
            User(id: 4, firstName: "Archie", lastName: "Prater", age: 22, mutualFriends:18, imageName: "http://managuideapp.com/images/cards/4ed/en/50/art_crop.jpg", occupation: "Substance Abuse Counselor"),
            User(id: 5, firstName: "James", lastName: "Braun", age: 24, mutualFriends: 3, imageName: "http://managuideapp.com/images/cards/8ed/en/45/art_crop.jpg", occupation: "Marketing Manager"),
            User(id: 6, firstName: "Danny", lastName: "Savage", age: 25, mutualFriends: 16, imageName: "http://managuideapp.com/images/cards/9ed/en/43/art_crop.jpg", occupation: "Dentist"),
            User(id: 7, firstName: "Chi", lastName: "Pollack", age: 29, mutualFriends: 9, imageName: "http://managuideapp.com/images/cards/dom/en/33/art_crop.jpg", occupation: "Recreational Therapist"),
            User(id: 8, firstName: "Josue", lastName: "Strange", age: 23, mutualFriends: 5, imageName: "http://managuideapp.com/images/cards/v15/en/14/art_crop.jpg", occupation: "HR Specialist"),
            User(id: 9, firstName: "Debra", lastName: "Weber", age: 28, mutualFriends: 13, imageName: "http://managuideapp.com/images/cards/pmoa/en/1/art_crop.jpg", occupation: "Judge")
        ]
    
    private func getCardWidth(_ geometry: GeometryProxy, id: Int) -> CGFloat {
        let offset: CGFloat = CGFloat(users.count - 1 - id) * 10
        return geometry.size.width - offset
    }
    
    private func getCardOffset(_ geometry: GeometryProxy, id: Int) -> CGFloat {
        return  CGFloat(users.count - 1 - id) * 10
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                    TinderDateView()
                    ZStack {
                        ForEach(self.users, id: \.self) { user in
                            TinderCardView(user: user, onRemove: { removedUser in
                                // Remove that user from our array
                                self.users.removeAll { $0.id == removedUser.id }
                               })
                               .animation(.spring(), value: 0.3)
                               .frame(width: self.getCardWidth(geometry, id: user.id),
                                      height: 400)
                               .offset(x: 0, y: self.getCardOffset(geometry, id: user.id))
                        }
                    }
                    Spacer()
                }
            }
        }.padding()
    }
}

struct TinderCardContentView_Previews: PreviewProvider {
    static var previews: some View {
        TinderCardContentView()
    }
}

// MARK: - DateView

struct TinderDateView: View {
    var body: some View {
      // Container to add background and corner radius to
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Friday, 10th January")
                        .font(.title)
                        .bold()
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }.padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
