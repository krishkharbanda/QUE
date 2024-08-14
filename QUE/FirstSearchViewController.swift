//
//  FirstSearchViewController.swift
//  QUE
//
//  Created by Krish Kharbanda on 9/15/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import UIKit

class FirstSearchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.overrideUserInterfaceStyle = .dark
        // Do any additional setup after loading the view.
    }
    
    @IBAction func donePressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}
