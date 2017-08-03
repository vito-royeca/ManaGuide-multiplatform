//
//  BaseViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 21/07/2017.
//  Copyright © 2017 Jovito Royeca. All rights reserved.
//

import UIKit
import MMDrawerController

class BaseViewController: UIViewController {

    // MARK: Variables
    var tapBGGesture: UITapGestureRecognizer?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tapBGGesture = UITapGestureRecognizer(target: self, action: #selector(BaseViewController.backgroundTapped(_:)))
        tapBGGesture!.delegate = self
        tapBGGesture!.numberOfTapsRequired = 1
        tapBGGesture!.cancelsTouchesInView = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let tapBGGesture = tapBGGesture {
            view.window!.addGestureRecognizer(tapBGGesture)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tapBGGesture = tapBGGesture {
            view.window!.removeGestureRecognizer(tapBGGesture)
        }
    }
    
    // MARK: Custom methods
    func showSettingsMenu(file: String) {
        if let navigationVC = mm_drawerController.rightDrawerViewController as? UINavigationController {
            var settingsView:SettingsViewController?
            
            for drawer in navigationVC.viewControllers {
                if drawer is SettingsViewController {
                    settingsView = drawer as? SettingsViewController
                }
            }
            if settingsView == nil {
                settingsView = SettingsViewController()
                navigationVC.addChildViewController(settingsView!)
            }
            
            settingsView!.showCreditsFooter = false
            settingsView!.file = file
            navigationVC.popToViewController(settingsView!, animated: true)
        }
        mm_drawerController.toggle(.right, animated:true, completion:nil)
    }
    
    func backgroundTapped(_ sender: UITapGestureRecognizer) {
        
        if sender.state == .ended {
            guard let presentedView = presentedViewController?.view else {
                return
            }
            
            if !presentedView.bounds.contains(sender.location(in: presentedView)) {
                dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func cardSize(inFrame frame: CGSize) -> CGSize {
        let width = frame.width
        let height = frame.height
        let defaultSize = CGSize(width: 480, height: 680)
        var newWidth = CGFloat(0)
        var newHeight = CGFloat(0)
        var itemsInRow = 0
        
        // iPhone portrait = 3
        // iPhone landscape = 4
        // iPad portrait = 4
        // iPad landscape = 6
        // card image = 480x680
        
        switch UIApplication.shared.statusBarOrientation {
        case .portrait,
             .portraitUpsideDown:
            if UIDevice.current.userInterfaceIdiom == .phone {
                itemsInRow = 3
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                itemsInRow = 4
            }
        case .landscapeLeft,
             .landscapeRight:
            if UIDevice.current.userInterfaceIdiom == .phone {
                itemsInRow = 4
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                itemsInRow = 5
            }
        default:
            ()
        }
        
        newWidth = CGFloat(width / CGFloat(itemsInRow))
        newHeight = (newWidth * defaultSize.height) / defaultSize.width
        
        return CGSize(width: newWidth, height: newHeight)
    }
}

// MARK: UIGestureRecognizerDelegate
extension BaseViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
