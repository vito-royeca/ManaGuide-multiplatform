//
//  CardView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import CoreData
import SwiftUI
import ManaKit
import SwiftUIPager
import SwiftUIX

struct CardView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: CardViewModel
    @State private var isShowingShareSheet = false
    private var withCloseButton: Bool

    init(newID: String,
         relatedCards: [NSManagedObjectID],
         withCloseButton: Bool) {
        _viewModel = StateObject(wrappedValue: CardViewModel(newID: newID,
                                                             relatedCards: relatedCards))
        self.withCloseButton = withCloseButton
    }
    
    var body: some View {
        Group {
            if viewModel.isBusy {
                BusyView()
            } else if viewModel.isFailed {
                ErrorView {
                    fetchRemoteData()
                }
            } else {
                #if os(iOS)
                if horizontalSizeClass == .compact {
                    compactView
                } else {
                    regularView
                }
                #else
                regularView
                #endif
            }
        }
        .onAppear {
            fetchRemoteData()
        }
    }
    
    private var compactView: some View {
        GeometryReader { proxy in
            if let cardObject = viewModel.cardObject {
                List {
                    Section {
                        let width = proxy.size.width * 0.7
                        let height = proxy.size.height * 0.4
                        carouselView(card: cardObject.objectID,
                                     width: width,
                                     height: height)
                    }
                    
                    if let prices = cardObject.prices?.allObjects as? [MGCardPrice] {
                        Section {
                            CardPricingInfoView(prices: prices)
                        }
                    }
                    
                    if let faces = cardObject.sortedFaces {
                        ForEach(faces) { face in
                            Section {
                                CardCommonInfoView(card: face)
                            }
                        }
                    } else {
                        Section {
                            CardCommonInfoView(card: cardObject)
                        }
                    }
                    
                    Section {
                        CardOtherInfoView(card: cardObject)
                    }
                    Section {
                        CardExtraInfoView(card: cardObject)
                    }
                }
                    .navigationBarTitle(Text(cardObject.displayName ?? ""))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        CardToolbar(withCloseButton: withCloseButton,
                                    presentationMode: presentationMode,
                                    isShowingShareSheet: $isShowingShareSheet)
                    }
                    .sheet(isPresented: $isShowingShareSheet, content: {
                        activityView
                    })
            } else {
                EmptyView()
            }
        }
    }
    
    private var regularView: some View {
        GeometryReader { proxy in
            if let card = viewModel.card,
               let cardObject = viewModel.find(MGCard.self, id: card) {
                
                HStack(alignment: .top) {
                    let width = proxy.size.width * 0.7
                    let height = proxy.size.height * 0.7
                    
                    List {
                        carouselView(card: card,
                                     width: width,
                                     height: height)
                        
                        if let prices = cardObject.prices?.allObjects as? [MGCardPrice] {
                            Section {
                                CardPricingInfoView(prices: prices)
                            }
                        }
                    }
                
                    List {
                        if let faces = cardObject.sortedFaces {
                            ForEach(faces) { face in
                                Section {
                                    CardCommonInfoView(card: face)
                                }
                            }
                        } else {
                            Section {
                                CardCommonInfoView(card: cardObject)
                            }
                        }
                        
                        Section {
                            CardOtherInfoView(card: cardObject)
                        }
                        Section {
                            CardExtraInfoView(card: cardObject)
                        }
                    }
                    
                }
                    .navigationBarTitle(Text(cardObject.displayName ?? ""))
                    .toolbar {
                        CardToolbar(withCloseButton: withCloseButton,
                                    presentationMode: presentationMode,
                                    isShowingShareSheet: $isShowingShareSheet)
                    }
                    .sheet(isPresented: $isShowingShareSheet) {
                        activityView
                    }
            } else {
                EmptyView()
            }
        }
    }

    private func carouselView(card: NSManagedObjectID, width: CGFloat, height: CGFloat) -> some View {
        Pager(page: Page.withIndex(viewModel.relatedCards.firstIndex(of: card) ?? 0),
              data: viewModel.relatedCards.isEmpty ? [card] : viewModel.relatedCards) { card in
            if let cardObject = viewModel.find(MGCard.self,
                                               id: card) {
                CardImageRowView(card: cardObject)
            }
        }
            .onPageChanged({ pageNumber in
                let card = viewModel.relatedCards[pageNumber]
                
                if let cardObject = viewModel.find(MGCard.self,
                                                   id: card) {
                    viewModel.newID = cardObject.newIDCopy
                    fetchRemoteData()
                }
            })
            .itemSpacing(0.9)
            .itemAspectRatio(0.9)
            .interactive(scale: 0.9)
            .pagingPriority(.high)
            .frame(height: height)
    }
    
    private var activityView: some View {
        var itemSources = [UIActivityItemSource]()
        
        if let card = viewModel.card,
           let cardObject = viewModel.find(MGCard.self,
                                           id: card) {
            itemSources.append(CardViewItemSource(card: cardObject))
        }

        return AppActivityView(activityItems: itemSources)
            .excludeActivityTypes([])
            .onCancel { }
            .onComplete { result in
                return
            }
    }
    
    private func shareAction() {
        guard let card = viewModel.card,
           let cardObject = viewModel.find(MGCard.self,
                                           id: card) else {
            return
        }
        
        let itemSource = CardViewItemSource(card: cardObject)
        let activityVC = UIActivityViewController(activityItems: [itemSource],
                                                  applicationActivities: nil)

        let connectedScenes = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
        let window = connectedScenes.first?.windows.first { $0.isKeyWindow }

        window?.rootViewController?.present(activityVC, animated: true, completion: nil)
    }
    
    private func fetchRemoteData() {
        Task {
            try await viewModel.fetchRemoteData()
        }
    }
}

// MARK: - CardToolbar
struct CardToolbar: ToolbarContent {
    @Binding var presentationMode: PresentationMode
    @Binding var isShowingShareSheet: Bool
    var withCloseButton: Bool

    init(withCloseButton: Bool,
        presentationMode: Binding<PresentationMode>,
         isShowingShareSheet: Binding<Bool>) {
        self.withCloseButton = withCloseButton
        _presentationMode = presentationMode
        _isShowingShareSheet = isShowingShareSheet
    }
    
    var body: some ToolbarContent {
        if withCloseButton {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: {
                    $presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                }
            }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: {
                isShowingShareSheet.toggle()
            }) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - Previews

#Preview {
    return NavigationView {
        CardView(newID: "rvr_en_273",
                 relatedCards: [],
                 withCloseButton: false)
    }
    .previewInterfaceOrientation(.portraitUpsideDown)
}

