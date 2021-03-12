import Foundation
import UIKit

private class ImportedSettingsInfo {
    var connections: Int = 0
    var updatedConnections: Int = 0
    var hasVideo: Bool = false
    var hasAudio: Bool = false
    var hasRecord: Bool = false
    var deletedRecords: Int = 0
    var importErrors: [Int: String] = [:]

    var isEmpty: Bool {
        return connections == 0 && !hasVideo && !hasAudio && !hasRecord && importErrors.isEmpty
    }
}

class DeepLink: LarixSettingsKeys {
    static var sharedInstance = DeepLink()

    private var parsedLink: NSMutableDictionary?
    private var parsedSettingsInfo: ImportedSettingsInfo?
    private var importedSettingsInfo: ImportedSettingsInfo?
    private let VIDEO_ERROR_INDEX:Int = -1
    private let AUDIO_ERROR_INDEX:Int = -2
    private let RECORD_ERROR_INDEX:Int = -3

    private let AUDIO_PLIST = "Settings.bundle/Audio"
    private let VIDEO_PLIST = "Settings.bundle/Video"

    private let CONFIG_STREAMER_MODES_MAP: [String: ConnectionMode] =
        ["av": .videoAudio, "v": .videoOnly, "a": .audioOnly]
    
    
    private let CONFIG_AUTH_MODES_MAP: [String:ConnectionAuthMode] =
        ["lime": .llnw,
         "peri": .periscope,
         "rtmp": .rtmp,
         "aka": .akamai ]
    
    private let CONFIGH_AUTH_REQURE_PASS:[ConnectionAuthMode] = [.llnw, .rtmp, .akamai]
    
    private let CONFIG_VIDEO_FORMAT_MAP: [String:String] =
        ["avc": "h264", "hevc": "hevc"]

    private let CONFIG_CAMERA_LOCATION_MAP: [String: String] =
        ["0": "back", "1": "front"]

    private let CONFIG_RIST_PROFILE_MAP: [String: Int32] =
        ["s": 0, "m": 1, "a": 2, "simple": 0, "main": 1, "advanced": 2]

    private let CONFIG_SRT_MODES_MAP: [String: Int32] =
        ["c": 0, "l": 1, "r": 2, "caller": 0, "listen": 1, "rendezvous": 2]
    

    private let CONFIG_MULTI_CAM_MODE: [String: String] =
        ["off": "off", "pip":"pip", "sbs": "sideBySide"]
    
    private let CONFIG_VIDEO_ORIENTATIONS = ["landscape", "portrait"]

    private let CONFIG_ABR_MODES = ["0", "1", "2", "3"]

    private let CONFIG_RECORD_STORAGE: [String: String] =
        ["local":"local", "photo_library": "photoLibrary", "cloud": "iCloud"]

    private let CONFIG_BACK_LENS: [String: String]

    private let wrongValueError = NSLocalizedString("Wrong value for parameter \"%@\" ", comment: "")
    
