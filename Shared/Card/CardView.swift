//
//  CardView.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import CoreData
import SwiftUI
import ManaKit
import SwiftUIX

struct CardView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: CardViewModel
    @State private var isShowingShareSheet = false
    @State private var selectedMenu: CardMenu = .pricing
    private var withCloseButton: Bool

    @State private var progress: CGFloat = 0
    @AppStorage("CardMenu") private var cardMenu = CardMenu.pricing.description

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
                } cancelAction: {
                    viewModel.isBusy = false
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
            update(menu: cardMenu)
        }
    }
    
    private var compactView: some View {
        GeometryReader { proxy in
            if let cardObject = viewModel.cardObject {
                Form {
                    Section {
                        let width = proxy.size.width
                        let height = proxy.size.height * 0.5
                        CardCarouselView(viewModel: viewModel,
                                         height: height)
                        .frame(width: width, height: height)
                    }
                    .listRowBackground(EmptyView().background(.clear))
                    
                    switch selectedMenu {
                    case .pricing:
                        if let prices = cardObject.prices?.allObjects as? [MGCardPrice] {
                            Section {
                                CardPricingInfoView(prices: prices)
                            }
                        }
                    case .info:
                        Section {
                            CardSetInfoView(card: cardObject)
                        }
                        
                        if let faces = cardObject.sortedFaces {
                            ForEach(faces) { face in
                                Section(face.displayName ?? "") {
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

                    case .extraInfo:
                        Section {
                            CardExtraInfoView(card: cardObject)
                        }
                    case .variations:
                        Section {
                            if !(cardObject.sortedVariations?.isEmpty ?? true)  {
                                CardVariationsView(card: cardObject)
                            } else {
                                Text("No variations")
                                    .listRowBackground(EmptyView().background(.clear))
                            }
                        }
                    case .parts:
                        Section {
                            if !(cardObject.sortedComponentParts?.isEmpty ?? true) {
                                CardComponentPartsView(card: cardObject)
                            } else {
                                Text("No parts")
                                    .listRowBackground(EmptyView().background(.clear))
                            }
                        }
                    case .printings:
                        Section {
                            if !(cardObject.sortedOtherPrintings?.isEmpty ?? true) {
                                CardOtherPrintingsView(card: cardObject)
                            } else {
                                Text("No printings")
                                    .listRowBackground(EmptyView().background(.clear))
                            }
                        }
                    case .languages:
                        Section {
                            if !(cardObject.sortedOtherLanguages?.isEmpty ?? true) {
                                CardLanguagesView(card: cardObject)
                            } else {
                                Text("No languages")
                                    .listRowBackground(EmptyView().background(.clear))
                            }
                        }
                    }
                }
                .navigationTitle(Text(cardObject.displayName ?? ""))
                .toolbar {
                    CardToolbar(withCloseButton: withCloseButton,
                                viewModel: viewModel,
                                presentationMode: presentationMode,
                                isShowingShareSheet: $isShowingShareSheet)
                }
                .sheet(isPresented: $isShowingShareSheet, content: {
                    activityView
                })
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.CardMenu)) { cardMenu in
                    let menu = (cardMenu.object as? String ?? CardMenu.pricing.description)
                    update(menu: menu)
                }
            }
        }
    }
    
    private var regularView: some View {
        GeometryReader { proxy in
            if let cardObject = viewModel.cardObject {
                HStack(alignment: .top) {
                    let height = proxy.size.height * 0.5
                    
                    Form {
                        CardCarouselView(viewModel: viewModel,
                                         height: height)
                        
                        if let prices = cardObject.prices?.allObjects as? [MGCardPrice] {
                            Section {
                                CardPricingInfoView(prices: prices)
                            }
                        }
                    }
                
                    Form {
                        Section {
                            CardSetInfoView(card: cardObject)
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
                    
                }
                    .navigationTitle(Text(cardObject.displayName ?? ""))
                    .toolbar {
                        CardToolbar(withCloseButton: withCloseButton,
                                    viewModel: viewModel,
                                    presentationMode: presentationMode,
                                    isShowingShareSheet: $isShowingShareSheet)
                    }
                    .sheet(isPresented: $isShowingShareSheet) {
                        activityView
                    }
            }
        }
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
    
    private func update(menu: String) {
        selectedMenu = CardMenu.allCases.first(where: { $0.description == menu }) ?? .pricing
    }
}

// MARK: - CardToolbar

struct CardToolbar: ToolbarContent {
    @Binding var presentationMode: PresentationMode
    @Binding var isShowingShareSheet: Bool
    var withCloseButton: Bool
    var viewModel: CardViewModel

    init(withCloseButton: Bool,
         viewModel: CardViewModel,
         presentationMode: Binding<PresentationMode>,
         isShowingShareSheet: Binding<Bool>) {
        self.withCloseButton = withCloseButton
        self.viewModel = viewModel
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
            CardMenuView()
                .environmentObject(viewModel)
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
        CardView(newID: "pip_en_259",
                 relatedCards: [],
                 withCloseButton: true)
    }
    .previewInterfaceOrientation(.landscapeRight)
}

