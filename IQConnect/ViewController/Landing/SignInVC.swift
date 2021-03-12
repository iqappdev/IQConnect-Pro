//
//  SignInVC.swift
//  IQConnect
//
//  Created by SuperDev on 06.01.2021.
//

import UIKit
import AVFoundation
import NVActivityIndicatorView
import Firebase

class SignInVC: UIViewController, NVActivityIndicatorViewable {
    
    override open var shouldAutorotate: Bool {
       return false
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return .portrait
    }
    
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var termsTextView: UITextView!
    @IBOutlet weak var supportEmailTextView: UITextView!
    @IBOutlet weak var websiteTextView: UITextView!
    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var showOrHidePasswordButton: UIButton!
    
    var videoPlayer: AVPlayer!
    var playerLayer: AVPlayerLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        AppDelegate.shared.signInVC = self
        
        Installations.installations().installationID { (deviceToken, error) in
            if error == nil, let deviceToken = deviceToken {
                SharedManager.sharedInstance.setDeviceToken(deviceToken)
            }
        }
    }
    
    deinit {
        AppDelegate.shared.signInVC = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.playVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopVideo()
    }
    
    @IBAction func onInfoButtonClick(_ sender: UIButton) {
        let title = "IQ Connect Pro"
        let message = """
        If you have already registered, use your IQ Connect Pro user ID to log in.
        
        If starting a new registration process, Please Contact your Administrator to create new User Id for you.
        """
        self.showAlert(title: title, message: message)
    }
    
    @IBAction func onShowOrHidePasswordButtonClick(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        if passwordTextField.isSecureTextEntry {
            showOrHidePasswordButton.setBackgroundImage(UIImage(named: "ic_eye"), for: .normal)
        } else {
            showOrHidePasswordButton.setBackgroundImage(UIImage(named: "ic_eye_off"), for: .normal)
        }
    }
    
    @IBAction func onSignInButtonClick(_ sender: UIButton) {
        guard let userID = userIDTextField.text?.trimmed else { return }
        guard let password = passwordTextField.text else { return }
        let deviceToken = SharedManager.sharedInstance.getDeviceToken()
        
        if userID.isEmpty {
            UIHelper.showError(message: "Enter the User ID")
            return
        }
        if password.isEmpty {
            UIHelper.showError(message: "Enter the Password")
            return
        }
        if deviceToken.isEmpty {
            return
        }
        
        SharedManager.sharedInstance.setUserPass(password)
        
        self.startAnimating(type: .lineScalePulseOut)
        Service_API.login(userID: userID, password: password, deviceToken: deviceToken) { (loginResponse, error) in
            
            self.stopAnimating()
            
            guard let loginResponse = loginResponse else {
                if let error = error {
                    UIHelper.showError(message: error.localizedDescription)
                }
                
                return
            }
            
            if loginResponse.status == "0" || loginResponse.status == "2" {
                if loginResponse.user_id?.isEmpty ?? true {
                    UIHelper.showError(message: "Please enter a name")
                    return
                }
                
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
                
            } else if loginResponse.status == "3" || loginResponse.status == "1" {
                self.showAlert(title: "IQ Connect Pro", message: loginResponse.message)
            }
        }
    }
    
    func setupUI() {
        supportEmailTextView.textContainerInset = .zero
        supportEmailTextView.textContainer.lineFragmentPadding = 0
        
        websiteTextView.textContainerInset = .zero
        websiteTextView.textContainer.lineFragmentPadding = 0
        
        termsTextView.textContainerInset = .zero
        termsTextView.textContainer.lineFragmentPadding = 0
        
        //Terms And conditions
        let pandC = SharedManager.sharedInstance.getPandC()
        let attributedString = NSMutableAttributedString(string: "By signing in, I agree to the EULA")
        let linkRange = (attributedString.string as NSString).range(of: "EULA")
        attributedString.addAttribute(.link, value: pandC, range: linkRange)
        let linkAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): UIColor.appBlueColor]
        
        //TextView Attributes
        termsTextView.linkTextAttributes = linkAttributes
        termsTextView.attributedText = attributedString
        termsTextView.textColor = .white
        termsTextView.textAlignment = .center
        termsTextView.font = UIFont.systemFont(ofSize: UIDevice.current.userInterfaceIdiom == .pad ? 21 : 14)
    }
}

extension SignInVC {
    func playVideo() {
        guard let url = Bundle.main.url(forResource: "login_bg_video", withExtension: "mp4") else {
            return
        }

        if self.videoPlayer == nil {
            let videoSize = UIScreen.main.bounds.size
            let movieAsset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: movieAsset)
            self.videoPlayer = AVPlayer(playerItem: playerItem)
            self.playerLayer = AVPlayerLayer(player: self.videoPlayer)
            self.playerLayer.frame = CGRect(origin: .zero, size: videoSize)
            self.videoContainerView.layer.addSublayer(self.playerLayer)
            self.playerLayer.backgroundColor = UIColor.clear.cgColor
            self.playerLayer.videoGravity = .resizeAspectFill
            self.videoPlayer.isMuted = true
        }
        
        self.videoPlayer.play()
        NotificationCenter.default.addObserver(self, selector: #selector(SignInVC.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer.currentItem)
    }
    
    func stopVideo() {
        if self.videoPlayer != nil {
            self.videoPlayer.pause()
            self.videoPlayer.seek(to: CMTime.zero)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func playerItemDidReachEnd() {
        self.videoPlayer.seek(to: CMTime.zero)
        self.videoPlayer.play()
    }
}