    override init() {
        parsedLink = nil
        if #available(iOS 13.0, *) {
            CONFIG_BACK_LENS = [
               "wide":         AVCaptureDevice.DeviceType.builtInWideAngleCamera.rawValue,
                "ultrawide":   AVCaptureDevice.DeviceType.builtInUltraWideCamera.rawValue,
                "tele":        AVCaptureDevice.DeviceType.builtInTelephotoCamera.rawValue
           ]
        } else if #available(iOS 10.0, *) {
            CONFIG_BACK_LENS = [
               "wide":         AVCaptureDevice.DeviceType.builtInWideAngleCamera.rawValue,
                "tele":        AVCaptureDevice.DeviceType.builtInTelephotoCamera.rawValue
           ]
        } else {
            CONFIG_BACK_LENS = [:]
        }
    }
    
    public func isDeepLinkUrl(_ request: URL?) ->Bool {
        guard let url = request else {return false}
        if url.scheme != "larix" || url.host == nil  {
            return false
        }
        let path = (url.host ?? "") + url.path
        return path.starts(with: "set/v1")
    }
    
    func parseDeepLink(request: URL) {
        guard let query = request.query else { return }
        let params:NSMutableDictionary = [:]
        let paramsArray = query.split(separator: "&")
        for param in paramsArray {
            let pair = param.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
            if pair.count < 2 {continue}
            let key = String(pair[0]).removingPercentEncoding ?? ""
            let value = String(pair[1]).removingPercentEncoding ?? ""
            let matches = splitParamName(key)
            _ = parseParameter(data: params, keys: matches, keyIndex: 0, value: NSString(string: value))
        }
        parsedLink = params
        parsedSettingsInfo = getSettingsInfo(params)
    }
    
    func hasParsedData() -> Bool {
        return !(parsedSettingsInfo?.isEmpty ?? true)
    }
    
    func clear() {
        parsedLink = nil
        parsedSettingsInfo = nil
        importedSettingsInfo = nil
    }
    
    public func getImportConfirmationBody() -> NSAttributedString {
        guard let info = parsedSettingsInfo, !info.isEmpty else {return NSAttributedString(string: "")}
        let attrRedColor = [NSAttributedString.Key.foregroundColor: UIColor.red]
        let attrBoldText = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)]
        let headerMessage = NSLocalizedString("Do you want to import following settings from the link?", comment: "")
        let messageAttr = NSMutableAttributedString(string: headerMessage, attributes: attrBoldText)
        if info.deletedRecords > 0 {
            let removemessage = String.localizedStringWithFormat(NSLocalizedString("\nRemove %d existing connections", comment: ""), info.deletedRecords)
            let removeAttr = NSAttributedString(string: removemessage, attributes: attrRedColor)
            messageAttr.append(removeAttr)
        }
        var message = ""
        if (info.connections > 0) {
            let updateCount = info.deletedRecords > 0 ? 0 : getExisingConnCount()
            if updateCount > 0 {
                let newCount = info.connections - updateCount
                if newCount > 0 {
                    message += "\n" + String.localizedStringWithFormat(NSLocalizedString("Connections (%d new, %d updated)", comment: ""), newCount, updateCount)
                } else {
                    message += "\n" + String.localizedStringWithFormat(NSLocalizedString("Connections (%d updated)", comment: ""), updateCount)
                }
            } else {
                message += "\n" + String.localizedStringWithFormat(NSLocalizedString("Connections (%d new)", comment: ""), info.connections)
            }
        }
        if (info.hasVideo) {
            message += "\n" + NSLocalizedString("Video", comment: "")
        }
        if (info.hasAudio) {
            message += "\n" + NSLocalizedString("Audio", comment: "")
        }
        if (info.hasRecord) {
            message += "\n" + NSLocalizedString("Record", comment: "")
        }
        let msgBody = NSAttributedString(string: message)
        messageAttr.append(msgBody)
        return messageAttr
    }
    
    func getExisingConnCount() -> Int {
        var count: Int? = 0
        if let connections = parsedLink?.object(forKey: "conn") as? NSArray {
            var connNames: [String] = [ ]
            for connection in connections {
                guard let conn = connection as? NSDictionary,
                      let name = conn.object(forKey: "name") as? String,
                      let overwrite = conn.object(forKey: "overwrite") as? String else { continue }
                if overwrite == "on" || overwrite == "1" {
                    connNames.append("'"+name+"'")
                }
            }
            if connNames.isEmpty {
                return 0
            }
            let paramNames = "(" + connNames.joined(separator: ",") + ")"
            count = dbQueue.read { db in
                try? Connection.filter(sql: "name in \(paramNames)").fetchCount(db)
            }
        }
        
        return count ?? 0
    }
    
    func importSettings() {
        importedSettingsInfo = ImportedSettingsInfo()
        guard let parsedLink = self.parsedLink else { return }

        if let deleteConn = parsedLink.object(forKey: "deleteConn") as? NSString {
            if deleteConn != "0" && deleteConn != "off" {
                importedSettingsInfo?.deletedRecords = deleteConnections()
            }
        }

        if let connections = parsedLink.object(forKey: "conn") as? NSArray {
            var activeCount = 0
            dbQueue.read { db in
                try! activeCount = Connection.filter(sql: "active=?", arguments: ["1"]).fetchCount(db)
            }
            if (connections.count > 0 && activeCount > 0) {
                //Set existing connections inactive
                try! dbQueue.write { db in
                    try db.execute(sql: "UPDATE connection SET active = 0")
                }
            }
            importedSettingsInfo!.connections = importConnections(connections)
        }
        if let encoidngSettings = parsedLink.object(forKey: "enc") as? NSDictionary {
            if let videoSettings = encoidngSettings.object(forKey: "vid") as? NSDictionary {
                importedSettingsInfo!.hasVideo = importVideoSettings(videoSettings)
            }
            if let audioSettings = encoidngSettings.object(forKey: "aud") as? NSDictionary {
                importedSettingsInfo!.hasAudio = importAudioSettings(audioSettings)
            }
            if let recordSettings = encoidngSettings.object(forKey: "record") as? NSDictionary {
                importedSettingsInfo!.hasRecord = importRecordSettings(recordSettings)
            }
        }
    }

    public func getImportConnectionCount() -> Int {
        return (importedSettingsInfo?.connections ?? 0) + (importedSettingsInfo?.deletedRecords ?? 0)
    }
    
    public func getImportResultBody() -> String {
        var import_status = ""
        guard let info = importedSettingsInfo, !info.isEmpty else { return "" }
        var avStatus = ""
        var settingsList: [String] = []
        if info.hasAudio {
            settingsList.append("audio")
        }
        if info.hasVideo {
            settingsList.append("video")
        }
        if info.hasRecord {
            settingsList.append("record")
        }
        avStatus = settingsList.joined(separator: ",") + " settings"

        if info.deletedRecords > 0 {
            import_status += String.localizedStringWithFormat(NSLocalizedString("Removed %d existing connections\n", comment: ""), info.deletedRecords)
        }
        if (info.connections > 0 || !info.importErrors.isEmpty) {
            var connString = String.localizedStringWithFormat(NSLocalizedString("Imported %d new connection(s)", comment: ""), info.connections)
            if info.updatedConnections > 0 && info.updatedConnections == info.connections {
                connString = String.localizedStringWithFormat(NSLocalizedString("Imported %d updated connection(s)", comment: ""), info.connections)
            } else if info.updatedConnections > 0  {
                let newCount = info.connections - info.updatedConnections
                connString = String.localizedStringWithFormat(NSLocalizedString("Imported %d connection(s) (%d new, %d updated)", comment: ""),
                                                              info.connections, newCount, info.updatedConnections)
            }
            if !settingsList.isEmpty {
                import_status += String.localizedStringWithFormat(NSLocalizedString("%@ and %@.", comment: ""),connString, avStatus)
            } else {
                import_status += connString + "."
            }
        } else {
            import_status += String.localizedStringWithFormat(NSLocalizedString("Imported %@.", comment: ""), avStatus)
        }
        let importErrors = info.importErrors
        if !importErrors.isEmpty {
            let keys = importErrors.keys.sorted()
            var errors = ""
            for index in keys {
                guard let err = importErrors[index] else { continue }
                if index == AUDIO_ERROR_INDEX {
                    errors +=  String.localizedStringWithFormat(NSLocalizedString("Audio: %@\n", comment: ""), err)
                } else if index == VIDEO_ERROR_INDEX {
                    errors +=  String.localizedStringWithFormat(NSLocalizedString("Video: %@\n", comment: ""), err)
                } else if index == RECORD_ERROR_INDEX {
                    errors +=  String.localizedStringWithFormat(NSLocalizedString("Record: %@\n", comment: ""), err)
                } else {
                    errors += String.localizedStringWithFormat(NSLocalizedString("Connection %d: %@\n", comment: ""), index, err)
                }
            }
            import_status += String.localizedStringWithFormat(NSLocalizedString("\nThere were following errors:\n%@", comment: ""), errors)
        }
        importedSettingsInfo = nil
        return import_status
    }
    
    private func deleteConnections() -> Int {
        var deleteCount = 0
        do {
            deleteCount = try dbQueue.write { db in
                try Connection.deleteAll(db)
            }
        } catch {
            NSLog("Save failed")
        }
        return deleteCount
    }

    
    private func importConnections(_ connections: NSArray) -> Int {
        var importedCount = 0
        var activeCount = 0
        for i in 0..<connections.count {
            guard let conn = connections[i] as? NSDictionary else {
                importedSettingsInfo?.importErrors[i] = NSLocalizedString("Unable to parse parameters", comment: "")
                continue
                
            }
            let urlStr = String(conn.object(forKey: "url") as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let url = URL(string: urlStr) else {
                importedSettingsInfo?.importErrors[i] = NSLocalizedString("Please enter connection URL, for example: rtmp://192.168.1.1:1935/live/stream.", comment: "")
                continue
            }
            let validUri = ConnectionUri(url: url)
            if let errorMsg = validUri.message {
                importedSettingsInfo?.importErrors[i] = errorMsg
                continue
            }
            var name = conn.object(forKey: "name") as? String ?? ""

            let strMode = conn.object(forKey: "mode") as? String ?? ""
            
            var active = activeCount < 3
            let activeStr = conn.object(forKey: "active") as? String ?? ""
            if !activeStr.isEmpty {
                active = activeCount < 3 && (activeStr != "off" && activeStr != "0")
            }
            let mode = CONFIG_STREAMER_MODES_MAP[strMode] ?? .videoAudio
            var newRecord: Connection?
            var insertRecord = true
            let overwrite = conn.object(forKey: "overwrite") as? String ?? "off"
            if !name.isEmpty && !overwrite.isEmpty && overwrite != "0" && overwrite != "off" {
                let found = dbQueue.read { db in
                    try? Connection.filter(sql: "name=?", arguments: [name]) .fetchOne(db)
                }
                if found != nil {
                    insertRecord = false
                    newRecord = found!
                    newRecord?.url = urlStr
                    newRecord?.mode = mode.rawValue
                    newRecord?.active = active
                }
            } else {
                if name.isEmpty {
                    let now = Date()
                    let df = DateFormatter()
                    df.dateFormat = "yyyyMMdd-HHmmss"
                    name = df.string(from: now)
                }
                name = validateConnectionName(name.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            //For rewrite get values for existing values to made possible to update just login/pass
            var username = conn.object(forKey: "user") as? String ?? (newRecord?.username ?? "")
            var password = conn.object(forKey: "pass") as? String ?? (newRecord?.password ?? "")
            let target = conn.value(forKey: "target") as? String ?? ""
            var authMode = CONFIG_AUTH_MODES_MAP[target] ?? ConnectionAuthMode(rawValue: newRecord?.auth ?? 0) ?? .default

            if !username.isEmpty && !password.isEmpty  {
                if validUri.isRtmp {
                    if !CONFIGH_AUTH_REQURE_PASS.contains(authMode) {
                        importedSettingsInfo?.importErrors[i] = NSLocalizedString("Unsupported target type for RTMP auth", comment: "")
                        continue
                    }
                } else {
                    authMode = ConnectionAuthMode.default
                    if !validUri.isRtsp {
                        importedSettingsInfo?.importErrors[i] = NSLocalizedString("User/pass authenticaton is not supported", comment: "")
                        continue
                    }
                }
            } else {
                username = ""
                password = ""
                if validUri.isRtmp {
                    if CONFIGH_AUTH_REQURE_PASS.contains(authMode) {
                        importedSettingsInfo?.importErrors[i] = NSLocalizedString("Please provide user/pass", comment: "")
                        continue
                    }
                } else {
                    authMode = ConnectionAuthMode.default
                }
            }
            
            if newRecord == nil {
                newRecord = Connection(name: name, url: urlStr, mode: mode, active: active)
            }
            guard let record = newRecord else { continue }
            
            if !username.isEmpty {
                record.username = username
            }
            if !password.isEmpty {
                record.password = password
            }
            record.auth = authMode.rawValue

            if validUri.isSrt {
                if let latency = conn.value(forKey: "srtlatency") as? String {
                    record.latency = Int32(latency) ?? 2000
                }
                if let maxbw = conn.value(forKey: "srtmaxbw") as? String {
                    record.maxbw = Int32(maxbw) ?? 0
                }
                if let streamid = conn.value(forKey: "srtstreamid") as? String {
                    record.streamid = streamid
                }

                if let passphrase = conn.value(forKey: "srtpass") as? String {
                    record.passphrase = String(passphrase)
                }
                if let pbkeylen = conn.value(forKey: "srtpbkl") as? String {
                    let len = Int32(pbkeylen) ?? 16
                    if (len == 16 || len == 24 || len == 32) {
                        record.pbkeylen = len
                    }
                }
                if let mode = conn.value(forKey: "srtmode") as? String, let modeInt = CONFIG_SRT_MODES_MAP[mode] {
                    record.srtConnectMode = modeInt
                }
                
            } else {
                record.latency = 0
                record.maxbw = 0
                record.streamid = nil
                record.passphrase = nil
                record.pbkeylen = 16
            }
            
            if validUri.isRist {
                if let profile = conn.value(forKey: "ristProfile") as? String,
                   let profileVal = CONFIG_RIST_PROFILE_MAP[profile] {
                    record.rist_profile = profileVal
                }
            } else {
                record.rist_profile = 0
            }

            do {
                try dbQueue.write { db in
                    if insertRecord {
                        try record.insert(db)
                    } else {
                        try record.save(db)
                        importedSettingsInfo?.updatedConnections += 1
                    }
                    importedCount += 1
                    if record.active {
                        activeCount += 1
                    }
                }
            } catch {
                NSLog("Save failed")
            }

        }
        return importedCount
    }
    
    private func importVideoSettings(_ video: NSDictionary) ->Bool {
        var preferenceChanged = false
        guard let path = Bundle.main.path(forResource: VIDEO_PLIST, ofType: "plist"),
              let videoPlist = NSDictionary(contentsOfFile: path) else { return false }
        var videoErrors = ""
        
        if let res = video.value(forKey: "res") as? NSString {
            var resParsed = false
            let s = String(res)
            let dimensions = s.split(separator: "x")
            if dimensions.count == 2 {
                let w = Int32(String(dimensions[0])) ?? 0
                let h = Int32(String(dimensions[1])) ?? 0
                for (key, res) in VideoResolutions {
                    if res.width == w && res.height == h {
                        UserDefaults.standard.set(String(key), forKey: video_resolution_key)
                        preferenceChanged = true
                        resParsed = true
                        break
                    }
                }
            }
            if !resParsed {
                videoErrors += String.localizedStringWithFormat(wrongValueError, "res")
            }
        }
        if let cameraId = video.object(forKey: "camera") as? NSString {
            if let camera = CONFIG_CAMERA_LOCATION_MAP[String(cameraId)] {
                UserDefaults.standard.set(camera, forKey: camera_location_key)
                preferenceChanged = true
            }
        }
        if let backLens = video.object(forKey: "backLens") as? String {
            let lens = CONFIG_BACK_LENS[backLens] ?? "auto"
            UserDefaults.standard.set(lens, forKey: camera_type_key)
        }
        if let fps = video.object(forKey: "fps") as? NSString {
            if setValue(String(fps), forKey: video_framerate_key, ifPresentIn: videoPlist) {
                preferenceChanged = true
            } else {
                videoErrors += String.localizedStringWithFormat(wrongValueError, "fps")
            }
        }
        
        if let bitrate = video.object(forKey: "bitrate") as? NSString {
            if setNearestValue(String(bitrate), forKey: video_bitrate_key, ifPresentIn: videoPlist) {
                preferenceChanged = true
            } else {
                videoErrors += String.localizedStringWithFormat(wrongValueError, "bitrate")
            }
        }
        if let keyframeInterval = video.object(forKey: "keyframe") as? NSString {
            if setNearestValue(String(keyframeInterval), forKey: video_keyframe_key, ifPresentIn: videoPlist) {
                preferenceChanged = true
            } else {
                videoErrors += String.localizedStringWithFormat(wrongValueError, "keyframe")
            }
        }
  
        if let format = video.object(forKey: "format") as? NSString {
            if let codec = CONFIG_VIDEO_FORMAT_MAP[String(format)] {
                UserDefaults.standard.set(codec, forKey: video_codec_type_key)
                preferenceChanged = true
            } else {
                videoErrors += String.localizedStringWithFormat(wrongValueError, "format")
            }
        }
        
        if let orientation = video.object(forKey: "orientation") as? String {
            if CONFIG_VIDEO_ORIENTATIONS.contains(orientation) {
                UserDefaults.standard.set(orientation, forKey: video_orientation_key)
                preferenceChanged = true
            } else {
                videoErrors += String.localizedStringWithFormat(wrongValueError, "orientation")
            }
        }
        
        if let rotation = video.object(forKey: "liveRotation") as? String {
            switch rotation {
            case "off":
                UserDefaults.standard.set(false, forKey: core_image_key)
                UserDefaults.standard.set("off", forKey: live_rotation_key)
                preferenceChanged = true
            case "lock":
                UserDefaults.standard.set(true, forKey: core_image_key)
                UserDefaults.standard.set("off", forKey: live_rotation_key)
                preferenceChanged = true
            case "on", "follow":
                UserDefaults.standard.set(true, forKey: core_image_key)
                UserDefaults.standard.set("on", forKey: live_rotation_key)
                preferenceChanged = true
            default:
                videoErrors += String.localizedStringWithFormat(wrongValueError, "liveRotation")
            }
        }

        if let multi_cam = video.object(forKey: "multiCam") as? String {
            if let multi_cam_mode = CONFIG_MULTI_CAM_MODE[multi_cam] {
                UserDefaults.standard.set(multi_cam_mode, forKey: multi_cam_key)
                preferenceChanged = true
            } else {
                videoErrors += String.localizedStringWithFormat(wrongValueError, "multiCam")
            }
        }

        if let abr_mode = video.object(forKey: "adaptiveBitrate") as? String {
            if CONFIG_ABR_MODES.contains(abr_mode) {
                UserDefaults.standard.set(abr_mode, forKey: abr_mode_key)
                preferenceChanged = true
            }  else {
                videoErrors += String.localizedStringWithFormat(wrongValueError, "adaptiveBitrate")
            }
        }
        if let adaptive_fps = video.object(forKey: "adaptiveFps") as? String {
            switch adaptive_fps {
            case "off", "0":
                UserDefaults.standard.set(false, forKey: adaptive_fps_key)
                preferenceChanged = true
            case "on", "1":
                UserDefaults.standard.set(true, forKey: adaptive_fps_key)
                preferenceChanged = true
            default:
                videoErrors += String.localizedStringWithFormat(wrongValueError, "liveRotation")
            }
        }
        
        if !videoErrors.isEmpty {
            importedSettingsInfo?.importErrors[VIDEO_ERROR_INDEX] = videoErrors
        }
        return preferenceChanged
    }

    private func importAudioSettings(_ audio: NSDictionary) -> Bool {
        var preferenceChanged = false
        var audioErrors = ""
        guard let path = Bundle.main.path(forResource: AUDIO_PLIST, ofType: "plist"),
              let audioPlist = NSDictionary(contentsOfFile: path) else { return false }
        
        if let bitrate = audio.object(forKey: "bitrate") as? NSString {
            if setValue(String(bitrate), forKey: audio_bitrate_key, ifPresentIn: audioPlist) {
                preferenceChanged = true
            } else {
                audioErrors += String.localizedStringWithFormat(wrongValueError, "bitrate")
            }
        }
        if let channels = audio.object(forKey: "channels") as? NSString {
            if setValue(String(channels), forKey: audio_channels_key, ifPresentIn: audioPlist) {
                preferenceChanged = true
            } else {
                audioErrors += String.localizedStringWithFormat(wrongValueError, "channels")
            }
        }
        if let sampleRate = audio.object(forKey: "samples") as? NSString {
            if setValue(String(sampleRate), forKey: audio_samplerate_key, ifPresentIn: audioPlist) {
                preferenceChanged = true
            } else {
                audioErrors += String.localizedStringWithFormat(wrongValueError, "samples")
            }
        }
        
        if let audioOnly = audio.object(forKey: "audioOnly") as? String {
            switch audioOnly {
            case "off", "0":
                UserDefaults.standard.set(false, forKey: radio_mode)
                preferenceChanged = true
            case "on", "1":
                UserDefaults.standard.set(true, forKey: radio_mode)
                preferenceChanged = true
            default:
                audioErrors += String.localizedStringWithFormat(wrongValueError, "audioOnly")
            }
        }
        
        if !audioErrors.isEmpty {
            importedSettingsInfo?.importErrors[AUDIO_ERROR_INDEX] = audioErrors
        }

        return preferenceChanged
    }

    private func importRecordSettings(_ record: NSDictionary) -> Bool {
        var preferenceChanged = false
        var recordErrors = ""

        if let enabled = record.object(forKey: "enabled") as? String {
            switch enabled {
            case "off", "0":
                UserDefaults.standard.set(false, forKey: record_stream_key)
                preferenceChanged = true
            case "on", "1":
                UserDefaults.standard.set(true, forKey: record_stream_key)
                preferenceChanged = true
            default:
                recordErrors += String.localizedStringWithFormat(wrongValueError, "enabled")
            }
        }
        if let duration = record.object(forKey: "duration") as? String {
            let durationInt = Int(duration) ?? -1
            if durationInt >= 0 && durationInt <= 24 * 60 {
                UserDefaults.standard.set(duration, forKey: record_duration_key)
                UserDefaults.standard.set(true, forKey: record_stream_key)
                preferenceChanged = true
            } else {
                recordErrors += String.localizedStringWithFormat(wrongValueError, "duration")
            }
        }
        if let storage = record.object(forKey: "storage") as? String {
            if let storageVal = CONFIG_RECORD_STORAGE[storage] {
                UserDefaults.standard.set(true, forKey: record_stream_key)
                UserDefaults.standard.set(storageVal, forKey: record_storage_key)
                preferenceChanged = true
            } else {
                recordErrors += String.localizedStringWithFormat(wrongValueError, "storage")
            }
        }

        if !recordErrors.isEmpty {
            importedSettingsInfo?.importErrors[RECORD_ERROR_INDEX] = recordErrors
        }

        return preferenceChanged
    }
    
    private func getSettingsInfo(_ settings: NSDictionary) -> ImportedSettingsInfo {
        let info = ImportedSettingsInfo()
        let connections = settings.object(forKey: "conn") as? NSArray
        info.connections = connections?.count ?? 0

        let encoidngSettings = settings.object(forKey: "enc") as? NSDictionary
        if encoidngSettings != nil {
            let videoSettings = encoidngSettings?.object(forKey: "vid")
            info.hasVideo = videoSettings != nil
            let audioSettings = encoidngSettings?.object(forKey: "aud")
            info.hasAudio = audioSettings != nil
            let recordSettings = encoidngSettings?.object(forKey: "record")
            info.hasRecord = recordSettings != nil
        }
        if let deleteConn = settings.object(forKey: "deleteConn") as? NSString,
           deleteConn != "0" && deleteConn != "off" {
            
            let count = dbQueue.read { db in
                try! Connection.fetchCount(db)
            }
            info.deletedRecords = count
        }
        return info;
    }
    
    private func splitParamName(_ name: String) -> [Substring] {
        var result:[Substring] = []
        var lPos: String.Index?
        var rPos: String.Index?
        for i in name.indices {
            let ch = name[i]
            if ch == "[" {
                lPos = name.index(after: i)
                rPos = nil
                if result.isEmpty {
                    let sub = name.prefix(upTo: i)
                    result.append(sub)
                }
            } else if ch == "]" {
                rPos = name.index(before: i)
                if lPos != nil {
                    var sub = Substring()
                    if lPos! < rPos! {
                        sub = name[lPos!...rPos!]
                    }
                    result.append(sub)
                }
                lPos = nil
            }
        }
        if result.isEmpty {
            let s = Substring(name)
            result.append(s)
        }
        return result
    }
    
   @discardableResult private func parseParameter(data: NSObject, keys: [Substring], keyIndex: Int, value: NSString) -> NSObject? {
        if keyIndex >= keys.count {
            return value
        }
        let dict = data as? NSMutableDictionary
        let keyName = String(keys[keyIndex])
        var obj: NSObject?
        if keyName.isEmpty {
            var arr = data as? NSMutableArray
            if arr == nil {
                arr = NSMutableArray()
            }
            var createNew = true
            var last = arr?.lastObject as? NSMutableDictionary
            if keyIndex+1 < keys.count && !keys[keyIndex+1].isEmpty {
                let childName = keys[keyIndex+1]
                createNew = last == nil || last?.object(forKey: childName) != nil
            }
            if createNew {
                last = NSMutableDictionary()
                let child = parseParameter(data: last!, keys: keys, keyIndex: keyIndex+1, value: value)
                if child != nil {
                    arr!.add(child!)
                }
            } else {
                _ = parseParameter(data: last!, keys: keys, keyIndex: keyIndex+1, value: value)
            }
            return arr
        } else if dict != nil {
            obj = dict?.object(forKey: keyName) as? NSObject
            if obj == nil {
                obj = NSMutableDictionary()
                dict?.setValue(obj, forKey: keyName)
            }
            if obj != nil {
                obj = parseParameter(data: obj!, keys: keys, keyIndex: keyIndex+1, value: value)
                dict?.setValue(obj, forKey: keyName)
            }
            return dict
        }
        return nil
    }
    
    private func validateConnectionName(_ name: String) -> String {
        let numberPattern = #"\s*\d+$"#
        var sequence = -1
        var pureName = name

        let duplicates = dbQueue.read { db in
            try! Connection.filter(sql: "name like ?", arguments: [pureName+"%"]).fetchAll(db)
        }
        if duplicates.isEmpty {
            return name
        }
        for conn in duplicates {
            let connName = conn.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if connName == pureName {
                sequence = 1
            } else if let numRange = connName.range(of: numberPattern, options: .regularExpression) {
                var id: Int
                let numStr = connName[numRange]
                let prefix = connName.prefix(upTo: numRange.lowerBound)
                if (prefix != pureName) {
                    //Existing connection name don't match new name exactly
                    continue
                }
                id = Int(numStr.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                if id > sequence {
                    sequence = id
                }
            }
        }
        if sequence >= 0 {
            pureName += String(format:" %d", sequence == 0 ? 2 : sequence + 1)
        }
        return pureName
    }
    
    private func getBundleSettingValues(dict: NSDictionary, key: String) -> [String] {
        guard let prefs = dict.object(forKey: "PreferenceSpecifiers") as? NSArray else {return []}
        for item in prefs {
            guard let pref = item as? NSDictionary else {continue}
            if let name = pref.object(forKey: "Key") as? NSString, String(name) == key {
                guard let values = pref.object(forKey: "Values") as? NSArray else {continue}
                return values as? Array<String> ?? []
            }
        }
        return []
    }
    
    private func setValue(_ value: String, forKey key: String, ifPresentIn dict: NSDictionary) -> Bool {
        var set = false
        let array = getBundleSettingValues(dict: dict, key: key)
        if array.contains(String(value)) {
            UserDefaults.standard.set(value, forKey: key)
            set = true
        }
        return set
    }

    private func setNearestValue(_ value: String, forKey key: String, ifPresentIn dict: NSDictionary) -> Bool {
        var set = false
        let array = getBundleSettingValues(dict: dict, key: key)
        if array.contains(String(value)) {
            UserDefaults.standard.set(value, forKey: key)
            set = true
        } else {
            if let intVal = Int(value), var nearestVal = Int(array[0]) {
                for x in array {
                    let intX = Int(x) ?? 0
                    if abs(intX - intVal) < abs(nearestVal - intVal) {
                        nearestVal = intX
                    }
                }
                UserDefaults.standard.set(String(nearestVal), forKey: key)
                set = true
            }
        }
        return set
    }
}
