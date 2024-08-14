//
//  Utilities.swift
//  QUE
//
//  Created by Krish Kharbanda on 11/12/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import Foundation
import UIKit

class Utilities {
    
    enum EntryType {
        case email
        case password
    }
    
    func validate(entry: String, type: EntryType) -> Bool {
        var regex = String()
        
        switch type {
        case .email:
            regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        case .password:
            regex = "^(?=.*[A-Z])(?=.*[!@#$&*])(?=.*[0-9]).{8,}$"
        }

        let validation = NSPredicate(format:"SELF MATCHES %@", regex)
        return validation.evaluate(with: entry)
    }
    
    func presentAlertController(title: String, message: String, action: String, viewController: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.view.overrideUserInterfaceStyle = .light
        alertController.view.tintColor = UIColor(named: "AccentColor")
        alertController.addAction(UIAlertAction(title: action, style: .default, handler: nil))
        viewController.present(alertController, animated: true, completion: nil)
    }
    
}
