//
//  NormalResponse.swift
//  IQConnect
//
//  Created by SuperDev on 13.01.2021.
//

import UIKit
import SwiftyJSON

@objc class NormalResponse: NSObject, Serializable {
    enum NormalResponseKeys: String, CodingKey {
        case error
        case message
        
        static func allKeys() -> [NormalResponseKeys] {
            return [
                error,
                message
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return NormalResponseKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var error: Bool = false
    @objc var message: String?
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        let json = JSON(dictionary)
        
        self.error = json[NormalResponseKeys.error.rawValue].boolValue
        self.message = json[NormalResponseKeys.message.rawValue].string
    }
    
    internal override init() {
        
    }
}

