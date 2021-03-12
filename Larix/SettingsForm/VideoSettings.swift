import Foundation
import Eureka
import AVFoundation

class VideoSettingsViewController: BundleSettingsViewController {
    private var allResolutions: [SettingListElem] = []
    private var allFps: [SettingListElem] = []
    private var allBackCam: [SettingListElem] = []

    var multicamEnabled: Bool {
        if !isMulticamSupported() {
            return false
        }
        let val = UserDefaults.standard.string(forKey: "pref_multi_cam") ?? "off"
        return val != "off"
    }
    
    override func loadSettings() {
        guard let path = Bundle.main.path(forResource: "Settings.bundle/Root", ofType: "plist"),
              let rootPlist = NSDictionary(contentsOfFile: path),
              let prefs = rootPlist.object(forKey: "PreferenceSpecifiers") as? NSArray else {return }
        
        
        let myPrefs = prefs.filter {
            guard let item = $0 as? NSDictionary else {return false}
            let name = item["Key"] as? String
            return name == "pref_camera" || name == "pref_device_type"
        }
        
        let section = Section()
        for pref in myPrefs {
            if let item = pref as? NSDictionary {
                addSelector(item: item, section: section)
            }
        }
        
        form.append(section)
        
        super.loadSettings()
    }
    
//    override func addSelector(item: NSDictionary, section: Section) {
//        if let pref = item.object(forKey: "Key") as? String, pref == "pref_video_bitrate" {
//            addStepper(item: item, section: section)
//            return
//        }
//        super.addSelector(item: item, section: section)
//    }
    
    
    func addStepper(item: NSDictionary, section: Section) {
         let pref = "pref_video_bitrate"
        
        let value = UserDefaults.standard.string(forKey: pref) ?? "0"
        let intVal = Int(value) ?? 0
        let item = StepperRow(pref) {
            $0.title = NSLocalizedString("Bitrate (Kbps)", comment: "")
            $0.displayValueFor = { value in
                if value ?? 0 == 0 {
                    return NSLocalizedString("Match resolution", comment: "")
                }
                return String(format:"%d", Int(value ?? 0))
            }
            $0.value = Double(intVal)
            $0.cell.stepper.autorepeat = true
            $0.cell.stepper.wraps = true
            $0.cell.stepper.stepValue = 500
            $0.cell.stepper.minimumValue = 0
            $0.cell.stepper.maximumValue = 20000
        }
       
        section <<< item
    }
    
    
    override func getHideCondition(tag: String) -> Condition? {
        if tag == "pref_live_rotation" {
            return Condition.function(["pref_core_image"], { form in
                if let rotation = form.rowBy(tag: "pref_core_image") as? SwitchRow {
                    return rotation.value != true
                }
                return true
            })
        }
        if tag == "pref_avc_profile" {
            return Condition.function(["pref_video_codec_type"], { form in
                if let codec = form.rowBy(tag: "pref_video_codec_type") as? PushRow<SettingListElem> {
                    return (codec.value?.value ?? "") != "h264"
                }
                return true
            })
        }
        if tag == "pref_hevc_profile" {
            return Condition.function(["pref_video_codec_type"], { form in
                if let codec = form.rowBy(tag: "pref_video_codec_type") as? PushRow<SettingListElem> {
                    return (codec.value?.value ?? "") != "hevc"
                }
                return true
            })
        }
        if tag == "adaptive_fps" {
            return Condition.function(["abr_mode"], { form in
                if let mode = form.rowBy(tag: "abr_mode") as? PushRow<SettingListElem> {
                    return (mode.value?.value ?? "0") == "0"
                }
                return true
            })
        }
        return nil
    }
    
    override func getDisableCondition(tag: String) -> Condition? {
        if tag == "pref_core_image" {
            return Condition.function(["pref_resolution"], { _ in !LarixSettings.sharedInstance.canPostprocess } )
        }
        return nil
    }

    
    override func filterValues(_ list: [SettingListElem], forParam key: String) -> [SettingListElem] {
        if key == "pref_device_type" {
            allBackCam = list
            return getAvailableCameras(list)
        }
        if key == "pref_multi_cam" && !isMulticamSupported() {
            return []
        }
        if key == "pref_resolution" {
            allResolutions = list
            return getAvailableResolutions(list)
        }
        if key == "pref_fps" {
            allFps = list
            return getAvailableFps(list)
        }
        return list
    }
    
