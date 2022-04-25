//
//  ContentView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI
import ManaKit

struct ContentView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    var body: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            TabNavigationView()
                .environment(\.horizontalSizeClass, horizontalSizeClass)
        } else {
            SideNavigationView()
                .environment(\.horizontalSizeClass, horizontalSizeClass)
        }
        #else
        SideNavigationView()
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
