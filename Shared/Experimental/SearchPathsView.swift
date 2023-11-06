//
//  SearchPathsView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 4/11/22.
//

import SwiftUI

struct SearchPathsView: View {
    var body: some View {
        let directory = FileManager.SearchPathDirectory.applicationSupportDirectory
        let paths = NSSearchPathForDirectoriesInDomains(directory,
                                                        .userDomainMask,
                                                        true)
        Text("Preview in: \(paths.description)")
    }
}

#Preview {
    SearchPathsView()
}
