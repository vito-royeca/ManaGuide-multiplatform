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

class PDFViewerViewController: UIViewController {

    // MARK: Variables
    var url: URL?
    
    // MARK: Outlets
    @IBOutlet weak var pdfView: PDFView!
    
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        // pdfView.displayDirection = .horizontal
        
        if let url = url {
            if let pdfDocument = PDFDocument(url: url) {
                pdfView.document = pdfDocument
            }
        }
    }

}
