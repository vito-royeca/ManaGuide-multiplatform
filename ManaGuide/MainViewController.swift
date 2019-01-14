//
//  MainViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 17.10.18.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit
import FontAwesome_swift

class MainViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // setup the ViewModels
        if let viewControllers = viewControllers {
            for vc in viewControllers {
                if let nvc = vc as? UINavigationController {
                    for child in nvc.viewControllers {
                        // TODO: fix this
//                        if let searchVC = child as? SearchViewController {
//                            let viewModel = SearchViewModel(withRequest: nil,
//                                                            andTitle: "Search",
//                                                            andMode: .standBy)
//                            viewModel.isStandBy = true
//                            searchVC.viewModel = viewModel
//                        }
                    }
                }
            }
        }
        
        guard let items = tabBar.items else {
            return
        }
        // TODO: fix this
//        items[2].image = UIImage.fontAwesomeIcon(name: .userCircle,
//                                                 style: .solid,
//                                                 textColor: UIColor.blue,
//                                                 size: CGSize(width: 30, height: 30))        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Spotlight
        let spotlight = SpotlightManager()
        spotlight.createSpotlightItems()
    }
}
