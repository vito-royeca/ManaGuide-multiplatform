//
//  TabTestView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/22/22.
//

import SwiftUI

struct TabTestView: View {
    @StateObject var viewModel = TabTestViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.tabTests) { tabTest in
                NavigationLink(destination: Text(tabTest.id)) {
                    VStack {
                        Text(tabTest.id)
                        Text("\(tabTest.date)")
                    }
                }
            }
        }
            .listStyle(.plain)
            .navigationBarTitle(viewModel.isBusy ? "Loading..." : "Test")
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
                viewModel.fetchData()
            }
    }
}

struct TabTestView_Previews: PreviewProvider {
    static var previews: some View {
        TabTestView()
    }
}
