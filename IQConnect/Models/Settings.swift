//
//  UserInfo.swift
//  IQConnect
//
//  Created by SuperDev on 07.01.2021.
//

import UIKit
import SwiftyJSON

@objc class Settings: NSObject, Serializable {
    enum SettingsKeys: String, CodingKey {
        case latestVersion
        case latestVersionCode
        case url
        case force_update
        case description
        case privacy_policy
        case terms
        case email_contact
        
        static func allKeys() -> [SettingsKeys] {
            return [
                latestVersion,
                latestVersionCode,
                url,
                force_update,
                description,
                privacy_policy,
                terms,
                email_contact
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return SettingsKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var latestVersion: String?
    @objc var latestVersionCode: String?
    @objc var url: String?
    @objc var force_update: String?
    @objc var descriptionText: String?
    @objc var privacy_policy: String?
    @objc var terms: String?
    @objc var email_contact: String?
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        let json = JSON(dictionary)
        
        self.latestVersion = json[SettingsKeys.latestVersion.rawValue].string
        self.latestVersionCode = json[SettingsKeys.latestVersionCode.rawValue].string
        self.url = json[SettingsKeys.url.rawValue].string
        self.force_update = json[SettingsKeys.force_update.rawValue].string
        self.descriptionText = json[SettingsKeys.description.rawValue].string
        self.privacy_policy = json[SettingsKeys.privacy_policy.rawValue].string
        self.terms = json[SettingsKeys.terms.rawValue].string
        self.email_contact = json[SettingsKeys.email_contact.rawValue].string
    }
    
    internal override init() {
        
    }
}
