//
//  CardsSearchViewModel.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import CoreData
import SwiftUI
import ManaKit

class CardsSearchViewModel: CardsViewModel {
    
    // MARK: - Variables

    static let maxPageSize = 20
    
    @Published var nameFilter = ""
    @Published var raritiesFilter = [MGRarity]()
    @Published var typesFilter = [MGCardType]()
    @Published var keywordsFilter = [MGKeyword]()
    @Published var pageLimit = maxPageSize
    @Published var pageOffset = 0
    @Published var hasMoreData = true
    @Published var isLoadingNextPage = false

    private var dataAPI: API
    private var frc: NSFetchedResultsController<MGCard>
    private var resultIDs = [NSManagedObjectID]()

    // MARK: - Initializers

    init(dataAPI: API = ManaKit.shared) {
        self.dataAPI = dataAPI
        frc = NSFetchedResultsController()
        
        super.init()
    }
    
    // MARK: - Methods

    override func fetchRemoteData() async throws {
        guard !isBusy else {
            return
        }

        do {
            if try dataAPI.willFetchCards(name: nameFilter,
                                          rarities: raritiesFilter.compactMap { $0.name },
                                          types: typesFilter.compactMap { $0.name },
                                          keywords: keywordsFilter.compactMap { $0.name },
                                          pageSize: CardsSearchViewModel.maxPageSize,
                                          pageOffset: pageOffset) {
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                    self.isFailed = false
                }
                
                resultIDs = try await dataAPI.fetchCards(name: nameFilter,
                                                         rarities: raritiesFilter.compactMap { $0.name },
                                                         types: typesFilter.compactMap { $0.name },
                                                         keywords: keywordsFilter.compactMap { $0.name },
                                                         pageSize: CardsSearchViewModel.maxPageSize,
                                                         pageOffset: pageOffset)
                DispatchQueue.main.async {
                    self.isBusy.toggle()
                }
            }

            DispatchQueue.main.async {
                self.fetchLocalData()
            }

        } catch {
            DispatchQueue.main.async {
                self.isBusy.toggle()
                self.isFailed = true
            }
        }
    }
    
    override func fetchLocalData() {
        frc = NSFetchedResultsController(fetchRequest: defaultFetchRequest(),
                                         managedObjectContext: ManaKit.shared.viewContext,
                                         sectionNameKeyPath: sectionNameKeyPath,
                                         cacheName: nil)
        frc.delegate = self
        

        do {
            try frc.performFetch()
            sections = frc.sections ?? []
            hasMoreData = (frc.fetchedObjects?.count ?? 0) >= CardsSearchViewModel.maxPageSize
        } catch {
            isFailed = true
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension CardsSearchViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = controller.sections ?? []
    }
}

// MARK: - NSFetchRequest

extension CardsSearchViewModel {
    func defaultFetchRequest() -> NSFetchRequest<MGCard> {
        var predicate = NSPredicate()

        if resultIDs.isEmpty {
            do {
//                let url = try dataAPI.fetchCardsURL(name: nameFilter,
//                                                    rarities: raritiesFilter.compactMap { $0.name },
//                                                    types: typesFilter.compactMap { $0.name },
//                                                    keywords: keywordsFilter.compactMap { $0.name },
//                                                    pageSize: CardsSearchViewModel.maxPageSize,
//                                                    pageOffset: pageOffset)
//                let request: NSFetchRequest<SearchResult> = SearchResult.fetchRequest()
//                request.predicate = NSPredicate(format: "pageOffset == %i AND url == %@",
//                                                pageOffset,
//                                                url.absoluteString)
//                let objects = try ManaKit.shared.viewContext.fetch(request)
//
//                predicate = NSPredicate(format: "newID IN %@",
//                                        objects.map { $0.newID })
            } catch {
                print(error)
            }
        } else {
            var newIDs = [String]()
            for resultID in resultIDs {
                if let object = find(MGCard.self,
                                     id: resultID) {
                    newIDs.append(object.newIDCopy)
                }
            }
            predicate = NSPredicate(format: "newID IN %@",
                                    newIDs)
        }

        let request: NSFetchRequest<MGCard> = MGCard.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        request.fetchLimit = pageLimit
        request.fetchOffset = pageOffset

        return request
    }
}

extension CardsSearchViewModel {
    var cards: [NSManagedObjectID] {
        guard let array = frc.fetchedObjects else {
            return []
        }
        return array.map { $0.objectID }
    }
    
    func willFetch() -> Bool {
        !nameFilter.isEmpty && nameFilter.count >= 4 ||
        !raritiesFilter.isEmpty ||
        !typesFilter.isEmpty ||
        !keywordsFilter.isEmpty
    }
    
    func resetFilters() {
        nameFilter = ""
        raritiesFilter.removeAll()
        typesFilter.removeAll()
        keywordsFilter.removeAll()
    }
    
    func resetPagination() {
        pageOffset = 0
        pageLimit = CardsSearchViewModel.maxPageSize
        resultIDs.removeAll()
    }
    
    func fetchRemoteNextPage() async throws {
        DispatchQueue.main.async {
            self.pageOffset += CardsSearchViewModel.maxPageSize
            self.pageLimit = self.pageOffset
            self.isLoadingNextPage = true
        }
        
        try await fetchRemoteData()
        
        DispatchQueue.main.async {
            self.isLoadingNextPage = false
        }
    }
}
