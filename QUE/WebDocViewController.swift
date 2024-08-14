//
//  WebDocViewController.swift
//  QUE
//
//  Created by Krish Kharbanda on 9/12/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import UIKit
import WebKit
import Firebase

class WebDocViewController: UIViewController {

    let db = Firestore.firestore()
    var firstSearch = Bool()
    let clipboard = UIPasteboard()
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.overrideUserInterfaceStyle = .dark
        self.navigationController?.navigationBar.topItem?.title = "Web Document"
        webView.load(URLRequest(url: URL(string: "https://quantumue.wixsite.com/support")!))
        db.collection("Users").document(MasterViewController.docId).getDocument { docSnapshot, err in
            if let error = err {
                print(error.localizedDescription)
                return
            }
            if let document = docSnapshot {
                if document == document {
                    if let searchDone = document.get("firstSearch") as? Bool {
                        self.firstSearch = searchDone
                    }
                }
            }
        }
        firstSearch = false
        if !firstSearch {
            present(storyboard?.instantiateViewController(withIdentifier: "FirstSearchVC") as! FirstSearchViewController, animated: true, completion: nil)
        }
        searchBar.searchTextField.delegate = self
        // Do any additional setup after loading the view.
    }

}
extension WebDocViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        var safeURL = URL(string: "")
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return false }
        if let url = URL(string: text), UIApplication.shared.canOpenURL(url) {
            safeURL = url
        } else {
            guard let encodedSearchString = text.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else { return false }

            if let url = URL(string: "https://www.google.com/search?q=\(encodedSearchString)"), UIApplication.shared.canOpenURL(url) {
                safeURL = url
            }
        }
        self.webView.load(URLRequest(url: safeURL!))
        searchBar.searchTextField.text = self.webView.url!.absoluteString
        view.endEditing(true)
        return false
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        searchBar.searchTextField.resignFirstResponder()
        view.endEditing(true)
    }
}
