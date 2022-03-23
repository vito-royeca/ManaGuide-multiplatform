//
//  TabTestViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/22/22.
//

import CoreData
import SwiftUI
import ManaKit

struct TabTest: Identifiable {
    var id: String
    var date: Date
}

class TabTestViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Variables
    @Published var tabTests = [TabTest]()
    @Published var isBusy = false
    
    func fetchData() {
        guard !isBusy && tabTests.isEmpty else {
            return
        }
        
        isBusy.toggle()
        
        DispatchQueue.global(qos: .background).async {
            var newTabTests = [TabTest]()
            for i in 0...9 {
                newTabTests.append(TabTest(id: "\(i)", date: Date()))
            }
                    
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.tabTests = newTabTests
                self.isBusy.toggle()
            })
        }
    }
}
