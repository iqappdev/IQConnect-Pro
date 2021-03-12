//
//  StreamStatusResponse.swift
//  IQConnect
//
//  Created by SuperDev on 20.01.2021.
//

import UIKit
import SwiftyJSON

@objc class StreamStatusResponse: NSObject, Serializable {
    enum StreamStatusResponseKeys: String, CodingKey {
        case comment
        case message
        case message_status
        case color_code_bg
        
        static func allKeys() -> [StreamStatusResponseKeys] {
            return [
                comment,
                message,
                message_status,
                color_code_bg
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return StreamStatusResponseKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var comment: String?
    @objc var message: String?
    @objc var message_status: String?
    @objc var color_code_bg: String?
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        let json = JSON(dictionary)
        
        self.comment = json[StreamStatusResponseKeys.comment.rawValue].string
        self.message = json[StreamStatusResponseKeys.message.rawValue].string
        self.message_status = json[StreamStatusResponseKeys.message_status.rawValue].string
        self.color_code_bg = json[StreamStatusResponseKeys.color_code_bg.rawValue].string
    }
    
    internal override init() {
        
    }

}
