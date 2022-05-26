//
//  FullscreenView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/3/22.
//

import SwiftUI

struct FullscreenView: View {
    @State private var isFullScreen = false
    
    var body: some View {
        ZStack{
//            Color.yellow.edgesIgnoringSafeArea(.all)
            Text("Hello, FullScreen!")
                .padding()
//                .background(Color.blue)
//                .foregroundColor(.green)
                .cornerRadius(8)
                .fullScreenCover(isPresented: $isFullScreen) {
                    FullScreenPageView(isFullScreen: $isFullScreen)
                }
                .onTapGesture {
                    isFullScreen.toggle()
                }
        }
    }
}

struct FullscreenView_Previews: PreviewProvider {
    static var previews: some View {
        FullscreenView()
    }
}

struct FullScreenPageView: View {
    @Binding var isFullScreen: Bool
    
    var body: some View {
        ZStack {
//            Color.red.edgesIgnoringSafeArea(.all)
            Text("This is full screen!!")
                .onTapGesture {
                    self.isFullScreen.toggle()
                }
            
        }
    }
}
