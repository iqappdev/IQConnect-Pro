//
//  StreamResponse.swift
//  IQConnect
//
//  Created by SuperDev on 11.01.2021.
//

import UIKit
import SwiftyJSON

@objc class StreamResponse: NSObject, Serializable {
    enum StreamResponseKeys: String, CodingKey {
        case stream_link
        case status
        case message
        
        static func allKeys() -> [StreamResponseKeys] {
            return [
                stream_link,
                status,
                message
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return StreamResponseKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var stream_link: String?
    @objc var status: String?
    @objc var message: String?
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        let json = JSON(dictionary)
        
        self.stream_link = json[StreamResponseKeys.stream_link.rawValue].string
        self.status = json[StreamResponseKeys.status.rawValue].string
        self.message = json[StreamResponseKeys.message.rawValue].string
    }
    
    internal override init() {
        
    }
}
