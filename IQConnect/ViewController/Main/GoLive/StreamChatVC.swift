//
//  StreamChatVC.swift
//  IQConnect
//
//  Created by SuperDev on 20.01.2021.
//

import UIKit
import Toaster

protocol StreamChatVCDelegate: class {
    func onDismiss()
}

class StreamChatVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputMessageTextField: UITextField!
    
    weak var delegate: StreamChatVCDelegate?
    var presetMessages = [Message]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPresetMessages()
    }
    
    @IBAction func onCloseButtonClick(_ sender: UIButton) {
        self.delegate?.onDismiss()
    }
    
    @IBAction func onSendButtonClick(_ sender: UIButton) {
        self.view.endEditing(true)
        
        guard let message = inputMessageTextField.text?.trimmed, !message.isEmpty else {
            return
        }
        
        sendMessage(message)
    }
    
    func loadPresetMessages() {
        Service_API.getPresetMessages { (messagesResponse, error) in
            guard let messagesResponse = messagesResponse else { return }
            
            self.presetMessages = messagesResponse.preset_msg
            self.tableView.reloadData()
        }
    }
    
    func sendMessage(_ message: String) {
        Service_API.addStreamMessage(message: message) { (response, error) in
            if let response = response, !response.error {
                Toast(text: "Message Sent!", duration: Delay.short).show()
                self.inputMessageTextField.text = ""
                self.delegate?.onDismiss()
            }
        }
    }
}

extension StreamChatVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension StreamChatVC: UITableViewDelegate, UITableViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.presetMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell") as? MessageCell {
            let message = presetMessages[indexPath.row]
            cell.message = message
            cell.delegate = self
            return cell
        }
        
        return UITableViewCell()
    }
}

extension StreamChatVC: MessageCellDelegate {
    func onEditAction(_ message: Message) {
        
    }
    
    func onDeleteAction(_ message: Message) {
        
    }
    
    func onMessageClickAction(_ message: Message) {
        if let msg = message.msg {
            sendMessage(msg)
        }
    }
}
