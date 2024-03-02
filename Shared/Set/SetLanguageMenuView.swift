//
//  SetLanguageMenuView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 2/25/24.
//

import SwiftUI
import ManaKit

struct SetLanguageMenuView: View {
    @EnvironmentObject private var viewModel: SetViewModel
    @AppStorage("SetLanguageFilter") private var setLanguageFilter = "en"
    
    var body: some View {
        Menu {
            languageFilterMenu
        } label: {
            Text(setLanguageFilter.uppercased())
        }
    }
    
    private var languageFilterMenu: some View {
        Group {
            ForEach(viewModel.commonLanguages(), id:\.code) { language in
                Button(action: {
                    setLanguageFilter = language.code
                    NotificationCenter.default.post(name: NSNotification.SetViewLanguageFilter,
                                                    object: setLanguageFilter)
                }) {
                    if setLanguageFilter == language.code {
                        Label("\(language.displayCode?.uppercased() ?? "") \(language.name ?? "")",
                              systemImage: "checkmark")
                    } else {
                        Text("\(language.displayCode?.uppercased() ?? "") \(language.name ?? "")")
                    }
                }
                .disabled(!(viewModel.setObject?.sortedLanguages ?? []).contains(language))
            }
        }
    }
}

#Preview {
    let viewModel = SetViewModel(setCode: "pip",
                                 languageCode: "en")

    return SetLanguageMenuView()
        .environmentObject(viewModel)
}
