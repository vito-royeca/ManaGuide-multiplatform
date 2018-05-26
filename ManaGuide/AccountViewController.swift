//
//  AccountViewController.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 24/05/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

    // MARK Outlets
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Actions
    @IBAction func loginAction(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showLogin", sender: nil)
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loginButton.image = UIImage.init(icon: .FAArrowCircleRight, size: CGSize(width: 30, height: 30), textColor: .white, backgroundColor: .clear)
        loginButton.title = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
