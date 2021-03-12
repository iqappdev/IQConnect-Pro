//
//  LoginResponse.swift
//  IQConnect
//
//  Created by SuperDev on 07.01.2021.
//

import UIKit
import SwiftyJSON

@objc class LoginResponse: NSObject, Serializable {
    enum LoginResponseKeys: String, CodingKey {
        case error
        case message
        case status
        case user_id
        case name
        case last_name
        case phone
        case mail
        case channel_id
        case photo_url
        case channel_name
        case news_feed
        case speed_test_id
        case abr_type
        
        static func allKeys() -> [LoginResponseKeys] {
            return [
                error,
                message,
                status,
                user_id,
                name,
                last_name,
                phone,
                mail,
                channel_id,
                photo_url,
                channel_name,
                news_feed,
                speed_test_id,
                abr_type
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return LoginResponseKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var error: Bool = false
    @objc var message: String?
    @objc var status: String?
    @objc var user_id: String?
    @objc var name: String?
    @objc var last_name: String?
    @objc var phone: String?
    @objc var mail: String?
    @objc var channel_id: String?
    @objc var photo_url: String?
    @objc var channel_name: String?
    @objc var news_feed: String?
    @objc var speed_test_id: Int = 0
    @objc var abr_type: String?
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        let json = JSON(dictionary)
        
        self.error = json[LoginResponseKeys.error.rawValue].boolValue
        self.message = json[LoginResponseKeys.message.rawValue].string
        self.status = json[LoginResponseKeys.status.rawValue].string
        self.user_id = json[LoginResponseKeys.user_id.rawValue].string
        self.name = json[LoginResponseKeys.name.rawValue].string
        self.last_name = json[LoginResponseKeys.last_name.rawValue].string
        self.phone = json[LoginResponseKeys.phone.rawValue].string
        self.mail = json[LoginResponseKeys.mail.rawValue].string
        self.channel_id = json[LoginResponseKeys.channel_id.rawValue].string
        self.photo_url = json[LoginResponseKeys.photo_url.rawValue].string
        self.channel_name = json[LoginResponseKeys.channel_name.rawValue].string
        self.news_feed = json[LoginResponseKeys.news_feed.rawValue].string
        self.speed_test_id = json[LoginResponseKeys.speed_test_id.rawValue].intValue
        self.abr_type = json[LoginResponseKeys.abr_type.rawValue].string
    }
    
    internal override init() {
        
    }
}
