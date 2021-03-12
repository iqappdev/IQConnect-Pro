//
//  SendFilesVC.swift
//  IQConnect
//
//  Created by SuperDev on 14.01.2021.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import STFTPNetwork

enum UploadingStatus {
    case none
    case uploading
    case success
    case failure
}

struct UploadFile {
    var url: URL
    var progress: CGFloat
    var status: UploadingStatus
}

class SendFilesVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var uploadingLoadingBar: UIView!
    
    private var uploadingFileList = [UploadFile]()
    var fileList: [URL] = [] {
        didSet {
            for fileUrl in fileList {
                let uploadingFile = UploadFile(url: fileUrl, progress: 0, status: .none)
                uploadingFileList.append(uploadingFile)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startUpload()
    }
    
    @IBAction func onDoneButtonClick(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
    }
    
    func startUpload() {
        let uploadService = SharedManager.sharedInstance.getUploadService()
        if uploadService == "S3" {
            uploadToAWS(0)
        } else if uploadService == "FTP" {
            connectToFTP()
        }
    }
    
    func connectToFTP() {
        let ftpIp = SharedManager.sharedInstance.getFtpIp()
        let ftpPort = SharedManager.sharedInstance.getFtpPort()
        let ftpUser = SharedManager.sharedInstance.getFtpUser()
        let ftpPwd = SharedManager.sharedInstance.getFtpPwd()
        
        STFTPNetwork.connect("ftp://\(ftpIp):\(ftpPort)", username: ftpUser, password: ftpPwd) { (success) in
            if !success {
                UIHelper.showError(message: "Can't connect to ftp server.")
                
                self.uploadingLoadingBar.isHidden = true
                self.doneButton.isHidden = false
                
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            let channelID = SharedManager.sharedInstance.getChannelID()
            let userID = SharedManager.sharedInstance.getUserID()
            let remotePath = "ftp://\(ftpIp):\(ftpPort)/\(channelID)/\(userID)"
            STFTPNetwork.create(remotePath) {
                self.uploadToFTP(0)
            } failHandler: { (errorCode) in
                self.uploadToFTP(0)
            }
        }
    }
    
    func uploadToFTP(_ position: Int) {
        if position == fileList.count {
            uploadingLoadingBar.isHidden = true
            doneButton.isHidden = false
            
            STFTPNetwork.disconnect()
            
            return
        }
        
        uploadingFileList[position].status = .uploading
        
        let ftpIp = SharedManager.sharedInstance.getFtpIp()
        let ftpPort = SharedManager.sharedInstance.getFtpPort()
        let channelID = SharedManager.sharedInstance.getChannelID()
        let userID = SharedManager.sharedInstance.getUserID()
        let fileName = AWSS3Manager.shared.getUniqueFileName(fileUrl: uploadingFileList[position].url)
        let remotePath = "ftp://\(ftpIp):\(ftpPort)/\(channelID)/\(userID)/\(fileName)"
        let localFilePath = uploadingFileList[position].url.path
        STFTPNetwork.upload(localFilePath, urlString: remotePath) { (bytesCompleted, bytesTotal) in
            
            let progress: CGFloat = bytesTotal > 0 ? CGFloat(bytesCompleted) / CGFloat(bytesTotal) : 0
            self.uploadingFileList[position].progress = progress
            if let cell = self.tableView.cellForRow(at: IndexPath(row: position, section: 0)) as? UploadingFileCell {
                cell.progressBar.setProgress(CGFloat(progress), animated: true)
            }
            
        } successHandler: {
            self.uploadingFileList[position].status = .success
            self.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .none)
            self.uploadToFTP(position + 1)
        } failHandler: { (errorCode) in
            self.uploadingFileList[position].status = .failure
            self.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .none)
            self.uploadToFTP(position + 1)
        }

    }
    
    func uploadToAWS(_ position: Int) {
        if position == fileList.count {
            uploadingLoadingBar.isHidden = true
            doneButton.isHidden = false
            return
        }
        
        uploadingFileList[position].status = .uploading
        
        let ext = uploadingFileList[position].url.pathExtension
        switch ext {
        case "jpg", "heic":
            AWSS3Manager.shared.uploadImage(imageUrl: uploadingFileList[position].url) { (progress) in
                self.uploadingFileList[position].progress = CGFloat(progress)
                if let cell = self.tableView.cellForRow(at: IndexPath(row: position, section: 0)) as? UploadingFileCell {
                    cell.progressBar.setProgress(CGFloat(progress), animated: true)
                }
            } completion: { (uploadedFilePath, error) in
                if error == nil {
                    self.uploadingFileList[position].status = .success
                } else {
                    self.uploadingFileList[position].status = .failure
                }
                self.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .none)
                self.uploadToAWS(position + 1)
            }

        case "mov":
            AWSS3Manager.shared.uploadVideo(videoUrl: uploadingFileList[position].url) { (progress) in
                self.uploadingFileList[position].progress = CGFloat(progress)
                if let cell = self.tableView.cellForRow(at: IndexPath(row: position, section: 0)) as? UploadingFileCell {
                    cell.progressBar.setProgress(CGFloat(progress), animated: true)
                }
            } completion: { (uploadedFilePath, error) in
                if error == nil {
                    self.uploadingFileList[position].status = .success
                } else {
                    self.uploadingFileList[position].status = .failure
                }
                self.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .none)
                self.uploadToAWS(position + 1)
            }
        case "m4a":
            AWSS3Manager.shared.uploadAudio(audioUrl: uploadingFileList[position].url) { (progress) in
                self.uploadingFileList[position].progress = CGFloat(progress)
                if let cell = self.tableView.cellForRow(at: IndexPath(row: position, section: 0)) as? UploadingFileCell {
                    cell.progressBar.setProgress(CGFloat(progress), animated: true)
                }
            } completion: { (uploadedFilePath, error) in
                if error == nil {
                    self.uploadingFileList[position].status = .success
                } else {
                    self.uploadingFileList[position].status = .failure
                }
                self.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .none)
                self.uploadToAWS(position + 1)
            }
        default:
            AWSS3Manager.shared.uploadOtherFile(fileUrl: uploadingFileList[position].url, conentType: "other") { (progress) in
                self.uploadingFileList[position].progress = CGFloat(progress)
                if let cell = self.tableView.cellForRow(at: IndexPath(row: position, section: 0)) as? UploadingFileCell {
                    cell.progressBar.setProgress(CGFloat(progress), animated: true)
                }
            } completion: { (uploadedFilePath, error) in
                if error == nil {
                    self.uploadingFileList[position].status = .success
                } else {
                    self.uploadingFileList[position].status = .failure
                }
                self.tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .none)
                self.uploadToAWS(position + 1)
            }
        }
    }
}

extension SendFilesVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uploadingFileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "UploadingFileCell") as? UploadingFileCell {
            let file = uploadingFileList[indexPath.row]
            cell.file = file
            return cell
        }
        
        return UITableViewCell()
    }
}
