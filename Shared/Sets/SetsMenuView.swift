//
//  SetsMenuView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/14/23.
//

import SwiftUI

struct SetsMenuView: View {
    @EnvironmentObject private var viewModel: SetsViewModel
    @AppStorage("SetsViewSort") private var setsSort = SetsViewSort.defaultValue
    @AppStorage("SetsTypeFilter") private var setsTypeFilter: String?

    var body: some View {
        Menu {
            sortByMenu
            typeFilterMenu
            clearMenu
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    var sortByMenu: some View {
        Menu {
            ForEach(SetsViewSort.allCases, id:\.description) { sort in
                Button(action: {
                    setsSort = sort
                    NotificationCenter.default.post(name: NSNotification.SetsViewSort,
                                                    object: setsSort)
                }) {
                    if setsSort == sort {
                        Label(setsSort.description,
                              systemImage: "checkmark")
                    } else {
                        Text(sort.description)
                    }
                }
            }
        } label: {
            Label("Sort by\n\(setsSort.description)",
                  systemImage: "arrow.up.arrow.down")
        }
    }
    
    var typeFilterMenu: some View {
        Menu {
            Button(action: {
                setsTypeFilter = nil
                NotificationCenter.default.post(name: NSNotification.SetsViewTypeFilter,
                                                object: setsTypeFilter)
            }) {
                if setsTypeFilter == nil {
                    Label(String.emdash,
                          systemImage: "checkmark")
                } else {
                    Text(String.emdash)
                }
            }

            ForEach(viewModel.setTypes(), id: \.name) { setType in
                Button(action: {
                    setsTypeFilter = setType.name
                    NotificationCenter.default.post(name: NSNotification.SetsViewTypeFilter,
                                                    object: setsTypeFilter)
                }) {
                    if setsTypeFilter == setType.name {
                        Label("\(setsTypeFilter ?? "")",
                              systemImage: "checkmark")
                    } else {
                        Text("\(setType.name ?? "")")
                    }
                }
            }
        } label: {
            Label("Filter by Type\n\(setsTypeFilter ?? String.emdash)",
                  systemImage: "doc.text.magnifyingglass")
        }
    }
    
    var clearMenu: some View {
        Button(action: {
            setsSort = SetsViewSort.defaultValue
            setsTypeFilter = nil
            NotificationCenter.default.post(name: NSNotification.SetsViewClear,
                                            object: nil)
        }) {
            Label("Reset to defaults",
                  systemImage: "clear")
        }
    }
}

#Preview {
    let viewModel = SetsViewModel()

    return SetsMenuView()
        .environmentObject(viewModel)
}
