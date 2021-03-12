//
//  Message.swift
//  IQConnect
//
//  Created by SuperDev on 13.01.2021.
//

import UIKit
import SwiftyJSON

@objc class Message: NSObject, Serializable {
    enum MessageKeys: String, CodingKey {
        case id
        case msg
        
        static func allKeys() -> [MessageKeys] {
            return [
                id,
                msg
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return MessageKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var id: Int = 0
    @objc var msg: String?
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        let json = JSON(dictionary)
        
        self.id = json[MessageKeys.id.rawValue].intValue
        self.msg = json[MessageKeys.msg.rawValue].string
    }
    
    internal override init() {
        
    }
}


