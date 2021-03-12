//
//  VideoResolution.swift
//  IQConnect
//
//  Created by SuperDev on 11.01.2021.
//

import UIKit
import SwiftyJSON

@objc class VideoResolution: NSObject, Serializable {
    enum VideoResolutionKeys: String, CodingKey {
        case pixel
        case upload_speed_min
        case upload_speed_max
        case FPS
        case width
        case height
        case video_bitrate
        case audio_bitrate
        case key_frame_interval
        case img_link
        
        static func allKeys() -> [VideoResolutionKeys] {
            return [
                pixel,
                upload_speed_min,
                upload_speed_max,
                FPS,
                width,
                height,
                video_bitrate,
                audio_bitrate,
                key_frame_interval,
                img_link
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return VideoResolutionKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var pixel: String?
    @objc var upload_speed_min: Int = 0
    @objc var upload_speed_max: Int = 0
    @objc var FPS: Int = 0
    @objc var width: Int = 0
    @objc var height: Int = 0
    @objc var video_bitrate: Int = 0
    @objc var audio_bitrate: Int = 0
    @objc var key_frame_interval: Int = 0
    @objc var img_link: String?
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        let json = JSON(dictionary)
        
        self.pixel = json[VideoResolutionKeys.pixel.rawValue].string
        self.upload_speed_min = json[VideoResolutionKeys.upload_speed_min.rawValue].intValue
        self.upload_speed_max = json[VideoResolutionKeys.upload_speed_max.rawValue].intValue
        self.FPS = json[VideoResolutionKeys.FPS.rawValue].intValue
        self.width = json[VideoResolutionKeys.width.rawValue].intValue
        self.height = json[VideoResolutionKeys.height.rawValue].intValue
        self.video_bitrate = json[VideoResolutionKeys.video_bitrate.rawValue].intValue
        self.audio_bitrate = json[VideoResolutionKeys.audio_bitrate.rawValue].intValue
        self.key_frame_interval = json[VideoResolutionKeys.key_frame_interval.rawValue].intValue
        self.img_link = json[VideoResolutionKeys.img_link.rawValue].string
    }
    
    internal override init() {
        
    }
}
