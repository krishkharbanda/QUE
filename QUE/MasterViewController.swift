//
//  MasterViewController.swift
//  QUE
//
//  Created by Krish Kharbanda on 5/22/21.
//  Copyright © 2021 KK Can Code. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseFirestore

class MasterViewController: UITableViewController {
    
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    var detailViewController: DetailViewController?
    static var objects: [Document] = [
        Document(title: "Fox & Dog", body: "The quick brown fox jumps over the lazy dog.")
    ]
    
    let db = Firestore.firestore()
    static var docId = String()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        navigationItem.leftBarButtonItem = editButtonItem
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: nil)
        addButton.customView?.overrideUserInterfaceStyle = .dark
        navigationItem.rightBarButtonItem = addButton
        
        if let split = splitViewController {
            detailViewController = split.viewControllers.last as? DetailViewController
        }
        NotificationCenter.default.addObserver(self, selector: #selector(fetchDoc), name: NSNotification.Name("fetchDocs"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("fetchDocs"), object: nil)
        
        var menuChildren = [UIAction]()
        
        for item in ["Default", "Web"] {
            menuChildren.append(UIAction(title: item, handler: { action in
                if action.title == "Default" {
                    self.createDoc()
                } else {
                    self.navigationController?.pushViewController(self.storyboard?.instantiateViewController(withIdentifier: "WKVC") as! WebDocViewController, animated: true)
                }
            }))
        }
        
        let menu = UIMenu(title: "Create Document", image: UIImage(systemName: ""), options: .displayInline, children: menuChildren)
        addButton.menu = menu
        // Do any additional setup after loading the view.
    }
    
    func objectContains(_ document: Document) -> Bool {
        for doc in MasterViewController.objects {
            if doc.title == document.title {
                return true
            }
        }
        return false
    }
    
    @objc func fetchDoc(notification: Notification) {
        if let documentID = UserDefaults.standard.string(forKey: "docId")?.reverseString(), !documentID.isEmpty {
            MasterViewController.docId = documentID
            self.db.collection("Users").document(documentID).getDocument { documentSnapshot, err in
                if let error = err {
                    print(error.localizedDescription)
                    return
                }
                if let document = documentSnapshot {
                    if document == document {
                        if let documentIds = document.get("documents") as? NSArray, let documents = documentIds as? Array<String>, !documents.isEmpty {
                            for documentId in documents {
                                self.db.collection("Documents").document(documentId).getDocument { docSnapshot, err in
                                    if let error = err {
                                        print(error.localizedDescription)
                                        return
                                    }
                                    if let doc = docSnapshot {
                                        if doc == doc {
                                            let newDoc = Document(title: String(describing: doc.get("title")!), body: String(describing: doc.get("body")!))
                                            if !self.objectContains(newDoc) {
                                                MasterViewController.objects.append(newDoc)
                                                self.tableView.reloadData()
                                                let docIds = documents
                                                self.saveToFirebase(with: docIds)
                                            }
                                        }
                                    }
                                }
                            }
                            self.tableView.reloadData()
                        } else {
                            self.saveToFirebase(with: [])
                        }
                    }
                }
            }
        } else {
            MasterViewController.docId = String((0..<20).map{ _ in self.letters.randomElement()! })
            let key = MasterViewController.docId.reverseString()
            self.db.collection("Users").document(MasterViewController.docId).setData(["documents": [], "firstSearch": false])
            UserDefaults.standard.set(key, forKey: "docId")
        }
    }
    
    func saveToFirebase(with docIds: [String]) {
        for doc in MasterViewController.objects {
            var done = false
            self.db.collection("Documents").whereField("title", isEqualTo: doc.title).getDocuments { querySnapshot, err in
                if let error = err {
                    print(error.localizedDescription)
                    return
                }
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    for document in documents {
                        if document == document {
                            if docIds.contains(document.documentID) {
                                self.db.collection("Documents").document(document.documentID).setData(["body": doc.body], merge: true)
                                done = true
                                break
                            }
                        }
                    }
                } else if doc.title != "Fox & Dog" && done == false {
                    let docId = String((0..<20).map{ _ in self.letters.randomElement()! })
                    self.db.collection("Documents").document(docId).setData(["title": doc.title, "body": doc.body])
                    var documents = docIds
                    documents.append(docId)
                    self.db.collection("Users").document(MasterViewController.docId).setData(["documents": documents], merge: true) { err in
                        if let error = err {
                            print(error.localizedDescription)
                            return
                        }
                        print("Success!")
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    func createDoc() {
        let alertController = UIAlertController(title: "New Document Title", message: "Please set a title for the document.", preferredStyle: .alert)
        var titleFld: UITextField?
        alertController.view.overrideUserInterfaceStyle = .dark
        alertController.view.tintColor = .systemGreen
        alertController.addTextField { titleField in
            titleFld = titleField
            titleFld?.placeholder = "Title"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Set", style: .default, handler: { action in
            if let text = titleFld?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                MasterViewController.objects.insert(Document(title: text), at: 0)
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Segues
    
    static var selectedIndex = Int()
    
    @IBSegueAction func makeDetailViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> UINavigationController? {
        guard let navigationController = UINavigationController(coder: coder) else {
            print("Unable to create UINavigationController")
            return nil
        }
        
        guard let indexPath = tableView.indexPathForSelectedRow else {
            print("Unable to determine the selected row")
            return nil
        }
        
        guard let detailController = navigationController.topViewController as? DetailViewController else {
            print("The UINavigationController's topViewController is not a DetailViewController")
            return nil
        }
        navigationController.overrideUserInterfaceStyle = .dark
        detailController.detailItem = MasterViewController.objects[indexPath.row]
        MasterViewController.selectedIndex = indexPath.row
        detailController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        detailController.navigationItem.leftItemsSupplementBackButton = true
        
        return navigationController
    }
    
    // MARK: - Table View
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MasterViewController.objects.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let object = MasterViewController.objects[indexPath.row]
        cell.textLabel!.text = object.title
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            MasterViewController.objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
extension String {
    public func reverseString() -> String {
        var i = 0
        var key = String()
        while i < self.reversed().count {
            key += String(self.reversed()[i])
            i += 1
        }
        return key
    }
}
extension Array {
    public func contains(_ element: String) -> Bool {
        for item in self {
            if let stringItem = item as? String, !stringItem.isEmpty {
                if stringItem == element {
                    return true
                }
            }
        }
        return false
    }
}
