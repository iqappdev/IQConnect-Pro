//
//  Serializable.swift
//  IQConnect
//
//  Created by SuperDev on 07.01.2021.
//

import UIKit
import SwifterSwift

protocol Serializable {
    func serializableProperties() -> [String]
    func valueForKey(key: String) -> Any?
    func toDictionary() -> [String : AnyHashable]
}

extension Serializable {
    func toDictionary() -> [String : AnyHashable] {
        var dict: [String : AnyHashable] = [:]
        
        for prop in self.serializableProperties() {
            if let val = self.valueForKey(key: prop) as? String {
                dict[prop] = val
            }
            else if let val = self.valueForKey(key: prop) as? Int {
                dict[prop] = val
            }
            else if let val = self.valueForKey(key: prop) as? Double {
                dict[prop] = val
            }
            else if let val = self.valueForKey(key: prop) as? Bool {
                dict[prop] = val
            }
            else if let val = self.valueForKey(key: prop) as? Date {
                dict[prop] = val
            }
            else if let val = self.valueForKey(key: prop) as? URL {
                dict[prop] = val.absoluteString
            }
            else if let val = self.valueForKey(key: prop) as? UIColor {
                dict[prop] = val.hexString
            }
            else if let val = self.valueForKey(key: prop) as? [String] {
                dict[prop] = val
            }
            else if let val = self.valueForKey(key: prop) as? [String : AnyHashable] {
                dict[prop] = val
            }
            else if let val = self.valueForKey(key: prop) as? NSNull {
                dict[prop] = val
            }
            else if let val = self.valueForKey(key: prop) as? Serializable {
                dict[prop] = val.toDictionary()
            }
            else if let val = self.valueForKey(key: prop) as? [Serializable] {
                var arr = [[String : AnyHashable]]()
                
                for item in (val as [Serializable]) {
                    arr.append(item.toDictionary())
                }
                
                dict[prop] = arr
            }
        }
        
        return dict
    }
}
