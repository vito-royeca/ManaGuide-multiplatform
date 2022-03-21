//
//  ManaGuideApp.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit

@main
struct ManaGuideApp: App {
    @Environment(\.scenePhase) var scenePhase

    init() {
        print("docsPath = \(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])")
        
        ManaKit.shared.configure(apiURL: "http://managuideapp.com")
        ManaKit.shared.setupResources()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .onChange(of: scenePhase) { newScenePhase in
              switch newScenePhase {
              case .active:
                print("App is active")
              case .inactive:
                print("App is inactive")
              case .background:
                print("App is in background")
              @unknown default:
                print("Oh - interesting: I received an unexpected new value.")
              }
            }
    }
}
