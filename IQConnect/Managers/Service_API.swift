//
//  Service_API.swift
//  IQConnect
//
//  Created by SuperDev on 07.01.2021.
//

import UIKit
import Alamofire
import SWXMLHash

//let SERVER_URL = "http://reporterapi.iqsat.net/index1.php/"
let SERVER_URL = "https://reporterapios.iqconnect.io/v2/index1.php/"
let SPEED_TEST_SERVER_URL = "https://www.speedtest.net/speedtest-servers-static.php"

class Service_API: NSObject {
    
    static func callWebservice(
        apiPath: String,
        method: HTTPMethod,
        parameters: Parameters?,
        completion: @escaping (Error?, Any?)->()
    ) {
        
        let url = "\(SERVER_URL)\(apiPath)"
        
        AF.request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: nil, interceptor: nil, requestModifier: nil).responseJSON { (response) in
            
            switch response.result {
            case .success(let JSON):
                let data = JSON as! NSDictionary
                completion(nil, data)
            case .failure(let error):
                completion(error, nil)
            }
        }
    }
    
    static func getSpeedTestServers(completion: @escaping ([SpeedTestServer]?, Error?)->()) {
        AF.request(SPEED_TEST_SERVER_URL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil, interceptor: nil, requestModifier: nil).responseData { (response) in
            switch response.result {
            case .success(let data):
                let xml = SWXMLHash.parse(data)
                let speedTestServers: [SpeedTestServer] = try! xml["settings"]["servers"]["server"].value()
                completion(speedTestServers, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    static func getSettings(
        completion: @escaping (Settings?, Error?)->()
    ) {
        let parameters = [
            "platform": "IOS"
        ]
        callWebservice(apiPath: "get_version", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let settings = Settings(dictionary: dict)
                completion(settings, nil)
            }
        }
    }
    
    static func login(
        userID: String,
        password: String,
        deviceToken: String,
        completion: @escaping (LoginResponse?, Error?)->()
    ) {
        let parameters = [
            "userid": userID,
            "password": password,
            "devicetoken": deviceToken,
            "platform": "IOS"
        ]
        
        callWebservice(apiPath: "signinReporter", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let loginResponse = LoginResponse(dictionary: dict)
                completion(loginResponse, nil)
            }
        }
    }
    
    static func updateProfile(
        userID: String,
        name: String,
        lastName: String,
        phone: String,
        email: String,
        completion: @escaping (NormalResponse?, Error?)->()
    ) {
        let parameters = [
            "reporter_id": userID,
            "first_name": name,
            "last_name": lastName,
            "email": email,
            "mobile": phone
        ]
        
        callWebservice(apiPath: "update_reporter", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = NormalResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func changePassword(
        userID: String,
        oldPassword: String,
        newPassword: String,
        completion: @escaping (NormalResponse?, Error?)->()
    ) {
        let parameters = [
            "userid": userID,
            "old_password": oldPassword,
            "new_password": newPassword
        ]
        
        callWebservice(apiPath: "change_password", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = NormalResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func contactUs(
        name: String,
        subject: String,
        message: String,
        completion: @escaping (NormalResponse?, Error?)->()
    ) {
        let parameters = [
            "name": name,
            "subject": subject,
            "message": message,
            "email": SharedManager.sharedInstance.getUserEmail()
        ]
        
        callWebservice(apiPath: "contact_us", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = NormalResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func getVideoResolutions(
        channelID: String,
        completion: @escaping (VideoResolutionList?, Error?)->()
    ) {
        let parameters = [
            "cl_id": channelID,
            "platform": "IOS"
        ]
        
        callWebservice(apiPath: "encoding_details", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let videoResolutionList = VideoResolutionList(dictionary: dict)
                completion(videoResolutionList, nil)
            }
        }
    }
    
    static func startStream(
        videoResolution: String,
        completion: @escaping (StreamResponse?, Error?)->()
    ) {
        let parameters = [
            "cl_id": SharedManager.sharedInstance.getChannelID(),
            "username": SharedManager.sharedInstance.getUserName(),
            "user_id": SharedManager.sharedInstance.getUserID(),
            "email": SharedManager.sharedInstance.getUserEmail(),
            "resolution": videoResolution,
            "event_name": SharedManager.sharedInstance.getEventName(),
            "event_description": SharedManager.sharedInstance.getEventDescription(),
            "location": SharedManager.sharedInstance.getCity()
        ]
        
        callWebservice(apiPath: "reporter_stream", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let streamResponse = StreamResponse(dictionary: dict)
                completion(streamResponse, nil)
            }
        }
    }
    
    static func stopStream(
        completion: ((Error?)->())?
    ) {
        let parameters = [
            "user_id": SharedManager.sharedInstance.getUserID()
        ]
        
        callWebservice(apiPath: "stop_stream", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                print(error.localizedDescription)
                completion?(error)
                return
            }
            
            completion?(nil)
        }
    }
    
    static func checkStreamStatus(
        bandWidth: String,
        completion: @escaping (StreamStatusResponse?, Error?)->()
    ) {
        let parameters = [
            "user_id": SharedManager.sharedInstance.getUserID(),
            "StreamSpeed": bandWidth
        ]
        
        callWebservice(apiPath: "reporter_stream_check", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = StreamStatusResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func getPresetMessages(completion: ((MessagesResponse?, Error?)->())?) {
        let parameters = [
            "user_id": SharedManager.sharedInstance.getUserID()
        ]
        
        callWebservice(apiPath: "reporter_msg", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion?(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let messagesResponse = MessagesResponse(dictionary: dict)
                completion?(messagesResponse, nil)
            }
        }
    }
    
    static func addStreamMessage(
        message: String,
        completion: @escaping (NormalResponse?, Error?)->()
    ) {
        let parameters = [
            "user_id": SharedManager.sharedInstance.getUserID(),
            "reply": message
        ]
        
        callWebservice(apiPath: "reply", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = NormalResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func deleteStreamMessages(
        completion: @escaping (NormalResponse?, Error?)->()
    ) {
        let parameters = [
            "user_id": SharedManager.sharedInstance.getUserID()
        ]
        
        callWebservice(apiPath: "remove_comment", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = NormalResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func getMessages(completion: ((MessagesResponse?, Error?)->())?) {
        let parameters = [
            "user_id": SharedManager.sharedInstance.getUserID()
        ]
        
        callWebservice(apiPath: "show_reporter_msg", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion?(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let messagesResponse = MessagesResponse(dictionary: dict)
                completion?(messagesResponse, nil)
            }
        }
    }
    
    static func addMessage(
        message: String,
        completion: @escaping (NormalResponse?, Error?)->()
    ) {
        let parameters = [
            "user_id": SharedManager.sharedInstance.getUserID(),
            "channel_id": SharedManager.sharedInstance.getChannelID(),
            "msg": message
        ]
        
        callWebservice(apiPath: "add_reporter_msg", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = NormalResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func editMessage(
        messageId: Int,
        message: String,
        completion: @escaping (NormalResponse?, Error?)->()
    ) {
        let parameters = [
            "msg_id": messageId,
            "msg": message
        ] as [String : Any]
        
        callWebservice(apiPath: "edit_reporter_msg", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = NormalResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func deleteMessage(
        messageId: Int,
        completion: @escaping (NormalResponse?, Error?)->()
    ) {
        let parameters = [
            "msg_id": messageId
        ]
        
        callWebservice(apiPath: "delete_reporter_msg", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = NormalResponse(dictionary: dict)
                completion(response, nil)
            }
        }
    }
    
    static func getFtpS3WatermarkDetails(
        completion: @escaping (FtpS3WatermaskDetails?, Error?)->()
    ) {
        let parameters = [
            "channel_id": SharedManager.sharedInstance.getChannelID()
        ]
        
        callWebservice(apiPath: "ftp_s3_watermark", method: .post, parameters: parameters) { (error, result) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let dict = result as? [String: Any] {
                let response = FtpS3WatermaskDetails(dictionary: dict)
                completion(response, nil)
            }
        }
    }
}
