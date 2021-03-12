//
//  MessagesVC.swift
//  IQConnect
//
//  Created by SuperDev on 12.01.2021.
//

import UIKit

class MessagesVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputMessageTextView: UITextView!
    @IBOutlet weak var inputMessageTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomBarBottomConstraint: NSLayoutConstraint!
    
    var messages = [Message]()
    var editingMessage: Message?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        loadMessages()
        
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func onMenuButtonClick(_ sender: UIButton) {
        self.view.endEditing(true)
        sideMenuController?.revealMenu()
    }
    
    @IBAction func onSendButtonClick(_ sender: UIButton) {
        let message = inputMessageTextView.text.trimmed
        
        self.view.endEditing(true)
        
        if message.isEmpty {
            return
        }
        
        self.inputMessageTextView.text = ""
        
        if let editingMessage = editingMessage {
            Service_API.editMessage(messageId: editingMessage.id, message: message) { (normalResponse, error) in
                self.editingMessage?.msg = message
                if let messageIndex = self.getMessageIndex(editingMessage.id) {
                    self.tableView.reloadRows(at: [IndexPath(row: messageIndex, section: 0)], with: .automatic)
                }
            }
        } else {
            Service_API.addMessage(message: message) { (normalResponse, error) in
                self.loadMessages()
            }
        }
    }

    private func setupUI() {
        inputMessageTextView.textContainerInset = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
    
    @objc func kbWillShow(_ notification:Notification) {
        let userInfo = notification.userInfo
        let kbFrameSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let kbSizeHeight = kbFrameSize.height
        bottomBarBottomConstraint.constant = kbSizeHeight
        if #available(iOS 11.0, *) {
            let window = UIWindow.key
            let bottomPadding = window?.safeAreaInsets.bottom
            bottomBarBottomConstraint.constant = kbSizeHeight - (bottomPadding ?? 0)
        }
        
        //chatTableViewTopConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func kbWillHide() {
        bottomBarBottomConstraint.constant = 0
    }
    
    func getMessageIndex(_ msgID: Int) -> Int? {
        for i in 0..<messages.count {
            if messages[i].id == msgID {
                return i
            }
        }
        
        return nil
    }
    
    func loadMessages() {
        Service_API.getMessages { (messagesResponse, error) in
            guard let messagesResponse = messagesResponse else { return }
            
            self.messages = messagesResponse.preset_msg
            self.tableView.reloadData()
        }
    }
}

extension MessagesVC: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        var sizeThatFits = textView.layoutManager.usedRect(for: textView.textContainer).size
        sizeThatFits.height += textView.textContainerInset.top + textView.textContainerInset.bottom
        
        var newHeight = sizeThatFits.height
        newHeight = min(newHeight, 150)
        newHeight = max(newHeight, 50)
        self.inputMessageTextViewHeightConstraint.constant = newHeight
        
    }
}

extension MessagesVC: UITableViewDelegate, UITableViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell") as? MessageCell {
            let message = messages[indexPath.row]
            cell.message = message
            cell.delegate = self
            return cell
        }
        
        return UITableViewCell()
    }
}

extension MessagesVC: MessageCellDelegate {
    func onEditAction(_ message: Message) {
        self.editingMessage = message
        self.inputMessageTextView.text = message.msg
        self.inputMessageTextView.becomeFirstResponder()
    }
    
    func onDeleteAction(_ message: Message) {
        self.editingMessage = nil
        self.inputMessageTextView.text = ""
        
        Service_API.deleteMessage(messageId: message.id) { (normalResponse, error) in
            if let messageIndex = self.getMessageIndex(message.id) {
                self.messages.remove(at: messageIndex)
                self.tableView.deleteRows(at: [IndexPath(row: messageIndex, section: 0)], with: .automatic)
            }
        }
    }
    
    func onMessageClickAction(_ message: Message) {
        
    }
}
