//
//  ViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 7/2/22.
//

import SwiftUI
import CoreData
import ManaKit

class ViewModel: NSObject, ObservableObject {
    // MARK: - Published Variables
    
    @Published var sections = [NSFetchedResultsSectionInfo]()
    @Published var isBusy = false
    @Published var isFailed = false
    var query = ""
    
    // MARK: - Variables
    
    var sortDescriptors: [NSSortDescriptor] {
        get {
            return [NSSortDescriptor]()
        }
    }
    
    var sectionNameKeyPath: String? {
        get {
            return nil
        }
    }
    
    var sectionIndexTitles: [String] {
        get {
            return []
        }
    }
    
    // MARK: - Methods
    
    func fetchRemoteData() async throws { }
    func fetchLocalData()  { }
    func dataArray<T: MGEntity>(_ type: T.Type) -> [T] {
        return [T]()
    }
    
    func find<T: MGEntity>(_ entity: T.Type,
                           id: NSManagedObjectID) -> T? {
        return ManaKit.sharedCoreData.viewContext.object(with: id) as? T
    }
    
    func find<T: MGEntity>(_ entity: T.Type,
                           ids: [NSManagedObjectID]) -> [T] {
        var array = [T]()
        
        for id in ids {
            if let object = ManaKit.sharedCoreData.viewContext.object(with: id) as? T {
                array.append(object)
            }
        }
        
        return array
    }
}
