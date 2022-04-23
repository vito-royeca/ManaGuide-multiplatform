//
//  MainView.swift
//  ManaKit_Example
//
//  Created by Vito Royeca on 11/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI
import ManaKit

struct MainView: View {
    
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
//                .accentColor(Color.accentColor)
            
            SetsView()
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "rectangle.3.group")
                    Text("Sets")
                }
                .accentColor(Color.accentColor)
            
            SearchView()
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .accentColor(Color.accentColor)
        }
            .accentColor(Color.accentColor)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
