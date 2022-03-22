//
//  SearchNavigation.swift
//  ManaGuide
//
//  Created by Vito Royeca on 3/21/22.
//

import SwiftUI

public struct SearchNavigationOptionKey: Hashable, Equatable, RawRepresentable {
    public static let automaticallyShowsSearchBar = SearchNavigationOptionKey("automaticallyShowsSearchBar")
    public static let obscuresBackgroundDuringPresentation = SearchNavigationOptionKey("obscuresBackgroundDuringPresentation")
    public static let hidesNavigationBarDuringPresentation = SearchNavigationOptionKey("hidesNavigationBarDuringPresentation")
    public static let hidesSearchBarWhenScrolling = SearchNavigationOptionKey("hidesSearchBarWhenScrolling")
    public static let placeholder = SearchNavigationOptionKey("Placeholder")
    public static let showsBookmarkButton = SearchNavigationOptionKey("showsBookmarkButton")
    public static let scopeButtonTitles = SearchNavigationOptionKey("scopeButtonTitles")
    public static let searchTextFieldFont = SearchNavigationOptionKey("searchTextFieldFont")
    public static let scopeBarButtonTitleTextAttributes = SearchNavigationOptionKey("scopeBarButtonTitleTextAttributes")
    
    public static func == (lhs: SearchNavigationOptionKey, rhs: SearchNavigationOptionKey) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
}

protocol SearchNavigationDelegate {
    var options: [SearchNavigationOptionKey : Any]? { get }
    func search()
    func scope()
    func cancel()
}

struct SearchNavigation<Content: View>: UIViewControllerRepresentable {
    @Binding var query: String?
    @Binding var scopeSelection: Int
    @Binding var isBusy: Bool
    var delegate: SearchNavigationDelegate?
    var content: () -> Content

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: context.coordinator.rootViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        
        context.coordinator.searchController.searchBar.delegate = context.coordinator
        
        // my additions
        let searchBar = context.coordinator.searchController.searchBar
        if let placeholder = delegate?.options?[.placeholder] as? String {
            searchBar.placeholder = placeholder
        }
        if let scopeButtonTitles = delegate?.options?[.scopeButtonTitles] as? [String] {
            searchBar.scopeButtonTitles = scopeButtonTitles
        }
        if let scopeBarButtonTitleTextAttributes = delegate?.options?[.scopeBarButtonTitleTextAttributes] as? [NSMutableAttributedString.Key: Any] {
            searchBar.setScopeBarButtonTitleTextAttributes(scopeBarButtonTitleTextAttributes, for: .normal)
        }
        if let searchTextFieldFont = delegate?.options?[.searchTextFieldFont] as? UIFont {
            searchBar.searchTextField.font = searchTextFieldFont
            
            if let placeholderLabel = searchBar.searchTextField.value(forKey: "placeholderLabel") as? UILabel {
                placeholderLabel.font = searchTextFieldFont
            }
        }
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        context.coordinator.update(content: content())
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(content: content(),
                    query: $query,
                    scopeSelection: $scopeSelection,
                    isBusy: $isBusy,
                    delegate: delegate)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var query: String?
        @Binding var scopeSelection: Int
        @Binding var isBusy: Bool
        var delegate: SearchNavigationDelegate?
        let rootViewController: UIHostingController<Content>
        let searchController = UISearchController(searchResultsController: nil)
        
        init(content: Content,
             query: Binding<String?>,
             scopeSelection: Binding<Int>,
             isBusy: Binding<Bool>,
             delegate: SearchNavigationDelegate?) {
            rootViewController = UIHostingController(rootView: content)
            searchController.searchBar.autocapitalizationType = .none
            searchController.obscuresBackgroundDuringPresentation = false
            rootViewController.navigationItem.searchController = searchController
            
            
            _query = query
            _scopeSelection = scopeSelection
            _isBusy = isBusy
            self.delegate = delegate
        }
        
        func update(content: Content) {
            rootViewController.rootView = content
            rootViewController.view.setNeedsDisplay()
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                   selector: #selector(self.doSearch(_:)),
                                                   object: searchBar)
            perform(#selector(self.doSearch(_:)),
                    with: searchBar,
                    afterDelay: 0.75)
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            if !isBusy {
                delegate?.search()
            }
        }
        
        func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
            if !isBusy {
                scopeSelection = selectedScope
                delegate?.scope()
            }
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            query = nil
            scopeSelection = 0
            delegate?.cancel()
        }
        
        @objc func doSearch(_ searchBar: UISearchBar) {
            guard let searchText = searchBar.text,
                searchText.trimmingCharacters(in: .whitespaces) != "" else {
                return
            }
            
            query = searchText
            if !isBusy {
                delegate?.search()
            }
        }
    }
    
}

