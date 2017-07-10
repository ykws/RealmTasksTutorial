//
//  ViewController.swift
//  RealmTasksTutorial
//
//  Created by Yoshiyuki Kawashima on 2017/07/10.
//  Copyright © 2017 ykws. All rights reserved.
//

import UIKit
import RealmSwift
import Keys

// MARK: Model

final class TaskList: Object {
  dynamic var text = ""
  dynamic var id = ""
  let items = List<Task>()
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

final class Task: Object {
  dynamic var text = ""
  dynamic var completed = false
}

class ViewController: UITableViewController {
  var items = List<Task>()
  var notificationToken: NotificationToken!
  var realm: Realm!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupRealm()
  }
  
  func setupUI() {
    title = "My Tasks"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
    navigationItem.leftBarButtonItem = editButtonItem
  }
  
  func setupRealm() {
    let keys = RealmTasksTutorialKeys()
    let username = keys.realmUsername
    let password = keys.realmPassword
    
    SyncUser.logIn(with: .usernamePassword(username: username, password: password, register: false), server: URL(string: "http://127.0.0.1:9080")!) { user, error in
      guard let user = user else {
        fatalError(String(describing: error))
      }
      
      DispatchQueue.main.async {
        let configuration = Realm.Configuration(
          syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://127.0.0.1:9080/~/realmtasks")!)
        )
        self.realm = try! Realm(configuration: configuration)
        
        func updateList() {
          if self.items.realm == nil, let list = self.realm.objects(TaskList.self).first {
            self.items = list.items
          }
          self.tableView.reloadData()
        }
        updateList()
        
        self.notificationToken = self.realm.addNotificationBlock { _ in
          updateList()
        }
      }
    }
  }
  
  deinit {
    notificationToken.stop()
  }
  
  // MARK: UITableView
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = items[indexPath.row]
    cell.textLabel?.text = item.text
    cell.textLabel?.alpha = item.completed ? 0.5 : 1
    return cell
  }
  
  override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    try! items.realm?.write {
      items.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      try! realm.write {
        let item = items[indexPath.row]
        realm.delete(item)
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = items[indexPath.row]
    try! item.realm?.write {
      item.completed = !item.completed
      let destinationIndexPath: IndexPath
      if item.completed {
        destinationIndexPath = IndexPath(row: items.count - 1, section: 0)
      } else {
        let completedCount = items.filter("completed = true").count
        destinationIndexPath = IndexPath(row: items.count - completedCount - 1, section: 0)
      }
      items.move(from: indexPath.row, to: destinationIndexPath.row)
    }
  }
  
  // MARK: Functions
  
  func add() {
    let alertController = UIAlertController(title: "New Task", message: "Enter Task Name", preferredStyle: .alert)
    var alertTextField: UITextField!
    alertController.addTextField { textField in
      alertTextField = textField
      textField.placeholder = "Task Name"
    }
    alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
      guard let text = alertTextField.text, !text.isEmpty else { return }
      
      //self.items.append(Task(value: ["text": text]))
      //self.tableView.reloadData()
      let items = self.items
      try! items.realm?.write {
        items.insert(Task(value: ["text": text]), at: items.filter("completed = false").count)
      }
    })
    present(alertController, animated: true, completion: nil)
  }
}

