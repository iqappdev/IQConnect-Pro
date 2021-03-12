//
//  URL+Extension.swift
//  IQConnect
//
//  Created by SuperDev on 18.01.2021.
//

import UIKit

extension URL {
    func getVideoDuration() -> String {
        let asset = AVAsset(url: self)

        let duration = asset.duration
        let durationTime = Int(CMTimeGetSeconds(duration))
        let h = durationTime / 3600
        let m = (durationTime % 3600) / 60
        let s = durationTime % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}
