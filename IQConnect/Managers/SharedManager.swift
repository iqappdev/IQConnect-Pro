//
//  SharedManager.swift
//  IQConnect
//
//  Created by SuperDev on 07.01.2021.
//

import UIKit

class SharedManager: NSObject {
    static let sharedInstance = SharedManager()
    
    let KEY_PANDC = "pandC"
    let KEY_SINCH_KEY = "sinchKey"
    let KEY_SINCH_APP_SECRET = "sinchAppSecret"
    let KEY_SINCH_ENVIRONMENT = "sinchEnvironment"
    let KEY_CONTACT_MAIL = "contactEmail"
    
    // user
    let KEY_IS_USER_LOGGED_IN = "isUserLoggedIn"
    let KEY_DEVICE_TOKEN = "deviceToken"
    let KEY_USER_ID = "userID"
    let KEY_USER_PASS = "userPass"
    let KEY_CHANNEL_NAME = "channelName"
    let KEY_CHANNEL_ID = "channelID"
    let KEY_USER_NAME = "userName"
    let KEY_USER_LAST_NAME = "userLastName"
    let KEY_USER_EMAIL = "userEmail"
    let KEY_USER_PHONE = "userPhone"
    let KEY_USER_IMAGE = "userImage"
    let KEY_ADB_CHECK = "adbCheck"
    let KEY_SPEED_TEST_SERVER_ID = "speedTestServerID"
    
    // event
    let KEY_VIDEO_RESOLUTION_INDEX = "videoResolutionIndex"
    let KEY_VIDEO_RESOLUTION_SUGGESTED = "videoResolutionSuggested"
    let KEY_VIDEO_CODEC = "videoCodec"
    let KEY_EVENT_NAME = "eventName"
    let KEY_CITY = "city"
    let KEY_EVENT_DESCRIPTION = "eventDescription"
    
    // s3, ftp, watermark
    let KEY_UPLOAD_SERVICE = "uploadService"
    let KEY_S3_ID = "s3ID"
    let KEY_S3_KEY = "s3Key"
    let KEY_S3_HOST = "s3Host"
    let KEY_FTP_IP = "ftpIp"
    let KEY_FTP_PORT = "ftpPort"
    let KEY_FTP_USER = "ftpUser"
    let KEY_FTP_PWD = "ftpPwd"
    let KEY_WATERMARK_LOGO = "watermarkLogo"
    let KEY_WATERMARK_STATUS = "watermarkStatus"
    
    override init() {
        super.init()
    }
    
    func getPandC() -> String {
        return UserDefaults.standard.string(forKey: KEY_PANDC) ?? ""
    }
    
