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
        TabView{
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
                    Image(systemName: "list.number")
                    Text("Sets")
                }

//            NavigationView {
//                RulesView()
//            }
//                .navigationViewStyle(.stack)
//                .tabItem {
//                    Image(systemName: "ruler")
//                    Text("Rules")
//                }
//
//            NavigationView {
//                TestView()
//            }
//                .navigationViewStyle(.stack)
//                .tabItem {
//                    Image(systemName: "testtube.2")
//                    Text("Test")
//                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
