//
//  MainView.swift
//  ManaKit_Example
//
//  Created by Vito Royeca on 11/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI

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
            
            SetsView()
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "rectangle.3.group")
                    Text("Sets")
                }
            
            SearchView()
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
