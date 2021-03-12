//
//  ContactUsVC.swift
//  IQConnect
//
//  Created by SuperDev on 13.01.2021.
//

import UIKit
import NVActivityIndicatorView

class ContactUsVC: UIViewController, NVActivityIndicatorViewable {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onMenuButtonClick(_ sender: UIButton) {
        self.view.endEditing(true)
        sideMenuController?.revealMenu()
    }
    
    @IBAction func onUpdateButtonClick(_ sender: UIButton) {
        guard let name = nameTextField.text?.trimmed, !name.isEmpty else {
            UIHelper.showError(message: "Enter the name")
            return
        }
        
        guard let subject = subjectTextField.text?.trimmed, !subject.isEmpty else {
            UIHelper.showError(message: "Enter the subject")
            return
        }
        
        guard let message = messageTextView.text?.trimmed, !message.isEmpty else {
            UIHelper.showError(message: "Enter the message")
            return
        }
        
        self.view.endEditing(true)
        
        let email = SharedManager.sharedInstance.getUserEmail()
        
        self.startAnimating(type: .lineScalePulseOut)
        Service_API.contactUs(
            name: name,
            subject: subject,
            message: message) { (response, error) in
            
            self.stopAnimating()
            
            guard let response = response else {
                if let error = error {
                    UIHelper.showError(message: error.localizedDescription)
                }
                
                return
            }
            
            if response.error {
                if let message = response.message {
                    UIHelper.showError(message: message)
                }
                
                return
            }
            
            self.nameTextField.text = ""
            self.subjectTextField.text = ""
            self.messageTextView.text = ""
            
            UIHelper.showMessage(nil, body: "Submitted successfully!", theme: .success)
        }
    }
}

