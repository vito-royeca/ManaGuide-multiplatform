//
//  TabNavigationView.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 4/24/22.
//

import SwiftUI

struct TabNavigationView: View {
    enum TabItem {
        case news
        case sets
        case search
    }
    
    @State private var selection: TabItem = .news
    
    var body: some View {
        TabView(selection: $selection) {
//            NavigationView {
//                NewsView()
//            }
//                .navigationViewStyle(.stack)
//                .tabItem {
//                    Image(systemName: "newspaper")
//                    Text("News")
//                }
//                .tag(TabItem.news)
//                .accentColor(Color.accentColor)

            SetsView()
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "rectangle.3.group")
                    Text("Sets")
                }
                .tag(TabItem.sets)
                .accentColor(Color.accentColor)

            SearchView()
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(TabItem.search)
                .accentColor(Color.accentColor)
        }
            .accentColor(Color.accentColor)
    }
}

struct TabNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigationView()
    }
}
