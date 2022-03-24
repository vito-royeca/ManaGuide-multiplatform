//
//  TabTestView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/22/22.
//

import SwiftUI

struct TabTestView: View {
    @StateObject var viewModel: TabTestViewModel
    
    init(date: Date) {
        _viewModel = StateObject(wrappedValue: TabTestViewModel(date: date))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.tabTests) { tabTest in
                NavigationLink(destination: TabTestView(date: tabTest.date)) {
                    VStack(alignment: .leading) {
                        Text(tabTest.id)
                        Text("\(tabTest.date)")
                    }
                }
            }
        }
            .listStyle(.plain)
            .navigationBarTitle(viewModel.isBusy ? "Loading..." : viewModel.date.description)
            .overlay(
                Group {
                    if viewModel.isBusy {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        EmptyView()
                    }
                })
            .onAppear {
                print("onAppear... \(viewModel.tabTests.count)")
                viewModel.fetchData()
            }
    }
}

struct TabTestView_Previews: PreviewProvider {
    static var previews: some View {
        TabTestView(date: Date())
    }
}
