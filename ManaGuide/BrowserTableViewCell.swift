//
//  BrowserTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 26/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit

class BrowserTableViewCell: UITableViewCell {

    // MARK: Variables
    
    // MARK: Outlets
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    
    // MARK: Actions
    @IBAction func backAction(_ sender: UIBarButtonItem) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @IBAction func forwardAction(_ sender: UIBarButtonItem) {
        if webView.canGoForward {
            webView.goForward()
        }
        
        webView.goForward()
    }
    
    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
