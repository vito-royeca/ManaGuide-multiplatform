//
//  SetsMenuView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/14/23.
//

import SwiftUI

struct SetsMenuView: View {
    @AppStorage("setsSort") private var setsSort = SetsViewSort.releaseDate
    @AppStorage("setsTypeFilter") private var setsTypeFilter: String?
    @EnvironmentObject private var viewModel: SetsViewModel

    var body: some View {
        Menu {
            sortByMenu
            typeFilterMenu
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    var sortByMenu: some View {
        Menu {
            Button(action: {
                setsSort = .name
                NotificationCenter.default.post(name: NSNotification.SetsViewSort,
                                                object: setsSort)
            }) {
                if setsSort == .name {
                    Label("Name",
                          systemImage: "checkmark")
                } else {
                    Text("Name")
                }
            }

            Button(action: {
                setsSort = .releaseDate
                NotificationCenter.default.post(name: NSNotification.SetsViewSort,
                                                object: setsSort)
            }) {
                if setsSort == .releaseDate {
                    Label("Release Date",
                          systemImage: "checkmark")
                } else {
                    Text("Release Date")
                }
            }

            Button(action: {
                setsSort = .type
                NotificationCenter.default.post(name: NSNotification.SetsViewSort,
                                                object: setsSort)
            }) {
                if setsSort == .type {
                    Label("Type",
                          systemImage: "checkmark")
                } else {
                    Text("Type")
                }
            }
        } label: {
            Text("Sort by")
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
                    Label("\u{2014}",
                          systemImage: "checkmark")
                } else {
                    Text("\u{2014}")
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
            Text("Filter by")
        }
    }
}

#Preview {
    let viewModel = SetsViewModel()

    return SetsMenuView()
        .environmentObject(viewModel)
}
