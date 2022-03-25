//
//  CardsViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/24/22.
//

import CoreData
import SwiftUI
import ManaKit

class CardsViewModel: NSObject, ObservableObject {

    // MARK: - Published Variables
    @Published var cards = [MGCard]()
    @Published var isBusy = false
    
    func fetchData() { }
    
    func fetchLocalData() { }
}