    func setPandC(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_PANDC)
        userDefaults.synchronize()
    }
    
    func getSinchKey() -> String {
        return UserDefaults.standard.string(forKey: KEY_SINCH_KEY) ?? ""
    }
    
    func setSinchKey(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_SINCH_KEY)
        userDefaults.synchronize()
    }
    
    func getSinchAppSecret() -> String {
        return UserDefaults.standard.string(forKey: KEY_SINCH_APP_SECRET) ?? ""
    }
    
    func setSinchAppSecret(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_SINCH_APP_SECRET)
        userDefaults.synchronize()
    }
    
    func getSinchEnvironment() -> String {
        return UserDefaults.standard.string(forKey: KEY_SINCH_ENVIRONMENT) ?? ""
    }
    
    func setSinchEnvironment(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_SINCH_ENVIRONMENT)
        userDefaults.synchronize()
    }
    
    func getContactEmail() -> String {
        return UserDefaults.standard.string(forKey: KEY_CONTACT_MAIL) ?? ""
    }
    
    func setContactEmail(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_CONTACT_MAIL)
        userDefaults.synchronize()
    }
    
    func isUserLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: KEY_IS_USER_LOGGED_IN)
    }
    
    func setIsUserLoggedIn(_ value: Bool) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_IS_USER_LOGGED_IN)
        userDefaults.synchronize()
    }
    
    func getDeviceToken() -> String {
        return UserDefaults.standard.string(forKey: KEY_DEVICE_TOKEN) ?? ""
    }
    
    func setDeviceToken(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_DEVICE_TOKEN)
        userDefaults.synchronize()
    }
    
    func getUserID() -> String {
        return UserDefaults.standard.string(forKey: KEY_USER_ID) ?? ""
    }
    
    func setUserID(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_USER_ID)
        userDefaults.synchronize()
    }
    
    func getUserPass() -> String {
        return UserDefaults.standard.string(forKey: KEY_USER_PASS) ?? ""
    }
    
    func setUserPass(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_USER_PASS)
        userDefaults.synchronize()
    }
    
    func getChannelName() -> String {
        return UserDefaults.standard.string(forKey: KEY_CHANNEL_NAME) ?? ""
    }
    
    func setChannelName(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_CHANNEL_NAME)
        userDefaults.synchronize()
    }
    
    func getChannelID() -> String {
        return UserDefaults.standard.string(forKey: KEY_CHANNEL_ID) ?? ""
    }
    
    func setChannelID(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_CHANNEL_ID)
        userDefaults.synchronize()
    }
    
    func getUserName() -> String {
        return UserDefaults.standard.string(forKey: KEY_USER_NAME) ?? ""
    }
    
    func setUserName(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_USER_NAME)
        userDefaults.synchronize()
    }
    
    func setUserLastName(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_USER_LAST_NAME)
        userDefaults.synchronize()
    }
    
    func getUserLastName() -> String {
        return UserDefaults.standard.string(forKey: KEY_USER_LAST_NAME) ?? ""
    }
    
    func getUserEmail() -> String {
        return UserDefaults.standard.string(forKey: KEY_USER_EMAIL) ?? ""
    }
    
    func setUserEmail(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_USER_EMAIL)
        userDefaults.synchronize()
    }
    
    func getUserPhone() -> String {
        return UserDefaults.standard.string(forKey: KEY_USER_PHONE) ?? ""
    }
    
    func setUserPhone(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_USER_PHONE)
        userDefaults.synchronize()
    }
    
    func getUserImagePath() -> String {
        return UserDefaults.standard.string(forKey: KEY_USER_IMAGE) ?? ""
    }
    
    func setUserImagePath(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_USER_IMAGE)
        userDefaults.synchronize()
    }
    
    func getAdbCheck() -> String {
        return UserDefaults.standard.string(forKey: KEY_ADB_CHECK) ?? ""
    }
    
    func setAdbCheck(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_ADB_CHECK)
        userDefaults.synchronize()
    }
    
    func getSpeedTestServerID() -> Int {
        return UserDefaults.standard.integer(forKey: KEY_SPEED_TEST_SERVER_ID)
    }
    
    func setSpeedTestServerID(_ value: Int) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_SPEED_TEST_SERVER_ID)
        userDefaults.synchronize()
    }
    
    func getVideoResolutionIndex() -> Int {
        return UserDefaults.standard.integer(forKey: KEY_VIDEO_RESOLUTION_INDEX)
    }
    
    func setVideoResolutionIndex(_ value: Int) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_VIDEO_RESOLUTION_INDEX)
        userDefaults.synchronize()
        
        switch value {
        case 0:
            LarixSettings.sharedInstance.resolution = CMVideoDimensions(width: 640, height: 360)
            LarixSettings.sharedInstance.audioBitrate = 64
            LarixSettings.sharedInstance.fps = 25
        case 1:
            LarixSettings.sharedInstance.resolution = CMVideoDimensions(width: 854, height: 480)
            LarixSettings.sharedInstance.audioBitrate = 96
            LarixSettings.sharedInstance.fps = 25
        case 2:
            LarixSettings.sharedInstance.resolution = CMVideoDimensions(width: 1280, height: 720)
            LarixSettings.sharedInstance.audioBitrate = 96
            LarixSettings.sharedInstance.fps = 50
        case 3:
            LarixSettings.sharedInstance.resolution = CMVideoDimensions(width: 1920, height: 1080)
            LarixSettings.sharedInstance.audioBitrate = 128
            LarixSettings.sharedInstance.fps = 50
        default:
            break
        }
    }
    
    func isVideoResolutionSuggested() -> Bool {
        return UserDefaults.standard.bool(forKey: KEY_VIDEO_RESOLUTION_SUGGESTED)
    }
    
    func setVideoResolutionSuggested(_ value: Bool) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_VIDEO_RESOLUTION_SUGGESTED)
        userDefaults.synchronize()
    }
    
    func getVideoCodec() -> String {
        return UserDefaults.standard.string(forKey: KEY_VIDEO_CODEC) ?? ""
    }
    
    func setVideoCodec(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_VIDEO_CODEC)
        userDefaults.synchronize()
    }

    func getEventName() -> String {
        return UserDefaults.standard.string(forKey: KEY_EVENT_NAME) ?? ""
    }
    
    func setEventName(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_EVENT_NAME)
        userDefaults.synchronize()
    }
    
    func getEventDescription() -> String {
        return UserDefaults.standard.string(forKey: KEY_EVENT_DESCRIPTION) ?? ""
    }
    
    func setEventDescription(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_EVENT_DESCRIPTION)
        userDefaults.synchronize()
    }

    func getCity() -> String {
        return UserDefaults.standard.string(forKey: KEY_CITY) ?? ""
    }
    
    func setCity(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_CITY)
        userDefaults.synchronize()
    }
    
    func getUploadService() -> String {
        return UserDefaults.standard.string(forKey: KEY_UPLOAD_SERVICE) ?? ""
    }
    
    func setUploadService(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_UPLOAD_SERVICE)
        userDefaults.synchronize()
    }
    
    func getS3ID() -> String {
        return UserDefaults.standard.string(forKey: KEY_S3_ID) ?? ""
    }
    
    func setS3ID(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_S3_ID)
        userDefaults.synchronize()
    }
    
    func getS3Key() -> String {
        return UserDefaults.standard.string(forKey: KEY_S3_KEY) ?? ""
    }
    
    func setS3Key(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_S3_KEY)
        userDefaults.synchronize()
    }
    
    func getS3Host() -> String {
        return UserDefaults.standard.string(forKey: KEY_S3_HOST) ?? ""
    }
    
    func setS3Host(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_S3_HOST)
        userDefaults.synchronize()
    }
    
    func getFtpIp() -> String {
        return UserDefaults.standard.string(forKey: KEY_FTP_IP) ?? ""
    }
    
    func setFtpIp(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_FTP_IP)
        userDefaults.synchronize()
    }
    
    func getFtpPort() -> String {
        return UserDefaults.standard.string(forKey: KEY_FTP_PORT) ?? ""
    }
    
    func setFtpPort(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_FTP_PORT)
        userDefaults.synchronize()
    }
    
    func getFtpUser() -> String {
        return UserDefaults.standard.string(forKey: KEY_FTP_USER) ?? ""
    }
    
    func setFtpUser(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_FTP_USER)
        userDefaults.synchronize()
    }
    
    func getFtpPwd() -> String {
        return UserDefaults.standard.string(forKey: KEY_FTP_PWD) ?? ""
    }
    
    func setFtpPwd(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_FTP_PWD)
        userDefaults.synchronize()
    }
    
    func getWatermarkLogo() -> String {
        return UserDefaults.standard.string(forKey: KEY_WATERMARK_LOGO) ?? ""
    }
    
    func setWatermarkLogo(_ value: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_WATERMARK_LOGO)
        userDefaults.synchronize()
    }
    
    func getWatermarkStatus() -> Int {
        return UserDefaults.standard.integer(forKey: KEY_WATERMARK_STATUS)
    }
    
    func setWatermarkStatus(_ value: Int) {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(value, forKey: KEY_WATERMARK_STATUS)
        userDefaults.synchronize()
    }
}
