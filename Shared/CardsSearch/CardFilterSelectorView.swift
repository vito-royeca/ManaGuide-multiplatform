//
//  CardFilterSelectorView.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 12/11/23.
//

import SwiftUI
import CoreData
import ManaKit

struct CardFilterSelectorView<T: MGEntity>: View {
    @ObservedObject var viewModel: ViewModel
    var type: T.Type
    @Binding var selectedFilters: [T]
    
    @State private var filters = [NSManagedObjectID: Bool]()
    @State private var query = ""
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    fetchRemoteData()
                }
            } else {
                contentView
            }
        }
        .onAppear {
            fetchRemoteData()
        }
        .onDisappear {
            updateFilters()
        }
        .onChange(of: query) { _ in
            search()
        }
    }
    
    private var contentView: some View {
        List {
            ForEach(viewModel.sections, id: \.name) { section in
                Section(header: Text(section.name)) {
                    ForEach(section.objects as? [T] ?? []) { filter in
                        Toggle(filter.description,
                               isOn: binding(for: filter.objectID))
                    }
                }
            }
        }
            .modifier(SectionIndex(sections: viewModel.sections,
                                   sectionIndexTitles: viewModel.sectionIndexTitles))
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search...")
    }
    
    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchRemoteData()

            for object in viewModel.dataArray(type) {
                filters[object.objectID] = selectedFilters.contains(object) ? true : false
            }
        }
    }
    
    private func search() {
        viewModel.query = query
        viewModel.fetchLocalData()
    }

    private func updateFilters() {
        selectedFilters.removeAll()

        for (key, value) in filters {
            if value,
                let filter = viewModel.find(type,
                                           id: key) {
                selectedFilters.append(filter)
            }
        }
        selectedFilters = selectedFilters.sorted(by: { $0.description < $1.description })
    }

    private func binding(for key: NSManagedObjectID) -> Binding<Bool> {
        return Binding(get: {
            return self.filters[key] ?? false
        }, set: {
            self.filters[key] = $0
        })
    }
}

#Preview {
    let model = CardTypesViewModel()
    return CardFilterSelectorView(viewModel: model,
                                  type: MGCardType.self,
                                  selectedFilters: .constant([]))
}
