//
//  PDFViewerViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 28/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import ManaKit
import PDFKit
import WebKit

class PDFViewerViewController: UIViewController {

    // MARK: Variables
    var url: URL?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if #available(iOS 11.0, *) {
            let pdfView = PDFView(frame: view.frame)
            view.addSubview(pdfView)
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            pdfView.displayMode = .singlePageContinuous
            pdfView.autoScales = true
            // pdfView.displayDirection = .horizontal
            
            if let url = url {
                if let pdfDocument = PDFDocument(url: url) {
                    pdfView.document = pdfDocument
                }
            }
        } else {
            // Fallback on earlier versions
            let webView = WKWebView(frame: view.frame)
            view.addSubview(webView)
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            
            if let url = url {
                webView.loadFileURL(url, allowingReadAccessTo: url)
            }
        }
    }

}
