//
//  View+Extras.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/31/22.
//

import SwiftUI
import CoreData

// MARK: - addColor(to:colorScheme:)

extension View {
    func addColor(to attributedString: NSAttributedString, colorScheme: ColorScheme) -> NSAttributedString {
        let newAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        let range = NSRange(location: 0, length: newAttributedString.string.count)
        let color = colorScheme == .dark ? UIColor.white : UIColor.black
        newAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        
        return newAttributedString
    }
}

// MARK: - SectionIndex

struct SectionIndex: ViewModifier {
    let sections: [NSFetchedResultsSectionInfo]
    let sectionIndexTitles: [String]
    
    func body(content: Content) -> some View {
        var body: some View {
            ScrollViewReader { scrollProxy in
                if sectionIndexTitles.isEmpty {
                    content
                } else {
                    ZStack {
                        content
                            .padding(.trailing, 7)
                        VStack {
                            ForEach(sectionIndexTitles, id: \.self) { sectionIndexTitle in
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        let name = sections.filter( { $0.indexTitle == sectionIndexTitle} ).first?.name ?? ""

                                        withAnimation {
                                            scrollProxy.scrollTo(name, anchor: .top)
                                        }
                                    }, label: {
                                        Text(sectionIndexTitle)
                                            .frame(width: 16)
                                            .font(.footnote)
                                            .padding(.trailing, 7)
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return body
    }
}

// MARK: - MeasureSize

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct MeasureSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self,
                                   value: geometry.size)
        })
    }
}

extension View {
    func measureSize(perform action: @escaping (CGSize) -> Void) -> some View {
        self.modifier(MeasureSizeModifier())
            .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}
