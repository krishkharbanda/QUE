//
//  DetailViewController.swift
//  QUE
//
//  Created by Krish Kharbanda on 5/22/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation
import FirebaseDynamicLinks
import FirebaseFirestore

class DetailViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var questionTextField: UITextField!
    @IBOutlet weak var documentTextView: UITextView!
    @IBOutlet weak var questionTextFieldBottomLayoutConstraint: NSLayoutConstraint!
    
    let db = Firestore.firestore()
    
    let que = QUE()
    var counter = 0
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: "")
    
    
    func configureView() {
        
        guard let detail = detailItem else {
            return
        }
        
        navigationController?.navigationBar.topItem?.title = detail.title
        
        
        guard let textView = documentTextView else {
            return
        }
        
        let fullTextColor = UIColor(named: "Full Text Color")!
        let helveticaNeue17 = UIFont(name: "HelveticaNeue", size: 17)!
        let bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: helveticaNeue17)
        
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: fullTextColor,
                                                         .font: bodyFont]
        
        textView.attributedText = NSAttributedString(string: detail.body, attributes: attributes)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        configureView()
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        /*
        let barButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareDoc))
        barButton.tintColor = .systemGreen
        navigationController?.navigationBar.topItem?.rightBarButtonItem = barButton
        */
        // Do any additional setup after loading the view.
    }
    
    var detailItem: Document? {
        didSet {
            configureView()
        }
    }
    
    @objc func shareDoc() {
        
        var shareUrl = URL(string: "")
        var documentId = String()
        
        guard let detailItem = detailItem else {
            return
        }
        
        DispatchQueue.main.async {
            var daDocs: [String] {
                var myDocs = [String]()
                
                self.db.collection("Users").document(MasterViewController.docId).getDocument { doc, err in
                    if let error = err {
                        print(error.localizedDescription)
                        return
                    }
                    if let document = doc {
                        if let documents = document.get("documents") as? NSArray {
                            myDocs = (documents as? Array<String>) ?? []
                        }
                    }
                }
                return myDocs
            }
            
            self.db.collection("Documents").whereField("title", isEqualTo: detailItem.title).getDocuments { querySnapshot, err in
                if let error = err {
                    print(error.localizedDescription)
                    return
                }
                if let docs = querySnapshot?.documents, !docs.isEmpty  {
                    for document in docs {
                        if document == document {
                            if daDocs.contains(document.documentID) {
                                documentId = document.documentID
                                if let url = document.get("url") as? String {
                                    if let shareURL = URL(string: url), UIApplication.shared.canOpenURL(shareURL) {
                                        shareUrl = shareURL
                                    }
                                } else {
                                    if let shareURl = self.createDynamicLink(docId: documentId), UIApplication.shared.canOpenURL(shareURl) {
                                        shareUrl = shareURl
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        guard let shareURL = shareUrl else { return }
        
        let ac = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        ac.title = "Share \(detailItem.title)"
        ac.excludedActivityTypes = [.assignToContact, .markupAsPDF, .openInIBooks, .saveToCameraRoll, .print]
        self.present(ac, animated: true)
    }
    
    func createDynamicLink(docId: String) -> URL? {
        guard let detailItem = detailItem else {
            return nil
        }
        
        var documentId = docId
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.example.com"
        components.path = "/documents"
        
        if documentId != "" {
            documentId = String((0..<20).map{ _ in MasterViewController().letters.randomElement()! })
        }
        print(documentId)
        self.db.collection("Documents").document(documentId).setData(["title": detailItem.title, "body": detailItem.body])
        
        components.queryItems = [URLQueryItem(name: "doc", value: documentId)]
        guard let linkParameter = components.url else { return nil }
        guard let linkBuilder = DynamicLinkComponents(link: linkParameter, domainURIPrefix: "https://quantumue.page.link/") else { return nil }
        if let myBundleId = Bundle.main.bundleIdentifier {
            linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
        }
        linkBuilder.iOSParameters?.appStoreID = "1569242797"
        linkBuilder.iOSParameters?.fallbackURL = URL(string: "https://quantumue.wixsite.com/support")
        
        let socialParameters = DynamicLinkSocialMetaTagParameters()
        socialParameters.title = detailItem.title
        socialParameters.descriptionText = "You have been invited to use the document \(detailItem.title). Click the link below to open the app, or if you don't have it, you will be redirected to the support page, where the app's App Store link will be provided."
        socialParameters.imageURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/quantumuniqueengine.appspot.com/o/QUE%20App%20Icon.png?alt=media&token=3daa643e-4519-43fd-81fc-2c30b7643895")
        
        linkBuilder.socialMetaTagParameters = socialParameters
        
        guard let longDynamicLink = linkBuilder.url else { return nil }
        print("The long URL is: \(longDynamicLink)")
        
        var sharingURL = URL(string: "")
        
        linkBuilder.shorten { url, warnings, err in
            if let error = err {
                print(error.localizedDescription)
                return
            }
            if let shortUrl = url {
                sharingURL = shortUrl
            }
        }
        return sharingURL
    }
    
    // MARK: - Updating Methods
    private static let appDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let searchText = textField.text ?? ""
        let placeholder = textField.placeholder
        textField.placeholder = "Searching..."
        textField.text = ""
        let body = self.documentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        detailItem?.body = body
        
        guard let detail = detailItem else {
            return false
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let answer = self.que.findAnswer(for: searchText, in: detail.body)
            print(answer)
            DispatchQueue.main.async {
                if answer.base == detail.body, let textView = self.documentTextView {
                    let semiTextColor = UIColor(named: "Semi Text Color")!
                    let helveticaNeue17 = UIFont(name: "HelveticaNeue", size: 17)!
                    let bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: helveticaNeue17)
                    
                    let mutableAttributedText = NSMutableAttributedString(string: detail.body,
                                                                          attributes: [.foregroundColor: semiTextColor,
                                                                                       .font: bodyFont])
                    
                    let location = answer.startIndex.utf16Offset(in: detail.body)
                    let length = answer.endIndex.utf16Offset(in: detail.body) - location
                    let answerRange = NSRange(location: location, length: length)
                    let fullTextColor = UIColor(named: "Full Text Color")!
                    
                    print(answerRange)
                    
                    mutableAttributedText.addAttributes([.foregroundColor: fullTextColor],
                                                        range: answerRange)
                    textView.attributedText = mutableAttributedText
                }
                var finalText = searchText
                if finalText.last != "?" {
                    finalText += "?"
                }
                textField.text = finalText
                textField.placeholder = placeholder
                self.speechUtterance = AVSpeechUtterance(string: String(answer))
                self.speechSynthesizer.speak(self.speechUtterance)
            }
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        configureView()
        return true
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let detail = detailItem else { return }
        for object in MasterViewController.objects {
            if object.title == detail.title {
                break
            }
            counter += 1
        }
        MasterViewController.objects[counter].title = detailItem?.title ?? "New Document"
        MasterViewController.objects[counter].body = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        documentTextView.resignFirstResponder()
        questionTextField.resignFirstResponder()
        view.endEditing(true)
    }
    
    // MARK: - Keyboard Event Handling
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIWindow.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIWindow.keyboardWillHideNotification,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let detail = detailItem else { return }
        for object in MasterViewController.objects {
            if object.title == detail.title {
                break
            }
            counter += 1
        }
        MasterViewController.objects[counter].title = detailItem?.title ?? "New Document"
        MasterViewController.objects[counter].body = documentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIWindow.keyboardWillShowNotification,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: UIWindow.keyboardWillHideNotification,
                                                  object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("fetchDocs"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        questionTextField.becomeFirstResponder()
    }
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        animateBottomLayoutConstraint(from: notification)
    }
    
    @objc
    func keyboardWillHide(notification: NSNotification) {
        animateBottomLayoutConstraint(from: notification)
    }
    
    func animateBottomLayoutConstraint(from notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            print("Unable to extract: User Info")
            return
        }
        
        guard let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
            print("Unable to extract: Animation Duration")
            return
        }
        
        guard let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            print("Unable to extract: Keyboard Frame End")
            return
        }
        
        guard let keyboardBeginFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
            print("Unable to extract: Keyboard Frame Begin")
            return
        }
        
        guard let rawAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
            print("Unable to extract: Keyboard Animation Curve")
            return
        }
        
        let offset = keyboardEndFrame.minY - keyboardBeginFrame.minY
        questionTextFieldBottomLayoutConstraint.constant -= offset
        
        let curveOption = UIView.AnimationOptions(rawValue: rawAnimationCurve << 16)
        
        UIView.animate(withDuration: animationDuration,
                       delay: 0.0,
                       options: [.beginFromCurrentState, curveOption],
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
    }
}
