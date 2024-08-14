//
//  ViewController.swift
//  QUE
//
//  Created by Krish Kharbanda on 5/22/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var typewriterLbl: UILabel!
    
    var typeWriterText = "Quantum Unique Engine"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        typewriterLbl.text = ""
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.view.addGestureRecognizer(gesture)
        // Do any additional setup after loading the view.
    }
    @objc func onTap() {
        for i in typeWriterText {
            typewriterLbl.text! += "\(i)"
            RunLoop.current.run(until: Date() + 0.1)
        }
    }
    
}
