//
//  SetHeaderView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 11/1/23.
//

import SwiftUI
import ManaKit

struct SetHeaderView: View {
    @ObservedObject var viewModel: SetViewModel
    @Binding var progress: CGFloat

    var body: some View {
        ZStack {
            VStack {
                if let set = viewModel.setObject {
                    SetRowView(set: set,
                               style: .header)
                }
                languageButtonsView
            }
            .padding(.horizontal, 5)
            .offset(y: progress * 50)
        }
    }

    var languageButtonsView: some View {
        HStack {
            Image("language")
                .resizable()
                .frame(width: 20, height: 20)
            ForEach(viewModel.commonLanguages(), id:\.code) { language in
                if viewModel.languageCode == language.code {
                    Text(language.displayCode ?? "")
                        .monospaced()
                } else {
                    Button(action: {
                        viewModel.languageCode = language.code ?? ""
                        Task {
                            try await viewModel.fetchRemoteData()
                        }
                    },
                           label: {
                        Text(language.displayCode ?? "")
                            .monospaced()
                    })
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.accentColor)
                    .disabled(!(viewModel.setObject?.sortedLanguages ?? []).contains(language))
                }
            }
            Spacer()
        }
    }
}

#Preview {
    let viewModel = SetViewModel(setCode: "who",
                                 languageCode: "en")
    Task {
        try await viewModel.fetchRemoteData()
    }
    
    return SetHeaderView(viewModel: viewModel,
                         progress: .constant(0))
}
