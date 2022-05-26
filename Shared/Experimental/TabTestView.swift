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
//        TabTestView(date: Date())
        TestScrollView()
    }
}
struct TestScrollView: View {
    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                Button("Jump to #50") {
                    proxy.scrollTo(50, anchor: .top)
                }

                List{
                    ForEach(0..<100) { i in
                        Text("Example \(i)")
                        .id(i)
                    }
                }
                    .onAppear{
                        proxy.scrollTo(45, anchor: .top)
                    }
            }
        }
    }
}
