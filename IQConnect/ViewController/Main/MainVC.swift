//
//  MainVC.swift
//  IQConnect
//
//  Created by SuperDev on 08.01.2021.
//

import UIKit
import SideMenuSwift
import SDWebImage
import NVActivityIndicatorView

struct VideoFile {
    var url: URL
    var videoDuration: String
    var videoThumbnail: UIImage?
}

class MainVC: UIViewController, NVActivityIndicatorViewable {
    
    enum ViewMode: Int {
        case videos
        case pictures
    }
    
    static var watermarkImage: UIImage?
    
    @IBOutlet weak var videosTableView: UITableView!
    @IBOutlet weak var picturesTableView: UITableView!
    
    @IBOutlet weak var videosButton: UIButton!
    @IBOutlet weak var picturesButton: UIButton!
    @IBOutlet weak var videosSeparator: UIView!
    @IBOutlet weak var picturesSeparator: UIView!
    
    let fm = FileManager.default
    var videoFileList: [VideoFile] = []
    var pictureFileList: [VideoFile] = []
    var viewMode: ViewMode = .videos
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.videosTableView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        self.picturesTableView.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        getFtpS3WatermarkDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadVideoFiles()
        }
    }
    
    @IBAction func onMenuButtonClick(_ sender: UIButton) {
        sideMenuController?.revealMenu()
    }
    
    @IBAction func onViewModeButtonClick(_ sender: UIButton) {
        var viewMode: ViewMode = .pictures
        if sender == videosButton {
            viewMode = .videos
        }
        
        if viewMode == self.viewMode {
            return
        }
        
        self.viewMode = viewMode
        
        videosButton.isSelected = false
        picturesButton.isSelected = false
        videosSeparator.isHidden = true
        picturesSeparator.isHidden = true
        videosTableView.isHidden = true
        picturesTableView.isHidden = true
        switch viewMode {
        case .videos:
            videosButton.isSelected = true
            videosSeparator.isHidden = false
            videosTableView.isHidden = false
        default:
            picturesButton.isSelected = true
            picturesSeparator.isHidden = false
            picturesTableView.isHidden = false
        }
    }
    
    @IBAction func onGoLiveButtonClick(_ sender: UIButton) {
        let alert = UIAlertController(title: "IQ Connect Pro", message: "We suggest to run speedtest before live streaming! Do you wish to run a speed test?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .cancel, handler: { (_) in
            self.performSegue(withIdentifier: "speedTestSegue", sender: nil)
        }))
        alert.addAction(UIAlertAction(title: "SKIP", style: .default, handler: { (_) in
            SharedManager.sharedInstance.setVideoResolutionSuggested(false)
            self.performSegue(withIdentifier: "liveDetailSegue", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func loadVideoFiles() {
        self.startAnimating(type: .lineScalePulseOut)
        
        DispatchQueue.global(qos: .background).async {
            do {
                let localPath = try self.fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let allFileList = try self.fm.contentsOfDirectory(at: localPath, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .effectiveIconKey ], options: [.skipsHiddenFiles])
                
                // get videos
                var videoFileList = [VideoFile]()
                let videoFileUrls = self.sortVideoFileList(fileList: allFileList, byAttr: .creationDateKey, descending: true)
                for fileUrl in videoFileUrls {
                    videoFileList.append(VideoFile(url: fileUrl, videoDuration: fileUrl.getVideoDuration(), videoThumbnail: fileUrl.thumbnail()))
                }
                if (videoFileList.count != self.videoFileList.count) {
                    DispatchQueue.main.async {
                        self.videoFileList = videoFileList
                        self.videosTableView.reloadData()
                    }
                }
                
                // get pictures
                var pictureFileList = [VideoFile]()
                let pictureFileUrls = self.sortPictureFileList(fileList: allFileList, byAttr: .creationDateKey, descending: true)
                for fileUrl in pictureFileUrls {
                    pictureFileList.append(VideoFile(url: fileUrl, videoDuration: "", videoThumbnail: try UIImage(url: fileUrl)))
                }
                if (pictureFileList.count != self.pictureFileList.count) {
                    DispatchQueue.main.async {
                        self.pictureFileList = pictureFileList
                        self.picturesTableView.reloadData()
                    }
                }
            } catch {
                print("Get file contents failed")
            }
            
            DispatchQueue.main.async {
                self.stopAnimating()
            }
        }
    }
    
    func getFtpS3WatermarkDetails() {
        Service_API.getFtpS3WatermarkDetails { (ftpS3WatermarkDetails, error) in
            guard let ftpS3WatermarkDetails = ftpS3WatermarkDetails, error == nil else {
                return
            }
            
            guard let iv = ftpS3WatermarkDetails.iv, let secretKey = ftpS3WatermarkDetails.secret_key else {
                return
            }
            
            let uploadServivce = ftpS3WatermarkDetails.upload_service ?? ""
            let s3Host = ftpS3WatermarkDetails.S3_HOST?.decryptAES(key: secretKey, iv: iv).replacingOccurrences(of: "\0", with: "") ?? ""
            let s3ID = ftpS3WatermarkDetails.S3_ID?.decryptAES(key: secretKey, iv: iv).replacingOccurrences(of: "\0", with: "") ?? ""
            let s3Key = ftpS3WatermarkDetails.S3_KEY?.decryptAES(key: secretKey, iv: iv).replacingOccurrences(of: "\0", with: "") ?? ""
            let ftpIp = ftpS3WatermarkDetails.ftp_ip?.decryptAES(key: secretKey, iv: iv).replacingOccurrences(of: "\0", with: "") ?? ""
            let ftpPort = ftpS3WatermarkDetails.ftp_port?.decryptAES(key: secretKey, iv: iv).replacingOccurrences(of: "\0", with: "") ?? ""
            let ftpUser = ftpS3WatermarkDetails.ftp_user?.decryptAES(key: secretKey, iv: iv).replacingOccurrences(of: "\0", with: "") ?? ""
            let ftpPwd = ftpS3WatermarkDetails.ftp_pwd?.decryptAES(key: secretKey, iv: iv).replacingOccurrences(of: "\0", with: "") ?? ""
            let watermarkLogo = ftpS3WatermarkDetails.watermark_logo ?? ""
            let watermarkStatus = ftpS3WatermarkDetails.watermark_status
            print("s3Host=\(s3Host)")
            print("s3ID=\(s3ID)")
            print("s3Key=\(s3Key)")
            
            SharedManager.sharedInstance.setUploadService(uploadServivce)
            SharedManager.sharedInstance.setS3Host(s3Host)
            SharedManager.sharedInstance.setS3ID(s3ID)
            SharedManager.sharedInstance.setS3Key(s3Key)
            SharedManager.sharedInstance.setFtpIp(ftpIp)
            SharedManager.sharedInstance.setFtpPort(ftpPort)
            SharedManager.sharedInstance.setFtpUser(ftpUser)
            SharedManager.sharedInstance.setFtpPwd(ftpPwd)
            SharedManager.sharedInstance.setWatermarkLogo(watermarkLogo)
            SharedManager.sharedInstance.setWatermarkStatus(watermarkStatus)
            
            if !watermarkLogo.isEmpty {
                SDWebImageDownloader.shared.downloadImage(with: URL(string: watermarkLogo)) { (image, data, error, finished) in
                    MainVC.watermarkImage = image
                }
            }
            
            AWSS3Manager.shared.initializeAWSS3()
        }
    }
    
    func sortVideoFileList(fileList: [URL], byAttr: URLResourceKey, descending: Bool) -> [URL] {
        var videoFileList = fileList.filter { $0.pathExtension == "mov"}
        videoFileList.sort { (url1, url2) -> Bool in
            var val1:URLResourceValues
            var val2:URLResourceValues
            do {
                val1 = try url1.resourceValues(forKeys: [byAttr])
                val2 = try url2.resourceValues(forKeys: [byAttr])
            } catch {
                return true
            }
            var res = true
            switch byAttr {
            case .fileSizeKey:
                res = val1.fileSize ?? 0 < val2.fileSize ?? 0
            case .creationDateKey where val1.creationDate != nil && val2.creationDate != nil:
                res = val1.creationDate! < val2.creationDate!
            default:
                res = false
            }
            if descending {
                res = !res
            }
            return res
        }
        
        return videoFileList
    }
    
    func sortPictureFileList(fileList: [URL], byAttr: URLResourceKey, descending: Bool) -> [URL] {
        var pictureFileList = fileList.filter { $0.pathExtension == "jpg" || $0.pathExtension == "heic" }
        pictureFileList.sort { (url1, url2) -> Bool in
            var val1:URLResourceValues
            var val2:URLResourceValues
            do {
                val1 = try url1.resourceValues(forKeys: [byAttr])
                val2 = try url2.resourceValues(forKeys: [byAttr])
            } catch {
                return true
            }
            var res = true
            switch byAttr {
            case .fileSizeKey:
                res = val1.fileSize ?? 0 < val2.fileSize ?? 0
            case .creationDateKey where val1.creationDate != nil && val2.creationDate != nil:
                res = val1.creationDate! < val2.creationDate!
            default:
                res = false
            }
            if descending {
                res = !res
            }
            return res
        }
        
        return pictureFileList
    }
    
    func getVideoFilePosition(_ videoFile: VideoFile) -> Int? {
        for i in 0..<videoFileList.count {
            if videoFileList[i].url.path == videoFile.url.path {
                return i
            }
        }
        
        return nil
    }
    
    func getPictureFilePosition(_ pictureFile: VideoFile) -> Int? {
        for i in 0..<pictureFileList.count {
            if pictureFileList[i].url.path == pictureFile.url.path {
                return i
            }
        }
        
        return nil
    }
}

extension MainVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == videosTableView {
            return self.videoFileList.count
        } else {
            return self.pictureFileList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell") as? VideoCell {
            if tableView == videosTableView {
                let file = videoFileList[indexPath.row]
                cell.file = file
                cell.delegate = self
                return cell
            } else {
                let file = pictureFileList[indexPath.row]
                cell.file = file
                cell.delegate = self
                return cell
            }
        }
        
        return UITableViewCell()
    }
}

