//
//  LiveBroadcastVC+Custom.swift
//  IQConnect
//
//  Created by SuperDev on 11.01.2021.
//

import UIKit
import Toaster
import NVActivityIndicatorView
import STFTPNetwork

extension LiveBroadcastVC: NVActivityIndicatorViewable {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMessages" {
            if let vc = segue.destination as? StreamChatVC {
                vc.delegate = self
            }
        }
    }
    
    @IBAction func Back_Click(_ sender: UIButton) {
        if doubleBackToExitPressedOnce {
            self.stopStream()
            self.navigationController?.popViewController()
        } else {
            doubleBackToExitPressedOnce = true
            Toast(text: "Please click \"BACK\" again to quit", duration: Delay.short).show()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.doubleBackToExitPressedOnce = false
            }
        }
    }
    
    @IBAction func Reply_Accept_Click(sender: UIButton) {
        Reply_View.isHidden = true
        sendMessage("Yes")
        deleteMessage()
    }
    
    @IBAction func Reply_Decline_Click(sender: UIButton) {
        Reply_View.isHidden = true
        sendMessage("No")
        deleteMessage()
    }
    
    @IBAction func Chat_Click(_ sender: UIButton) {
        Chat_View.isHidden = false
    }
    
    @IBAction func Shoot_Option_Click(_ sender: UIButton) {
        self.Shoot_Buttons_View.isHidden = true
        
        if sender.tag == 1 {
            isShootAndSend = true
            self.Shoot_Button.setImage(#imageLiteral(resourceName: "shoot_and_send"), for: .normal)
            Toast(text: "Save and send", duration: Delay.short).show()
        } else if sender.tag == 2 {
            isShootAndSend = false
            self.Shoot_Button.setImage(#imageLiteral(resourceName: "shoot"), for: .normal)
            Toast(text: "Save", duration: Delay.short).show()
        }
    }
    
    @objc func Shoot_Tap(sender: UITapGestureRecognizer) {
        if !self.Shoot_Buttons_View.isHidden {
            self.Shoot_Buttons_View.isHidden = true
        } else {
            self.Shoot_Click(Shoot_Button)
        }
    }

    @objc func Shoot_LongPress(sender: UILongPressGestureRecognizer) {
        self.Shoot_Buttons_View.isHidden = false
    }
    
    func startBatteryMonitor() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        
        // display battery level
        var batteryLevel = Int(UIDevice.current.batteryLevel * 100.0)
        if batteryLevel < 0 {
            batteryLevel = 0
        }
        Battery_View.level = batteryLevel
    }
    
    func stopBatteryMonitor() {
        UIDevice.current.isBatteryMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }
    
    func showBroadcastingView() {
        self.Broadcasting_View_Width_Constraint.constant = 90
        
        UIView.animate(withDuration: 0.6, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.Broadcasting_Dot_View.alpha = 0
        }, completion: nil)
    }
    
    func hideBroadcastingView() {
        self.Broadcasting_View_Width_Constraint.constant = 0
        
        self.Broadcasting_Dot_View.layer.removeAllAnimations()
        self.Broadcasting_Dot_View.alpha = 1
        self.view.layer.removeAllAnimations()
        self.view.layoutIfNeeded()
    }
    
    func showRecordingView() {
        self.Recording_View.isHidden = false
        
        UIView.animate(withDuration: 0.6, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.Recording_Dot_View.alpha = 0
        }, completion: nil)
    }
    
    func hideRecordingView() {
        self.Recording_View.isHidden = true
        
        self.Recording_Dot_View.layer.removeAllAnimations()
        self.Recording_Dot_View.alpha = 1
        self.view.layer.removeAllAnimations()
        self.view.layoutIfNeeded()
    }
    
    @objc func batteryLevelDidChange(_ notification: Notification) {
        var batteryLevel = Int(UIDevice.current.batteryLevel * 100.0)
        if batteryLevel < 0 {
            batteryLevel = 0
        }
        Battery_View.level = batteryLevel
    }
    
    func configureModeButton() {
        configureCircularMenuButton(button: Mode_Button, numberOfMenuItems: 3, menuRedius: 60, postion: .topLeft)
        Mode_Button.menuButtonSize = .medium
        
        loadModeButton()
    }
    
    func configureResolutionButton() {
        var options = [UIImage]()
        for videoResolution in videoResolutions {
            options.append(UIImage(named: "video_resolution_\(videoResolution.height)")!)
        }
        
        Resolution_Button.options = options
        Resolution_Button.buttonCornerRadius = 20
        Resolution_Button.imageInsets    = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        Resolution_Button.selectionColor = UIColor(red: 44.0/256.0, green: 62.0/256.0, blue: 80.0/256.0, alpha: 1.0)
        Resolution_Button.buttonBackgroundColor = .appBlueColor
        Resolution_Button.expandedButtonBackgroundColor = Resolution_Button.buttonBackgroundColor
                
        Resolution_Button.optionSelectionBlock = {
            index in
            print("[Left] Did select cat at index: \(index)")
            SharedManager.sharedInstance.setVideoResolutionIndex(index)
            self.currentVideoResolution = self.videoResolutions[index]
            self.displayResolutionLabel()
            
            if self.isBroadcasting {
                self.restartBroadcasting = true
                self.applicationWillResignActive()
                self.applicationDidBecomeActive()
            } else {
                self.applicationWillResignActive()
                self.applicationDidBecomeActive()
            }
        }
        
        loadResolutionButton()
    }
    
    func configureShootButton() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(Shoot_Tap))
        Shoot_Button.addGestureRecognizer(tapGestureRecognizer)
            
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(Shoot_LongPress))
        Shoot_Button.addGestureRecognizer(longPressRecognizer)
    }
    
    func loadModeButton() {
        if LarixSettings.sharedInstance.canBroadcast, LarixSettings.sharedInstance.record {
            Mode_Button.backgroundColor = .appGreenColor
            Mode_Button.setTitle("L&S", for: .normal)
        } else if LarixSettings.sharedInstance.canBroadcast {
            Mode_Button.backgroundColor = .appRedColor
            Mode_Button.setTitle("Live", for: .normal)
        } else if LarixSettings.sharedInstance.record {
            Mode_Button.backgroundColor = .appBlueColor
            Mode_Button.setTitle("Save", for: .normal)
        }
    }
    
    func getVideoResolutions() {
        configureResolutionButton()
        
        let channelID = SharedManager.sharedInstance.getChannelID()
        Service_API.getVideoResolutions(channelID: channelID) { (videoResolutionsList, error) in
            guard let videoResolutionsList = videoResolutionsList, error == nil else {
                return
            }
            
            self.videoResolutions = videoResolutionsList.videos
            
            let videoResolutionIndex = SharedManager.sharedInstance.getVideoResolutionIndex()
            self.currentVideoResolution = self.videoResolutions[videoResolutionIndex]
            self.configureResolutionButton()
            self.displayResolutionLabel()
        }
    }
    
    func loadResolutionButton() {
        let videoResolutionIndex = SharedManager.sharedInstance.getVideoResolutionIndex()
        if videoResolutionIndex < Resolution_Button.options.count {
            Resolution_Button.currentValue = Resolution_Button.options[videoResolutionIndex]
        }
    }
    
    func displayResolutionLabel() {
        guard let currentVideoResolution = self.currentVideoResolution else {
            Resolution_Label.text = ""
            return
        }
        
        let codecStr = (LarixSettings.sharedInstance.videoConfig.type == kCMVideoCodecType_HEVC) ? "HEVC" : "H.264"
        
        Resolution_Label.text = "\(currentVideoResolution.width)x\(currentVideoResolution.height) - \(SharedManager.sharedInstance.getAdbCheck()) - \(codecStr)"
    }
    
    func startStream() {
        guard let currentVideoResolution = self.currentVideoResolution else { return }
        
        Settings_Button.isHidden = true
        
        if !LarixSettings.sharedInstance.canBroadcast {
            self.currentConnection = nil
            self.startBroadcast()
            return
        }
        
        self.startAnimating(type: .lineScalePulseOut)
        Service_API.startStream(videoResolution: "\(currentVideoResolution.width)x\(currentVideoResolution.height)") { (streamResponse, error) in
            
            self.stopAnimating()
            
            guard let streamResponse = streamResponse, error == nil else {
                if let error = error {
                    Toast(text: error.localizedDescription).show()
                }
                return
            }
            
            if streamResponse.status != "0" {
                Toast(text: streamResponse.message).show()
                return
            }
            
            print(streamResponse.stream_link!)
            let userName = SharedManager.sharedInstance.getUserName()
            self.currentConnection = Connection(name: userName, url: streamResponse.stream_link!, mode: .videoAudio, active: false)
            self.startBroadcast()
        }
    }

    func stopStream() {
        Settings_Button.isHidden = false
        
        Service_API.stopStream { (_) in
            
        }
        stopBroadcast()
    }
    
    func uploadPhoto(_ fileUrl: URL) {
        let uploadService = SharedManager.sharedInstance.getUploadService()
        if uploadService == "S3" {
            uploadToAWS(fileUrl)
        } else if uploadService == "FTP" {
            connectToFTP(fileUrl)
        }
    }
    
    func connectToFTP(_ fileUrl: URL) {
        let ftpIp = SharedManager.sharedInstance.getFtpIp()
        let ftpPort = SharedManager.sharedInstance.getFtpPort()
        let ftpUser = SharedManager.sharedInstance.getFtpUser()
        let ftpPwd = SharedManager.sharedInstance.getFtpPwd()
        
        STFTPNetwork.connect("ftp://\(ftpIp):\(ftpPort)", username: ftpUser, password: ftpPwd) { (success) in
            if !success {
                Toast(text: "Can't connect to ftp server.", duration: Delay.short).show()
                return
            }
            
            let channelID = SharedManager.sharedInstance.getChannelID()
            let userID = SharedManager.sharedInstance.getUserID()
            let remotePath = "ftp://\(ftpIp):\(ftpPort)/\(channelID)/\(userID)"
            STFTPNetwork.create(remotePath) {
                self.uploadToFTP(fileUrl)
            } failHandler: { (errorCode) in
                self.uploadToFTP(fileUrl)
            }
        }
    }
    
    func uploadToFTP(_ fileURL: URL) {
        let ftpIp = SharedManager.sharedInstance.getFtpIp()
        let ftpPort = SharedManager.sharedInstance.getFtpPort()
        let channelID = SharedManager.sharedInstance.getChannelID()
        let userID = SharedManager.sharedInstance.getUserID()
        let fileName = AWSS3Manager.shared.getUniqueFileName(fileUrl: fileURL)
        let remotePath = "ftp://\(ftpIp):\(ftpPort)/\(channelID)/\(userID)/\(fileName)"
        let localFilePath = fileURL.path
        STFTPNetwork.upload(localFilePath, urlString: remotePath) { (bytesCompleted, bytesTotal) in
        } successHandler: {
            Toast(text: "File Upload Completed", duration: Delay.short).show()
            STFTPNetwork.disconnect()
        } failHandler: { (errorCode) in
            Toast(text: "File Upload Failed", duration: Delay.short).show()
            STFTPNetwork.disconnect()
        }

    }
    
    func uploadToAWS(_ fileURL: URL) {
        AWSS3Manager.shared.uploadImage(imageUrl: fileURL) { (progress) in
            
        } completion: { (uploadedFilePath, error) in
            if error == nil {
                Toast(text: "File Upload Completed", duration: Delay.short).show()
            } else {
                Toast(text: "File Upload Failed", duration: Delay.short).show()
            }
        }
    }

    
    func startCheckStreamStatus() {
        checkStatusTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(checkStreamStatus), userInfo: nil, repeats: true)
    }
    
    func stopCheckStreamStatus() {
        checkStatusTimer?.invalidate()
        checkStatusTimer = nil
        
        self.Reply_View.isHidden = true
    }
    
    @objc func checkStreamStatus() {
        Service_API.checkStreamStatus(bandWidth: bandWidth) { (streamStatusResponse, error) in
            guard let streamStatusResponse = streamStatusResponse else { return }
            
            if let comment = streamStatusResponse.comment, !comment.isEmpty, comment != "NULL" {
                self.Reply_View.isHidden = false
                self.Reply_Comment_Label.text = comment
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.Reply_View.isHidden = true
                    self.deleteMessage()
                }
            }
            
            if !self.isBroadcasting { return }
            
            if let message = streamStatusResponse.message, !message.isEmpty {
                if message.caseInsensitiveCompare("Stream_Going_Live") == .orderedSame {
                    self.hideBroadcastingView()
                    self.showBroadcastingView()
                    self.Broadcasting_Background_View.backgroundColor = .appButtonRedColor
                    self.Broadcasting_Label.text = "LIVE"
                } else if message.caseInsensitiveCompare("Client_Cancel_the_Stream_After_Going_Live") == .orderedSame {
                    self.hideBroadcastingView()
                    self.stopStream()
                    self.navigationController?.popToRootViewController(animated: true)
                } else if message.caseInsensitiveCompare("Client_Cancel_the_Stream_Before_Going_Live") == .orderedSame {
                    self.hideBroadcastingView()
                    self.stopStream()
                    self.navigationController?.popToRootViewController(animated: true)
                } else if message.caseInsensitiveCompare("Recording") == .orderedSame {
                    self.hideBroadcastingView()
                    self.showBroadcastingView()
                    self.Broadcasting_Background_View.backgroundColor = .appButtonBlueColor
                    self.Broadcasting_Label.text = "ON-QUE"
                }
            }
            
            if let messageStatus = streamStatusResponse.message_status, !messageStatus.isEmpty,
               let color_code_bg = streamStatusResponse.color_code_bg, !color_code_bg.isEmpty {
                self.hideBroadcastingView()
                self.showBroadcastingView()
                self.Broadcasting_Background_View.backgroundColor = UIColor(hexString: color_code_bg)
                self.Broadcasting_Label.text = messageStatus
            }
        }
    }
    
    func sendMessage(_ message: String) {
        Service_API.addStreamMessage(message: message) { (response, error) in
            if let response = response, !response.error {
                Toast(text: "Message Sent!", duration: Delay.short).show()
            }
        }
    }
    
    func deleteMessage() {
        Service_API.deleteStreamMessages { (_, _) in
            
        }
    }
}

