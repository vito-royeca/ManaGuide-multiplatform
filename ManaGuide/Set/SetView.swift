//
//  SetView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI
import ManaKit
import SDWebImageSwiftUI

struct SetView: View {
    @StateObject var viewModel: SetViewModel
    
    init(setCode: String, languageCode: String) {
        _viewModel = StateObject(wrappedValue: SetViewModel(setCode: setCode, languageCode: languageCode))
        
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }
    
    var body: some View {
        CardsView(viewModel: viewModel) {
            if let set = viewModel.set {
                VStack(spacing: 0) {
                    SetRowView(set: set)
                    LazyVGrid(columns: [GridItem(),GridItem(),GridItem(),GridItem(),GridItem(),GridItem()], spacing: 0) {
                        ForEach(set.sortedLanguageCodes ?? [], id:\.self) { code in
                            if displayCode(for: viewModel.languageCode) == code {
                                Text(code)
                                    .foregroundColor(Color.gray)
                            } else {
                                Button(code, action: {
                                    viewModel.languageCode = reverseDisplayCode(for: code)
                                    viewModel.fetchData()
                                })
                                    .buttonStyle(PlainButtonStyle())
                                    .foregroundColor(Color.blue)
                            }
                        }
                    }
                }
            } else {
                EmptyView()
            }
        }
            .navigationBarTitle {
                Button(action: {
                  // do nothing
                }) {
                    if let set = viewModel.set,
                       let url = set.logoURL {
                        WebImage(url: url)
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                    } else {
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
    }
    
    func displayCode(for code: String) -> String {
        if code == "zhs" {
            return "汉语"
        } else if code == "zht" {
            return "漢語"
        } else {
            return code.uppercased()
        }
    }
    
    func reverseDisplayCode(for code: String) -> String {
        if code == "汉语" {
            return "zhs"
        } else if code == "漢語" {
            return "zht"
        } else {
            return code.lowercased()
        }
    }
}

struct SetView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetView(setCode: "afr", languageCode: "en")
        }
    }
}