extension MainVC: VideoCellDelegate {
    func onDeleteAction(_ file: VideoFile) {
        if let position = self.getVideoFilePosition(file) {
            let alert = UIAlertController(title: "IQ Connect Pro", message: "\(file.url.lastPathComponent)\n Do you really want to Delete this file?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { (_) in
                do {
                    try self.fm.removeItem(at: file.url)
                    self.videoFileList.remove(at: position)
                    self.videosTableView.deleteRows(at: [IndexPath(row: position, section: 0)], with: .automatic)
                } catch {
                    
                }
            }))
            present(alert, animated: true, completion: nil)
        }
        
        if let position = self.getPictureFilePosition(file) {
            let alert = UIAlertController(title: "IQ Connect Pro", message: "\(file.url.lastPathComponent)\n Do you really want to Delete this file?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { (_) in
                do {
                    try self.fm.removeItem(at: file.url)
                    self.pictureFileList.remove(at: position)
                    self.picturesTableView.deleteRows(at: [IndexPath(row: position, section: 0)], with: .automatic)
                } catch {
                    
                }
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func onRenameAction(_ file: VideoFile) {
        if let position = self.getVideoFilePosition(file) {
            let alert = UIAlertController(title: "IQ Connect Pro", message: "Rename", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.text = file.url.lastPathComponent.replacingOccurrences(of: ".mov", with: "")
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                guard let filename = alert.textFields![0].text, !filename.isEmpty else { return }
                do {
                    let renameFilePath = file.url.path.replacingOccurrences(of: file.url.lastPathComponent, with: "\(filename).mov")
                    let renameFileUrl = URL(fileURLWithPath: renameFilePath)
                    try self.fm.moveItem(at: file.url, to: renameFileUrl)
                    self.videoFileList[position].url = renameFileUrl
                    self.videosTableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .automatic)
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Error", message: "Filename already exists.")
                    }
                }
                
            }))
            present(alert, animated: true, completion: nil)
        }
        
        if let position = self.getPictureFilePosition(file) {
            let alert = UIAlertController(title: "IQ Connect Pro", message: "Rename", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.text = file.url.lastPathComponent
                    .replacingOccurrences(of: ".\(file.url.pathExtension)", with: "")
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                guard let filename = alert.textFields![0].text, !filename.isEmpty else { return }
                do {
                    let renameFilePath = file.url.path.replacingOccurrences(of: file.url.lastPathComponent, with: "\(filename).\(file.url.pathExtension)")
                    let renameFileUrl = URL(fileURLWithPath: renameFilePath)
                    try self.fm.moveItem(at: file.url, to: renameFileUrl)
                    self.pictureFileList[position].url = renameFileUrl
                    self.picturesTableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .automatic)
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Error", message: "Filename already exists.")
                    }
                }
                
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func onUploadAction(_ file: VideoFile) {
        if let vc = UIHelper.viewControllerWith("SendFilesVC") as? SendFilesVC {
            vc.fileList = [file.url]
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: false, completion: nil)
        }
    }
    
    func onShareAction(_ file: VideoFile, on button: UIButton) {
        let objectsToShare = [file.url]
        let vc = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = button.superview
        vc.popoverPresentationController?.sourceRect = button.frame
        self.present(vc, animated: true, completion: nil)
    }
}
