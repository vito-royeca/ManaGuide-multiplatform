//
//  ManaGuideApp.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import Firebase
import ManaKit

@main
struct ManaGuideApp: App {
    @Environment(\.scenePhase) var scenePhase

    init() {
        let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                           .userDomainMask,
                                                           true)[0]
        print("docsPath = \(docsPath)")
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color.accentColor)

        // Server setup
        FirebaseApp.configure()

        ManaKit.shared.configure(apiURL: "https://managuideapp.com")
        Task {
            await ManaKit.shared.setupResources()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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
            .commands {
                SidebarCommands()
            }
    }
}
