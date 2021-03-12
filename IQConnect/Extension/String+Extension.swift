//
//  String+Extension.swift
//  IQConnect
//
//  Created by SuperDev on 14.01.2021.
//

import Foundation
import CryptoSwift

extension String {
 
    func decryptAES(key: String, iv: String) -> String {
        do {
            let encrypted = self
            let keyArray = Array(key.utf8)
            let ivArray = Array(iv.utf8)
            let aes = try AES(key: keyArray, blockMode: CBC(iv: ivArray), padding: .noPadding)
            let decrypted = try aes.decrypt(Array(hex: encrypted))
            return String(data: Data(decrypted), encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
