//
//  SideNavigationView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/24/22.
//

import SwiftUI

struct SideNavigationView: View {
    enum SideItem {
        case news
        case sets
        case cards
    }
    
    @State private var selection: SideItem? = .news
    
    var body: some View {
        NavigationView {
            let initialView = NewsView()
            
            List {
                NavigationLink(tag: SideItem.news, selection: $selection) {
                    initialView
                } label: {
                    Label("News", systemImage: "newspaper")
                }
                
                NavigationLink(tag: SideItem.sets, selection: $selection) {
                    SetsView()
                } label: {
                    Label("Sets", systemImage: "rectangle.3.group")
                }
                
                NavigationLink(tag: SideItem.cards, selection: $selection) {
                    CardsSearchView()
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
            }

            initialView
            
        }
            .navigationBarTitle("Mana Guide")
    }
}

struct SideNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        SideNavigationView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
