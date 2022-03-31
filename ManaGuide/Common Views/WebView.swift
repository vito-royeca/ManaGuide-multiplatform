//
//  WebView.swift
//  dckx
//
//  Created by Vito Royeca on 2/29/20.
//  Copyright © 2020 Vito Royeca. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    private let webView = WKWebView()
    var link: String?
    var html: String?
    var baseURL: URL?
    
    init (link: String?, html: String?, baseURL: URL?) {
        self.link = link
        self.html = html
        self.baseURL = baseURL == nil ? bundleBaseURL() : baseURL
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        private var control: WebView

        init(_ control: WebView) {
            self.control = control
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated  {
                if let url = navigationAction.request.url,
//                    let host = url.host, !host.hasPrefix("www.google.com"),
                    UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }
            } else {
                decisionHandler(.allow)
            }
        }
    }
    
    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        if let link = link,
            let url = URL(string: link) {
            webView.load(URLRequest(url: url))
        } else if let html = html {
            webView.loadHTMLString(html, baseURL: baseURL)
        }
        
        return webView
    }
        
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        if let link = link,
            let url = URL(string: link) {
//            Readability.parse(url: url, completion: { data in
//                let title = (data?.title ?? "")
//                let text = (data?.text ?? "").replacingOccurrences(of: "\n", with: "<p class='answer'>").replacingOccurrences(of: "|<>|", with: "")
//
//                let css = UserDefaults.standard.bool(forKey: SettingsKey.comicsExplanationUseSystemFont) ? "system.css" : "dckx.css"
//                let head = "<head><link href='\(css)' rel='stylesheet'></head>"
//
//                var html = "<html>\(head)<body>"
//                html += "<h1>\(title)</h1>"
//                html += text
//                html += "</body></html>"
//
//                uiView.loadHTMLString(html, baseURL: baseURL)
//            })
            
                uiView.load(URLRequest(url: url))
            
        } else if let html = html {
            uiView.loadHTMLString(html, baseURL: baseURL)
        }
    }
    
    func makeCoordinator() -> WebView.Coordinator {
        Coordinator(self)
    }
    
    func bundleBaseURL() -> URL? {
        let bundlePath = Bundle.main.bundlePath
        let url = URL(fileURLWithPath: bundlePath)
        return url
    }
}
