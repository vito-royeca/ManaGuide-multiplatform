//
//  MainView.swift
//  ManaKit_Example
//
//  Created by Vito Royeca on 11/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            SearchView()
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            NavigationView {
                SetsView()
            }
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "rectangle.3.group")
                    Text("Sets")
                }
            
            NavigationView {
                TabTestView(date: Date())
            }
                .navigationViewStyle(.stack)
                .tabItem {
                    Image(systemName: "testtube.2")
                    Text("Test")
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
