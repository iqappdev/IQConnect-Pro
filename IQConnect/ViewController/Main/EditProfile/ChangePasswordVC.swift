//
//  ChangePasswordVC.swift
//  IQConnect
//
//  Created by SuperDev on 13.01.2021.
//

import UIKit
import NVActivityIndicatorView

class ChangePasswordVC: UIViewController, NVActivityIndicatorViewable {
    
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onMenuButtonClick(_ sender: UIButton) {
        self.view.endEditing(true)
        sideMenuController?.revealMenu()
    }
    
    @IBAction func onUpdateButtonClick(_ sender: UIButton) {
        guard let currentPassword = currentPasswordTextField.text?.trimmed, !currentPassword.isEmpty else {
            UIHelper.showError(message: "Enter the current password.")
            return
        }
        
        guard let newPassword = newPasswordTextField.text?.trimmed, !newPassword.isEmpty else {
            UIHelper.showError(message: "Enter the new password.")
            return
        }
        
        guard let confirmPassword = confirmPasswordTextField.text?.trimmed, !confirmPassword.isEmpty else {
            UIHelper.showError(message: "Enter the confirm password.")
            return
        }
        
        if newPassword != confirmPassword {
            UIHelper.showError(message: "New passwords do not match.")
            return
        }
        
        self.view.endEditing(true)
        
        let userID = SharedManager.sharedInstance.getUserID()
        
        self.startAnimating(type: .lineScalePulseOut)
        Service_API.changePassword(
            userID: userID,
            oldPassword: currentPassword,
            newPassword: newPassword) { (response, error) in
            
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
            
            SharedManager.sharedInstance.setUserPass(newPassword)
            
            self.currentPasswordTextField.text = ""
            self.newPasswordTextField.text = ""
            self.confirmPasswordTextField.text = ""
            
            UIHelper.showMessage(nil, body: "Password has been changed successfully!", theme: .success)
        }
    }
}
