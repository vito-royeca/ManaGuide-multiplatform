//
//  TextViewWrapper.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI

struct TextViewWrapper: UIViewRepresentable {
    var attributedText: NSAttributedString
    var maxLayoutWidth: CGFloat
    var textViewStore: TextViewStore
    
    func makeUIView(context: Context) -> TextView {
        let uiView = TextView()
        
        uiView.backgroundColor = .clear
        uiView.textContainerInset = .zero
        uiView.isEditable = false
        uiView.isScrollEnabled = false
        uiView.textContainer.lineFragmentPadding = 0
        
        return uiView
    }
    
    func updateUIView(_ uiView: TextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.maxLayoutWidth = maxLayoutWidth
        
        uiView.textContainer.maximumNumberOfLines = context.environment.lineLimit ?? 0
        uiView.textContainer.lineBreakMode = NSLineBreakMode(context.environment.truncationMode)
        
        switch context.environment.font ?? .body {
        case .largeTitle:
            uiView.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title:
            uiView.font = UIFont.preferredFont(forTextStyle: .title1)
        case .title2:
            uiView.font = UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            uiView.font = UIFont.preferredFont(forTextStyle: .title3)
        case .headline:
            uiView.font = UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:
            uiView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        case .callout:
            uiView.font = UIFont.preferredFont(forTextStyle: .callout)
        case .caption:
            uiView.font = UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2:
            uiView.font = UIFont.preferredFont(forTextStyle: .caption2)
        case .footnote:
            uiView.font = UIFont.preferredFont(forTextStyle: .footnote)
        case .body:
            fallthrough
        default:
            uiView.font = UIFont.preferredFont(forTextStyle: .body)
        }
        
        switch context.environment.multilineTextAlignment {
        case .leading:
            uiView.textAlignment = .left
        case .center:
            uiView.textAlignment = .center
        case .trailing:
            uiView.textAlignment = .right
        }
        
        textViewStore.didUpdateTextView(uiView)
    }
}

extension NSLineBreakMode {
    init(_ truncationMode: Text.TruncationMode) {
        switch truncationMode {
        case .head:
            self = .byTruncatingHead
        case .tail:
            self = .byTruncatingTail
        case .middle:
            self = .byTruncatingMiddle
        @unknown default:
            self = .byWordWrapping
        }
    }
}

final class TextView: UITextView {
    var maxLayoutWidth: CGFloat = 0 {
        didSet {
            guard maxLayoutWidth != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        guard maxLayoutWidth > 0 else {
            return super.intrinsicContentSize
        }

        return sizeThatFits(
            CGSize(width: maxLayoutWidth, height: .greatestFiniteMagnitude)
        )
    }
}

extension GeometryProxy {
    var maxWidth: CGFloat {
        size.width - safeAreaInsets.leading - safeAreaInsets.trailing
    }
}

final class TextViewStore: ObservableObject {
    @Published private(set) var height: CGFloat?
    
    func didUpdateTextView(_ textView: TextView) {
        height = textView.intrinsicContentSize.height
    }
}

struct AttributedText: View {
    @StateObject private var textViewStore = TextViewStore()
    private let attributedText: NSAttributedString
    
    init(_ attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }
    
    var body: some View {
        GeometryReader { geometry in
            TextViewWrapper(
                attributedText: attributedText,
                maxLayoutWidth: geometry.maxWidth,
                textViewStore: textViewStore
            )
        }
            .frame(height: textViewStore.height)
    }
}

struct AttributedText_Previews: PreviewProvider {
    static var previews: some View {
        AttributedText(
            NSAttributedString(
                string: "I had called upon my friend, ...",
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .backgroundColor: UIColor.yellow
                ]
            )
        )
            .lineLimit(2)
            .truncationMode(.middle)
    }
}