    func getAvailableCameras(_ list: [SettingListElem]) -> [SettingListElem] {
        var result: [SettingListElem] = []
        var devices: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInTelephotoCamera]
        if #available(iOS 13.0, *) {
            devices.append(.builtInUltraWideCamera)
        }
        let discovery = AVCaptureDevice.DiscoverySession.init(deviceTypes: devices, mediaType: .video, position: .back)
        
        for cam in discovery.devices {
            let type = cam.deviceType.rawValue
            if let elem = list.first(where: { $0.value == type }) {
                result.append(elem)
            }
        }
        if result.count > 1 {
            let title = getDefaultBackCamera()
            let autoTitle = String.localizedStringWithFormat("Auto (%@)", title)

            let auto = SettingListElem(title: NSLocalizedString(autoTitle, comment: ""), value: "Auto")
            result.insert(auto, at: 0)
        } else {
            result.removeAll()
        }
        return result
    }
    
    func getAvailableResolutions(_ list: [SettingListElem]) -> [SettingListElem] {
        let supported = getResolutions()
        let res = list.filter { supported.contains($0.value) }
        return res
    }
    
    func getAvailableFps(_ list: [SettingListElem]) -> [SettingListElem] {
        let supported = getFps(list)
        let res = list.filter { supported.contains($0.value) }
        return res
    }
    
    func getResolutions() -> Set<String> {
        let multiCam = multicamEnabled
        let fps = Float64(UserDefaults.standard.string(forKey: "pref_fps") ?? "30") ?? 30.0

        var resolutions = Set<String>()
        guard let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {return [] }
        for format in cam.formats {
            if #available(iOS 13.0, *) {
                if multiCam && format.isMultiCamSupported == false { continue }
            }
            let hasFps = format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= fps && $0.minFrameRate <= fps }
            if !hasFps { continue }
            let camRes = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            resolutions.insert(String(camRes.height))
        }
        return resolutions
    }
    
    func getFps(_ list: [SettingListElem]) -> Set<String> {
        let multiCam = multicamEnabled
        let height = Int(UserDefaults.standard.string(forKey: "pref_resolution") ?? "720") ?? 720

        var fpsList = Set<String>()
        guard let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {return [] }
        for format in cam.formats {
            if #available(iOS 13.0, *) {
                if multiCam && format.isMultiCamSupported == false { continue }
            }
            let camRes = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if camRes.height != height { continue }
            for elem in list {
                let fps = Float64(elem.value) ?? 0.0
                let hasFps = format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= fps && $0.minFrameRate <= fps }
                if hasFps {
                    fpsList.insert(elem.value)
                }
            }
            if fpsList.count == list.count {
                break //Already find all
            }
        }
        return fpsList
    }
        
    func isMulticamSupported() -> Bool {
        if #available(iOS 13.0, *) {
            return AVCaptureMultiCamSession.isMultiCamSupported 
        } else {
            return false
        }
    }
    
    func getDefaultBackCamera(probe:((AVCaptureDevice, CMVideoDimensions, Double) -> Bool)? = nil) -> String {
        var defaultType = AVCaptureDevice.DeviceType.builtInDualCamera
        var virtualCamera: AVCaptureDevice?
        var title = "Dual"
        if #available(iOS 13.0, *) {
            defaultType = AVCaptureDevice.DeviceType.builtInTripleCamera
            title = "Triple"
            virtualCamera = AVCaptureDevice.default(defaultType, for: .video, position: .back)
            if virtualCamera == nil || supportedCamera(virtualCamera!) == false {
                defaultType = AVCaptureDevice.DeviceType.builtInDualWideCamera
                title = "Dual"
            }
        }
        virtualCamera = AVCaptureDevice.default(defaultType, for: .video, position: .back)
        if virtualCamera == nil || supportedCamera(virtualCamera!) == false {
            defaultType = .builtInWideAngleCamera
            title = "Dual"
        }
        return title
    }
    
    func supportedCamera(_ camera: AVCaptureDevice) -> Bool {
        let multiCam = multicamEnabled
        let height = Int(UserDefaults.standard.string(forKey: "pref_resolution") ?? "720") ?? 720
        let fps = Float64(UserDefaults.standard.string(forKey: "pref_fps") ?? "30") ?? 30.0
        for format in camera.formats {
            if #available(iOS 13.0, *) {
                if multiCam && format.isMultiCamSupported == false { continue }
            }
            let camRes = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if camRes.height != height { continue }
            let hasFps = format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= fps && $0.minFrameRate <= fps }
            if hasFps {
                return true
            }
        }
        return false
    }
    
    override func valueHasBeenChanged(for row: BaseRow, oldValue: Any?, newValue: Any?) {
//        if row.tag == "pref_video_bitrate" {
//            let floatVal = newValue as? Float64 ?? 0.0
//            let strVal = String(Int(floatVal)) 
//           
//            UserDefaults.standard.setValue(strVal, forKey: row.tag!)
//            return
//        }
        super.valueHasBeenChanged(for: row, oldValue: oldValue, newValue: newValue)
        if row.tag == "pref_multi_cam" || row.tag == "pref_resolution" {
            guard let fps = form.rowBy(tag: "pref_fps") as? PushRow<SettingListElem>, fps.value != nil else { return }
            updateValue(row: fps, all: allFps, available: getAvailableFps(allFps))
        }
        if row.tag == "pref_multi_cam" || row.tag == "pref_fps" {
            guard let res = form.rowBy(tag: "pref_resolution") as? PushRow<SettingListElem>, res.value != nil else { return }
            updateValue(row: res, all: allResolutions, available: getAvailableResolutions(allResolutions))
        }
        
        if row.tag == "pref_multi_cam" || row.tag == "pref_fps" || row.tag == "pref_resolution" {
            guard let cam = form.rowBy(tag: "pref_device_type") as? PushRow<SettingListElem>, cam.value != nil else { return }
            let available = getAvailableCameras(allBackCam)
            updateValue(row: cam, all: allBackCam, available: available)
            if cam.value?.value == "Auto" && cam.value?.title != available[0].title {
                //Updated description for Auto
                cam.value = available[0]
                cam.updateCell()
            }
        }
        if row.tag == "pref_resolution" {
            guard let liveRotation = form.rowBy(tag: "pref_core_image") as? SwitchRow, liveRotation.value != nil else { return }
            if !LarixSettings.sharedInstance.postprocess {
                liveRotation.value = false
            }
        }
    }
    
    func updateValue(row: PushRow<SettingListElem>, all: [SettingListElem], available: [SettingListElem]) {
        if !available.contains(row.value!) {
            guard var idx = all.firstIndex(of: row.value!) else {return}
            while idx < all.count && !available.contains(all[idx]) {
                idx += 1
            }
            if idx < all.count {
                row.value = all[idx]
            } else if !available.isEmpty {
                row.value = available.last
            }
            if let setting = row.value {
                UserDefaults.standard.setValue(setting.value, forKey: row.tag!)
            }
        }
        row.options = available
    }

}
