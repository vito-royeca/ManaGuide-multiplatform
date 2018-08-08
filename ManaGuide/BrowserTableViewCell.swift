//
//  BrowserTableViewCell.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 26/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import Font_Awesome_Swift

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
        backButton.image = UIImage(bgIcon: .FAArrowCircleLeft,
                                   orientation: UIImageOrientation.up,
                                   bgTextColor: UIColor.lightGray,
                                   bgBackgroundColor: UIColor.clear,
                                   topIcon: .FAArrowCircleLeft,
                                   topTextColor: UIColor.clear,
                                   bgLarge: true,
                                   size: CGSize(width: 20, height: 20))
        
        forwardButton.image = UIImage(bgIcon: .FAArrowRight,
                                      orientation: UIImageOrientation.up,
                                      bgTextColor: UIColor.lightGray,
                                      bgBackgroundColor: UIColor.clear,
                                      topIcon: .FAArrowRight,
                                      topTextColor: UIColor.clear,
                                      bgLarge: true,
                                      size: CGSize(width: 20, height: 20))
        
        refreshButton.image = UIImage(bgIcon: .FARefresh,
                                      orientation: UIImageOrientation.up,
                                      bgTextColor: UIColor.lightGray,
                                      bgBackgroundColor: UIColor.clear,
                                      topIcon: .FARefresh,
                                      topTextColor: UIColor.clear,
                                      bgLarge: true,
                                      size: CGSize(width: 20, height: 20))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
