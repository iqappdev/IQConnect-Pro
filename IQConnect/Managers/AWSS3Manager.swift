//
//  AWSS3Manager.swift
//  IQConnect
//
//  Created by SuperDev on 14.01.2021.
//

import Foundation
import UIKit
import AWSS3 //1

typealias progressBlock = (_ progress: Double) -> Void //2
typealias completionBlock = (_ response: Any?, _ error: Error?) -> Void //3

class AWSS3Manager {
    
    static let shared = AWSS3Manager() // 4
    private init () { }
    let bucketName = "iqsinsp01" //5
    
    func initializeAWSS3() {
        let accessKey = SharedManager.sharedInstance.getS3ID()
        let secretKey = SharedManager.sharedInstance.getS3Key()
        let endpoint = AWSEndpoint(urlString: "\(SharedManager.sharedInstance.getS3Host())/IQ_Connect")
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
        let configuration = AWSServiceConfiguration(region: .USWest1, endpoint: endpoint, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    // Upload image using local path url
    func uploadImage(imageUrl: URL, progress: progressBlock?, completion: completionBlock?) {
        let fileName = self.getUniqueFileName(fileUrl: imageUrl)
        self.uploadfile(fileUrl: imageUrl, fileName: fileName, contenType: "image", progress: progress, completion: completion)
        
    }
    
    // Upload video from local path url
    func uploadVideo(videoUrl: URL, progress: progressBlock?, completion: completionBlock?) {
        let fileName = self.getUniqueFileName(fileUrl: videoUrl)
        self.uploadfile(fileUrl: videoUrl, fileName: fileName, contenType: "video", progress: progress, completion: completion)
    }
    
    // Upload auido from local path url
    func uploadAudio(audioUrl: URL, progress: progressBlock?, completion: completionBlock?) {
        let fileName = self.getUniqueFileName(fileUrl: audioUrl)
        self.uploadfile(fileUrl: audioUrl, fileName: fileName, contenType: "audio", progress: progress, completion: completion)
    }
    
    // Upload files like Text, Zip, etc from local path url
    func uploadOtherFile(fileUrl: URL, conentType: String, progress: progressBlock?, completion: completionBlock?) {
        let fileName = self.getUniqueFileName(fileUrl: fileUrl)
        self.uploadfile(fileUrl: fileUrl, fileName: fileName, contenType: conentType, progress: progress, completion: completion)
    }
    
    // Get unique file name
    func getUniqueFileName(fileUrl: URL) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy_hh-mm-ss-SSS"
        let dateStr = dateFormatter.string(from: Date())
        
        let strExt: String = fileUrl.pathExtension
        let filename = fileUrl.lastPathComponent.replacingOccurrences(of: ".\(strExt)", with: "")
        return "\(SharedManager.sharedInstance.getUserID())_\(filename)_\(dateStr).\(strExt)"
    }
    
    //MARK:- AWS file upload
    // fileUrl :  file local path url
    // fileName : name of file, like "myimage.jpeg" "video.mov"
    // contenType: file MIME type
    // progress: file upload progress, value from 0 to 1, 1 for 100% complete
    // completion: completion block when uplaoding is finish, you will get S3 url of upload file here
    private func uploadfile(fileUrl: URL, fileName: String, contenType: String, progress: progressBlock?, completion: completionBlock?) {
        // Upload progress block
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, awsProgress) in
            guard let uploadProgress = progress else { return }
            DispatchQueue.main.async {
                print("progress:\(awsProgress.fractionCompleted)")
                uploadProgress(awsProgress.fractionCompleted)
            }
        }
        // Completion block
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    let url = AWSS3.default().configuration.endpoint.url
                    let key = "\(SharedManager.sharedInstance.getChannelID())/\(SharedManager.sharedInstance.getUserID())/\(fileName)"
                    let publicURL = url?.appendingPathComponent(self.bucketName).appendingPathComponent(key)
                    print("Uploaded to:\(String(describing: publicURL))")
                    if let completionBlock = completion {
                        completionBlock(publicURL?.absoluteString, nil)
                    }
                } else {
                    if let completionBlock = completion {
                        completionBlock(nil, error)
                    }
                }
            })
        }
        // Start uploading using AWSS3TransferUtility
        let awsTransferUtility = AWSS3TransferUtility.default()
        let key = "\(SharedManager.sharedInstance.getChannelID())/\(SharedManager.sharedInstance.getUserID())/\(fileName)"
        awsTransferUtility.uploadFile(fileUrl, bucket: bucketName, key: key, contentType: contenType, expression: expression, completionHandler: completionHandler).continueWith { (task) -> Any? in
            if let error = task.error {
                print("error is: \(error.localizedDescription)")
            }
            if let _ = task.result {
                // your uploadTask
            }
            return nil
        }
    }
}
