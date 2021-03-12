//
//  FtpS3WatermaskDetails.swift
//  IQConnect
//
//  Created by SuperDev on 14.01.2021.
//

import UIKit
import SwiftyJSON

@objc class FtpS3WatermaskDetails: NSObject, Serializable {
    enum FtpS3WatermaskDetailsKeys: String, CodingKey {
        case iv
        case secret_key
        case upload_service
        case S3_HOST
        case S3_ID
        case S3_KEY
        case ftp_ip
        case ftp_port
        case ftp_user
        case ftp_pwd
        case watermark_logo
        case watermark_status
        
        static func allKeys() -> [FtpS3WatermaskDetailsKeys] {
            return [
                iv,
                secret_key,
                upload_service,
                S3_HOST,
                S3_ID,
                S3_KEY,
                ftp_ip,
                ftp_port,
                ftp_user,
                ftp_pwd,
                watermark_logo,
                watermark_status
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return FtpS3WatermaskDetailsKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var iv: String?
    @objc var secret_key: String?
    @objc var upload_service: String?
    @objc var S3_HOST: String?
    @objc var S3_ID: String?
    @objc var S3_KEY: String?
    @objc var ftp_ip: String?
    @objc var ftp_port: String?
    @objc var ftp_user: String?
    @objc var ftp_pwd: String?
    @objc var watermark_logo: String?
    @objc var watermark_status: Int = 0
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        let json = JSON(dictionary)
        
        self.iv = json[FtpS3WatermaskDetailsKeys.iv.rawValue].string
        self.secret_key = json[FtpS3WatermaskDetailsKeys.secret_key.rawValue].string
        self.upload_service = json[FtpS3WatermaskDetailsKeys.upload_service.rawValue].string
        self.S3_HOST = json[FtpS3WatermaskDetailsKeys.S3_HOST.rawValue].string
        self.S3_ID = json[FtpS3WatermaskDetailsKeys.S3_ID.rawValue].string
        self.S3_KEY = json[FtpS3WatermaskDetailsKeys.S3_KEY.rawValue].string
        self.ftp_ip = json[FtpS3WatermaskDetailsKeys.ftp_ip.rawValue].string
        self.ftp_port = json[FtpS3WatermaskDetailsKeys.ftp_port.rawValue].string
        self.ftp_user = json[FtpS3WatermaskDetailsKeys.ftp_user.rawValue].string
        self.ftp_pwd = json[FtpS3WatermaskDetailsKeys.ftp_pwd.rawValue].string
        self.watermark_logo = json[FtpS3WatermaskDetailsKeys.watermark_logo.rawValue].string
        self.watermark_status = json[FtpS3WatermaskDetailsKeys.watermark_status.rawValue].intValue
    }
    
    internal override init() {
        
    }
}


