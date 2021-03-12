//
//  WelcomeVC.swift
//  IQConnect
//
//  Created by SuperDev on 06.01.2021.
//

import UIKit

class WelcomeVC: UIViewController {
    
    override open var shouldAutorotate: Bool {
       return false
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.getSettings()
        }
    }
    
    private func getSettings() {
        Service_API.getSettings() { (settings, error) in
            guard let settings = settings, error == nil else {
                if let error = error {
                    print(error.localizedDescription)
                }
                return
            }
            
            SharedManager.sharedInstance.setPandC(settings.privacy_policy ?? "")
            SharedManager.sharedInstance.setContactEmail(settings.email_contact ?? "")
            
            if SharedManager.sharedInstance.isUserLoggedIn() {
                self.login()
            } else {
                AppDelegate.shared.showSignInScreen()                
            }
        }
    }
    
    private func login() {
        let userID = SharedManager.sharedInstance.getUserID()
        let password = SharedManager.sharedInstance.getUserPass()
        let deviceToken = SharedManager.sharedInstance.getDeviceToken()
        
        Service_API.login(userID: userID, password: password, deviceToken: deviceToken) { (loginResponse, error) in
            
            guard let loginResponse = loginResponse else {
                if let error = error {
                    UIHelper.showError(message: error.localizedDescription)
                }
                
                return
            }
            
            if loginResponse.status == "0" || loginResponse.status == "2" {
                SharedManager.sharedInstance.setIsUserLoggedIn(true)
                SharedManager.sharedInstance.setChannelName(loginResponse.channel_name ?? "")
                SharedManager.sharedInstance.setChannelID(loginResponse.channel_id ?? "")
                SharedManager.sharedInstance.setUserID(loginResponse.user_id ?? "")
                SharedManager.sharedInstance.setUserName(loginResponse.name ?? "")
                SharedManager.sharedInstance.setUserLastName(loginResponse.last_name ?? "")
                SharedManager.sharedInstance.setUserEmail(loginResponse.mail ?? "")
                SharedManager.sharedInstance.setUserPhone(loginResponse.phone ?? "")
                SharedManager.sharedInstance.setUserImagePath(loginResponse.photo_url ?? "")
                SharedManager.sharedInstance.setAdbCheck(loginResponse.abr_type ?? "")
                SharedManager.sharedInstance.setSpeedTestServerID(loginResponse.speed_test_id)
                
                // show main page
                AppDelegate.shared.showMainScreen()
                
            } else if loginResponse.status == "3" {
                self.showAlert(title: "IQ Connect Pro", message: loginResponse.message)
            } else {
                AppDelegate.shared.showSignInScreen()
            }
        }
    }
}
