//
//  MessagesResponse.swift
//  IQConnect
//
//  Created by SuperDev on 13.01.2021.
//

import UIKit

@objc class MessagesResponse: NSObject, Serializable {
    enum MessagesResponseKeys: String, CodingKey {
        case preset_msg
        
        static func allKeys() -> [MessagesResponseKeys] {
            return [
                preset_msg
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return MessagesResponseKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var preset_msg = [Message]()
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        if let msgsArray = dictionary[MessagesResponseKeys.preset_msg.rawValue] as? [[String : Any]] {
            for msgDict in msgsArray {
                if let msg = Message(dictionary: msgDict) {
                    self.preset_msg.append(msg)
                }
            }
        }
    }
    
    internal override init() {
        
    }
}
