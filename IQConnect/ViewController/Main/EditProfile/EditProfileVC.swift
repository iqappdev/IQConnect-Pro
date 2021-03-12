//
//  EditProfileVC.swift
//  IQConnect
//
//  Created by SuperDev on 13.01.2021.
//

import UIKit
import NVActivityIndicatorView

class EditProfileVC: UIViewController, NVActivityIndicatorViewable {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayProfileInfo()
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
        
        guard let lastName = lastNameTextField.text?.trimmed, !lastName.isEmpty else {
            UIHelper.showError(message: "Enter the last name")
            return
        }
        
        guard let email = emailTextField.text?.trimmed, !email.isEmpty else {
            UIHelper.showError(message: "Enter the email")
            return
        }
        
        guard let phone = phoneNumberTextField.text?.trimmed, !phone.isEmpty else {
            UIHelper.showError(message: "Enter the phone")
            return
        }
        
        self.view.endEditing(true)
        
        let userID = SharedManager.sharedInstance.getUserID()
        
        self.startAnimating(type: .lineScalePulseOut)
        Service_API.updateProfile(
            userID: userID,
            name: name,
            lastName: lastName,
            phone: phone,
            email: email) { (response, error) in
            
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
            
            SharedManager.sharedInstance.setUserName(name)
            SharedManager.sharedInstance.setUserLastName(lastName)
            SharedManager.sharedInstance.setUserPhone(phone)
            SharedManager.sharedInstance.setUserEmail(email)
            
            UIHelper.showMessage(nil, body: "Profile has been updated successfully!", theme: .success)
        }
    }
    
    func displayProfileInfo() {
        nameTextField.text = SharedManager.sharedInstance.getUserName()
        lastNameTextField.text = SharedManager.sharedInstance.getUserLastName()
        emailTextField.text = SharedManager.sharedInstance.getUserEmail()
        phoneNumberTextField.text = SharedManager.sharedInstance.getUserPhone()
    }
}
