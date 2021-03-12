//
//  MenuVC.swift
//  IQConnect
//
//  Created by SuperDev on 08.01.2021.
//

import UIKit
import SideMenuSwift
import SDWebImage

class MenuVC: UIViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sideMenuController?.cache(viewControllerGenerator: {
            self.storyboard?.instantiateViewController(withIdentifier: "MessagesVC")
        }, with: "messages")
        sideMenuController?.cache(viewControllerGenerator: {
            self.storyboard?.instantiateViewController(withIdentifier: "EditProfileVC")
        }, with: "profile")
        sideMenuController?.cache(viewControllerGenerator: {
            self.storyboard?.instantiateViewController(withIdentifier: "ChangePasswordVC")
        }, with: "password")
        sideMenuController?.cache(viewControllerGenerator: {
            self.storyboard?.instantiateViewController(withIdentifier: "ContactUsVC")
        }, with: "contactUs")
        sideMenuController?.cache(viewControllerGenerator: {
            self.storyboard?.instantiateViewController(withIdentifier: "AboutUsVC")
        }, with: "aboutUs")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        avatarImageView.sd_setImage(with: URL(string: SharedManager.sharedInstance.getUserImagePath()), placeholderImage: UIImage(named: "ic_avatar"), completed: nil)
        userNameLabel.text = "\(SharedManager.sharedInstance.getUserName()) \(SharedManager.sharedInstance.getUserLastName())"
        userEmailLabel.text = SharedManager.sharedInstance.getUserEmail()
    }
    
    @IBAction func onHomeButtonClick(_ sender: UIButton) {
        sideMenuController?.setContentViewController(with: "home", animated: false)
        sideMenuController?.hideMenu()
    }
    
    @IBAction func onProfileButtonClick(_ sender: UIButton) {
        sideMenuController?.setContentViewController(with: "profile", animated: false)
        sideMenuController?.hideMenu()
    }
    
    @IBAction func onChangePasswordButtonClick(_ sender: UIButton) {
        sideMenuController?.setContentViewController(with: "password", animated: false)
        sideMenuController?.hideMenu()
    }
    
    @IBAction func onMessagesButtonClick(_ sender: UIButton) {
        sideMenuController?.setContentViewController(with: "messages", animated: false)
        sideMenuController?.hideMenu()
    }
    
    @IBAction func onContactUsButtonClick(_ sender: UIButton) {
        sideMenuController?.setContentViewController(with: "contactUs", animated: false)
        sideMenuController?.hideMenu()
    }
    
    @IBAction func onAboutUsButtonClick(_ sender: UIButton) {
        sideMenuController?.setContentViewController(with: "aboutUs", animated: false)
        sideMenuController?.hideMenu()
    }

    @IBAction func onLogoutButtonClick(_ sender: UIButton) {
        let alert = UIAlertController(title: "IQ Connect Pro", message: "Do you really wish to logout?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { (_) in
            SharedManager.sharedInstance.setIsUserLoggedIn(false)
            AppDelegate.shared.showSignInScreen()
        }))
        present(alert, animated: true, completion: nil)
    }
}
