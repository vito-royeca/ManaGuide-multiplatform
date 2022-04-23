//
//  SearchPathsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/11/22.
//

import SwiftUI

struct SearchPathsView: View {
    var body: some View {
        let paths = NSSearchPathForDirectoriesInDomains(
                        FileManager.SearchPathDirectory.applicationSupportDirectory,
                       .userDomainMask, true)
//        print("Preview in: \(paths)")
        
        Text("Preview in: \(paths.description)")
    }
}

struct SearchPathsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchPathsView()
    }
}
