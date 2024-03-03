//
//  TabNavigationView.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 4/24/22.
//

import SwiftUI
import ManaKit

struct TabNavigationView: View {
    
    @State private var tabState: Visibility = .visible
    private let keyruneUnicode = "e615" // Legends
    
    var body: some View {
        TabView {
//            NavigationView {
//                NewsView()
//            }
//                .navigationViewStyle(.stack)
//                .tabItem {
//                    Image(systemName: "newspaper")
//                    Text("News")
//                }

            TabStateScrollView(tabState: $tabState) {
                SetsView()
            }
            .toolbar(tabState, for: .tabBar)
            .animation(.easeInOut(duration: 0.3), value: tabState)
            .tabItem {
                Image(systemName: "rectangle.3.group")
                Text("Sets")
            }

            TabStateScrollView(tabState: $tabState) {
                CardsSearchFormView()
            }
            .toolbar(tabState, for: .tabBar)
            .animation(.easeInOut(duration: 0.3), value: tabState)
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
        }
    }
}

struct TabNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        TabNavigationView()
    }
}
