//
//  VideoResolutionList.swift
//  IQConnect
//
//  Created by SuperDev on 11.01.2021.
//

import UIKit

@objc class VideoResolutionList: NSObject, Serializable {
    enum VideoResolutionListKeys: String, CodingKey {
        case video
        
        static func allKeys() -> [VideoResolutionListKeys] {
            return [
                video
            ]
        }
    }
    
    func serializableProperties() -> [String] {
        return VideoResolutionListKeys.allKeys().map { $0.rawValue }
    }
    
    func valueForKey(key: String) -> Any? {
        return self.value(forKey: key)
    }
    
    @objc var videos = [VideoResolution]()
    
    init?(dictionary: [String : Any]) {
        super.init()
        
        if let videosArray = dictionary[VideoResolutionListKeys.video.rawValue] as? [[String : Any]] {
            for videoDict in videosArray {
                if let videoResolution = VideoResolution(dictionary: videoDict) {
                    self.videos.append(videoResolution)
                }
            }
        }
    }
    
    internal override init() {
        
    }
}