extension LiveBroadcastVC: ASCircularButtonDelegate {
    func buttonForIndexAt(_ menuButton: ASCircularMenuButton, indexForButton: Int) -> UIButton {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        if indexForButton == 2 {
            button.backgroundColor = .appGreenColor
            button.setTitle("L&S", for: .normal)
        } else if indexForButton == 1 {
            button.backgroundColor = .appRedColor
            button.setTitle("Live", for: .normal)
        } else if indexForButton == 0 {
            button.backgroundColor = .appBlueColor
            button.setTitle("Save", for: .normal)
        }
        
        return button
    }
    
    func didClickOnCircularMenuButton(_ menuButton: ASCircularMenuButton, indexForButton: Int, button: UIButton) {
        if indexForButton == 2 {
            LarixSettings.sharedInstance.canBroadcast = true
            LarixSettings.sharedInstance.record = true
        } else if indexForButton == 1 {
            LarixSettings.sharedInstance.canBroadcast = true
            LarixSettings.sharedInstance.record = false
        } else if indexForButton == 0 {
            LarixSettings.sharedInstance.canBroadcast = false
            LarixSettings.sharedInstance.record = true
        }
        
        loadModeButton()
    }
}

extension LiveBroadcastVC: StreamChatVCDelegate {
    func onDismiss() {
        Chat_View.isHidden = true
    }
}
