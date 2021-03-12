//
//  LiveBroadcastVC.swift
//  IQConnect
//
//  Created by SuperDev on 11.01.2021.
//

import AVFoundation
import UIKit
import CocoaLumberjack
import GRDB
import Toaster
import Photos
import BatteryView

protocol ApplicationStateObserver: AnyObject {
    func applicationDidBecomeActive()
    func applicationWillResignActive()
    
    func mediaServicesWereLost()
    func mediaServicesWereReset()
}

class LiveBroadcastVC: UIViewController, ApplicationStateObserver, StreamerAppDelegate, CloudNotificationDelegate {
    
    
    @IBOutlet weak var Indicator: UIActivityIndicatorView!
    @IBOutlet weak var Broadcast_Button: UIButton!
    @IBOutlet weak var Settings_Button: UIButton!
    @IBOutlet weak var Resolution_Button: VKExpandableButton!
    @IBOutlet weak var Mode_Button: ASCircularMenuButton!
    @IBOutlet weak var Flip_Button: UIButton!
    @IBOutlet weak var Chat_Button: UIButton!
    @IBOutlet weak var Mute_Button: UIButton!
    @IBOutlet weak var Shoot_Button: UIButton!
    @IBOutlet weak var Flash_Button: UIButton!
    @IBOutlet weak var Shoot_Buttons_View: UIStackView!
    @IBOutlet weak var Chat_View: UIView!
    @IBOutlet weak var Reply_View: UIView!
    @IBOutlet weak var Reply_Comment_Label: UILabel!
    @IBOutlet weak var Battery_View: BatteryView!
    
    @IBOutlet weak var Time_Label: UILabel!
    @IBOutlet weak var Fps_Label: UILabel!
    @IBOutlet weak var Focus_Label: UILabel!
    
    @IBOutlet weak var Name_Label0: UILabel!
    @IBOutlet weak var Name_Label1: UILabel!
    @IBOutlet weak var Name_Label2: UILabel!
    
    @IBOutlet weak var Status_Label0: UILabel!
    @IBOutlet weak var Status_Label1: UILabel!
    @IBOutlet weak var Status_Label2: UILabel!
    
    @IBOutlet weak var Resolution_Label: UILabel!
    
    @IBOutlet weak var Message_Label: UILabel!
    @IBOutlet weak var VUMeter: AudioLevelMeter!
    
    @IBOutlet weak var Broadcasting_View: UIView!
    @IBOutlet weak var Broadcasting_View_Width_Constraint: NSLayoutConstraint!
    @IBOutlet weak var Broadcasting_Background_View: UIView!
    @IBOutlet weak var Broadcasting_Dot_View: UIView!
    @IBOutlet weak var Broadcasting_Label: UILabel!
    @IBOutlet weak var Recording_View: UIView!
    @IBOutlet weak var Recording_Dot_View: UIView!
    
    var name = [UILabel]()
    var status = [UILabel]()
    
    var alertController: UIAlertController?
    
    var streamer: Streamer?
    
    var checkStatusTimer: Timer?
    var bandWidth = ""
    var uiTimer: Timer?
    var retryTimer: Timer?
    var retryList = [Connection]()
    var restartRecording = false
    var recordDurationTImer: Timer?
    var restartBroadcasting = false
    
    var previewLayer: AVCaptureVideoPreviewLayer?       //Preview for single-cam capture
    var frontPreviewLayer: AVCaptureVideoPreviewLayer?  //Preview from front camera for multi-cam capture
    var backPreviewLayer: AVCaptureVideoPreviewLayer?   //Preview from back camera for multi-cam capture

    var canStartCapture = true
    
    var cloudUtils = CloudUtilites()
    
    class ConnectionStatistics {
        var isUdp: Bool = false
        var startTime: CFTimeInterval = CACurrentMediaTime()
        var prevTime: CFTimeInterval = CACurrentMediaTime()
        var duration: CFTimeInterval = 0
        var prevBytesSent: UInt64 = 0
        var prevBytesDelivered: UInt64 = 0
        var bps: Double = 0
        var latency: Double = 0
        var packetsLost: UInt64 = 0
    }
    
    var isBroadcasting = false
    var broadcastStartTime: CFTimeInterval = CACurrentMediaTime()
    
    var currentConnection: Connection?
    var connectionId:[Int32:Connection] = [:] // id -> Connection
    var connectionState:[Int32:ConnectionState] = [:] // id -> ConnectionState
    var connectionStatistics:[Int32:ConnectionStatistics] = [:] // id -> ConnectionStaistics
    
    let tapRec = UITapGestureRecognizer()
    let longPressRec = UILongPressGestureRecognizer()
    let pinchRec = UIPinchGestureRecognizer()
    
    var zoomFactor: CGFloat = 1
    
    var streamConditioner: StreamConditioner?
    
    var isMulticam: Bool = false
    var volumeChangeTime: CFTimeInterval = 0
    var mediaResetPending = false
    var backgroundStream = false
    
    var videoResolutions = [VideoResolution]()
    var currentVideoResolution: VideoResolution?
    
    var isShootAndSend = false
    var doubleBackToExitPressedOnce = false
    
    @IBAction func Broadcast_Click(_ sender: UIButton) {
        DDLogVerbose("Broadcast_Click")
        if streamer?.isPaused == true {
            streamer?.isPaused = false
            broadcastWillResume()
        } else if !isBroadcasting {
            startStream()
        } else {
            stopStream()
        }
    }

    @IBAction func Broadcast_LongTap(_ sender: UIButton) {
        if !isBroadcasting {
            return
        }
        if streamer?.isPaused == true {
            broadcastWillResume()
            streamer?.isPaused = false
        } else {
            broadcastWillPause()
            streamer?.isPaused = true
        }
    }
    
    @IBAction func Flip_Click(_ sender: UIButton) {
        DDLogVerbose("Flip_Click")
        Focus_Label.isHidden = true
        streamer?.changeCamera()
        adjustPipPosition()
    }
    
    @IBAction func Mute_Click(_ sender: UIButton) {
        DDLogVerbose("Mute_Click")
        isMuted = !isMuted
    }
    
    @IBAction func Shoot_Click(_ sender: UIButton) {
        DDLogVerbose("Shoot_Click")
        streamer?.captureStillImage()
    }
    
    @IBAction func Flash_Click(_ sender: Any) {
        let flashOn = streamer?.toggleFlash() ?? false
        if flashOn {
            Flash_Button.layer.backgroundColor = UIColor.white.cgColor
            Flash_Button.setImage(#imageLiteral(resourceName: "flash_on"), for: .normal)
        } else {
            Flash_Button.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor
            Flash_Button.setImage(#imageLiteral(resourceName: "flash"), for: .normal)
        }
        DDLogVerbose("Flash_Click \(flashOn)")
    }
    
    // MARK: ViewController state transition
    override func viewDidLoad() {
        super.viewDidLoad()
        // Called after init(coder:) when the view is loaded into memory, this method is also called only once during the life of the view controller object. It’s a great place to do any view initialization or setup you didn’t do in the Storyboard. Perhaps you want to add subviews or auto layout constraints programmatically – if so, this is a great place to do either of those. Note that just because the view has been loaded into memory doesn’t necessarily mean that it’s going to be displayed soon – for that, you’ll want to look at viewWillAppear. Oh, and remember to call super.viewDidLoad() in your implementation to make sure your superclass’s viewDidLoad gets a chance to do its work – I usually call super right at the beginning of the implementation.
        DDLogVerbose("viewDidLoad")
        
        configureModeButton()
        configureShootButton()
        
        Fps_Label.text = SharedManager.sharedInstance.getChannelName()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mainView = self
        
        name = [Name_Label0, Name_Label1, Name_Label2]
        status = [Status_Label0, Status_Label1, Status_Label2]
        
        makeRoundButttons()
        
        tapRec.addTarget(self, action: #selector(tappedView))
        longPressRec.addTarget(self, action: #selector(longPressedView))
        pinchRec.addTarget(self, action: #selector(pinchHandler))
        
        view.addGestureRecognizer(tapRec)
        view.addGestureRecognizer(longPressRec)
        view.addGestureRecognizer(pinchRec)
        
        getVideoResolutions()
        
        startBatteryMonitor()
    }
    
    deinit {
        AppDelegate.shared.mainView = nil
        stopBatteryMonitor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Always called after viewDidLoad (for obvious reasons, if you think about it), and just before the view appears on the screen to the user, viewWillAppear is called. This gives you a chance to do any last-minute view setup, kick off a network request (in another class, of course), or refresh the screen. Unlike viewDidLoad, viewWillAppear is called the first time the view is displayed as well as when the view is displayed again, so it can be called multiple times during the life of the view controller object. It’s called when the view is about to appear as a result of the user tapping the back button, closing a modal dialog, when the view controller’s tab is selected in a tab bar controller, or a variety of other reasons. Make sure to call super.viewWillAppear() at some point in the implementation – I generally do it first thing.
        DDLogVerbose("viewWillAppear")
        
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        cloudUtils.delegate = self
        cloudUtils.activate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // viewDidAppear is called when the view is actually visible, and can be called multiple times during the lifecycle of a View Controller (for instance, when a Modal View Controller is dismissed and the view becomes visible again). This is where you want to perform any layout actions or do any drawing in the UI - for example, presenting a modal view controller. However, anything you do here should be repeatable. It's best not to retain things here, or else you'll get memory leaks if you don't release them when the view disappears.
        DDLogVerbose("viewDidAppear")
        
        // For custom app based on larix sdk remove DeepLink condition check
        if DeepLink.sharedInstance.hasParsedData() {
            // Present import settings dialog later and then start capture
            return
        }
        
        // Handle "Back" from Settings page or first app launch
        if deviceAuthorized {
            startCapture()
        } else {
            checkForAuthorizationStatus()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Similar to viewWillAppear, this method is called just before the view disappears from the screen. And like viewWillAppear, this method can be called multiple times during the life of the view controller object. It’s called when the user navigates away from the screen – perhaps dismissing the screen, selecting another tab, tapping a button that shows a modal view, or navigating further down the navigation hierarchy. This is a great place to hide the keyboard, save state, and possibly cancel running timers or network requests. Like the other methods in the view controller lifecycle, be sure to call super at some point in viewWillDisappear.
        DDLogVerbose("viewWillDisappear")
        
        ToastCenter.default.cancelAll()
        dismissAlertController()
        
        stopStream()
        stopCapture()
        
        cloudUtils.deactivate()
        cloudUtils.delegate = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // viewDidDisappear is an optional method that your view can utilize to execute custom code when the view does indeed disappear. You aren't required to have this in your view, and your code should (almost?) never need to call it.
        DDLogVerbose("viewDidDisappear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        DDLogVerbose("didReceiveMemoryWarning")
    }
    
    // MARK: Application state transition
    func applicationDidBecomeActive() {
        // For custom app based on larix sdk remove DeepLink condition check
        if DeepLink.sharedInstance.hasParsedData() {
            presentImportDialog()
            return
        }
        let audioOnly = LarixSettings.sharedInstance.radioMode
        var needResume = true
        if backgroundStream {
            if !audioOnly {
                //Was turned off while in backround
                stopStream()
                stopCapture()
            } else {
                endBackgroundCapture()
                startRecord()
                needResume = false
            }
            backgroundStream = false
        }
        if needResume {
            resumeCapture(shouldRequestPermissions: false)
        }
    }
    
    func resumeCapture(shouldRequestPermissions: Bool) {
        if viewIfLoaded?.window != nil {
            DDLogVerbose("didBecomeActive")
            // Handle view transition from background
            if deviceAuthorized {
                startCapture()
            } else {
                if shouldRequestPermissions {
                    checkForAuthorizationStatus()
                } else {
                    // permission request already in progress and app is returning from permission request dialog
                    // capture will start on permission granted
                    DDLogVerbose("skip resumeCapture")
                }
            }
        }
    }
    
    func applicationWillResignActive() {
        dismissAlertController()
        
        if viewIfLoaded?.window != nil {
            DDLogVerbose("willResignActive")
            
            if deviceAuthorized {
                let keepStreaming = LarixSettings.sharedInstance.radioMode && !connectionId.isEmpty
                if keepStreaming {
                    setBackgroundCapture()
                    //iOS terminates app if it record stream in background
                    stopRecord()
                } else {
                    stopStream()
                    removePreview()
                    stopCapture()
                }
                ToastCenter.default.cancelAll()
            }
        }
    }
    
    // MARK: Respond to the media server crashing and restarting
    // https://developer.apple.com/library/archive/qa/qa1749/_index.html
    
    func mediaServicesWereLost() {
        if viewIfLoaded?.window != nil, deviceAuthorized {
            DDLogVerbose("mediaServicesWereLost")
            mediaResetPending = streamer?.session != nil
            stopStream()
            removePreview()
            stopCapture()
            
            Indicator.isHidden = false
            Indicator.startAnimating()
            
            hideUI()
            Settings_Button.isHidden = false
            Mode_Button.isHidden = false
            Resolution_Button.isHidden = false
            
            showStatusMessage(message: NSLocalizedString("Waiting for media services initialize.", comment: ""))
        }
    }
    
    func mediaServicesWereReset() {
        if viewIfLoaded?.window != nil, deviceAuthorized {
            DDLogVerbose("mediaServicesWereReset, pending:\(mediaResetPending)")
            if mediaResetPending {
                startCapture()
                mediaResetPending = false
            }
        }
    }
    
    // MARK: Start broadcasting
    func startBroadcast() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if !appDelegate.canConnect {
            let message = NSLocalizedString("No internet connection.", comment: "")
            Toast(text: message).show()
            return
        }
        
        broadcastWillStart()
        if LarixSettings.sharedInstance.canBroadcast {
            if let connection = currentConnection {
                createConnection(connection: connection)
                showConnectionInfo()
            }
        }
        startRecord()
        
        if LarixSettings.sharedInstance.canBroadcast {
            streamConditioner?.start(bitrate: LarixSettings.sharedInstance.videoBitrate, id: Array(connectionId.keys))
        }
    }
    
    func stopBroadcast() {
        broadcastWillStop()
        
        let ids = Array(connectionId.keys)
        for id in ids {
            releaseConnection(id: id)
        }
        stopRecord()
        
        streamConditioner?.stop()
    }
    
    // MARK: Update UI on broadcast start
    func broadcastWillStart() {
        if !isBroadcasting {
            DDLogVerbose("start broadcasting")
            
            let deviceOrientation = UIApplication.shared.statusBarOrientation
            let newOrientation = toAVCaptureVideoOrientation(deviceOrientation: deviceOrientation, defaultOrientation: AVCaptureVideoOrientation.portrait)
            streamer?.orientation = newOrientation
            
            if let stereoOrientation = AVAudioSession.StereoOrientation(rawValue: newOrientation.rawValue) {
                streamer?.stereoOrientation = stereoOrientation
            }
            broadcastStartTime = CACurrentMediaTime()
            Time_Label.isHidden = false
            Time_Label.text = "00:00:00"
            Broadcast_Button.setBackgroundImage(#imageLiteral(resourceName: "broadcast_stop"), for: .normal)
            Broadcast_Button.setTitle("STOP", for: .normal)
//            Settings_Button.isEnabled = false
            Mode_Button.isHidden = true
//            Resolution_Button.isUserInteractionEnabled = false
            
            if LarixSettings.sharedInstance.canBroadcast {
                Chat_Button.isHidden = false
                startCheckStreamStatus()
                showBroadcastingView()
                self.Broadcasting_Background_View.backgroundColor = .appButtonBlueColor
                self.Broadcasting_Label.text = "ON-QUE"
            }
            if LarixSettings.sharedInstance.record {
                showRecordingView()
            }
            
            isBroadcasting = true
        }
    }
    
    func broadcastWillStop() {
        if isBroadcasting {
            DDLogVerbose("stop broadcasting")
            
            retryTimer?.invalidate()
            retryTimer = nil
            
            retryList.removeAll()
            
            Time_Label.isHidden = true
            Time_Label.text = "00:00:00"
            Broadcast_Button.setBackgroundImage(#imageLiteral(resourceName: "broadcast_start"), for: .normal)
            Broadcast_Button.setTitle("START", for: .normal)
            Settings_Button.isEnabled = true
            Mode_Button.isHidden = false
            Resolution_Button.isUserInteractionEnabled = true
            Chat_Button.isHidden = true
            stopCheckStreamStatus()
            hideRecordingView()
            hideBroadcastingView()
            hideConnectionInfo()
            
            isBroadcasting = false
            if streamer?.isPaused == true {
                //In a case we failed while been paused
                streamer?.isPaused = false
                broadcastWillResume()
            }
        }
    }
    
    func broadcastWillPause() {
        Broadcast_Button.setBackgroundImage(#imageLiteral(resourceName: "broadcast_pause"), for: .normal)
        Broadcast_Button.setTitle("", for: .normal)
        Flip_Button.isEnabled = false
        Flash_Button.isEnabled = false
        Mute_Button.isEnabled = false
        Shoot_Button.isEnabled = false
        previewLayer?.isHidden = true
        frontPreviewLayer?.isHidden = true
        backPreviewLayer?.isHidden = true
    }

    func broadcastWillResume() {
        if isBroadcasting {
            Broadcast_Button.setBackgroundImage(#imageLiteral(resourceName: "broadcast_stop"), for: .normal)
            Broadcast_Button.setTitle("STOP", for: .normal)
        } else {
            Broadcast_Button.setBackgroundImage(#imageLiteral(resourceName: "broadcast_start"), for: .normal)
            Broadcast_Button.setTitle("START", for: .normal)
        }
        Flip_Button.isEnabled = true
        Flash_Button.isEnabled = true
        Mute_Button.isEnabled = true
        Shoot_Button.isEnabled = true
        previewLayer?.isHidden = false
        frontPreviewLayer?.isHidden = false
        backPreviewLayer?.isHidden = false
    }

    // MARK: Capture utitlies
    
    /* Note: method is called on a background thread after permission request. Move your UI update codes inside the main queue. */
    func startCapture() {
        DDLogVerbose("LiveBroadcastVC::startCapture")
        
        guard canStartCapture else {
            return
        }
        do {
            let audioOnly = LarixSettings.sharedInstance.radioMode
            canStartCapture = false
            
            removePreview()
            
            DispatchQueue.main.async {
                self.hideUI()
                self.Message_Label.isHidden = true
                self.Indicator.isHidden = false
                self.Indicator.startAnimating()
                
                UIApplication.shared.isIdleTimerDisabled = true
            }
//            if #available(iOS 13.0, *) {
//                if !audioOnly && StreamerMultiCam.isSupported() {
//                    streamer = StreamerMultiCam()
//                    isMulticam = streamer != nil
//                }
//            }
            if streamer == nil {
                streamer = StreamerSingleCam()
                isMulticam = false
            }
            streamer?.delegate = self
            if !audioOnly {
                streamer?.videoConfig = LarixSettings.sharedInstance.videoConfig
            }
            streamer?.audioConfig = LarixSettings.sharedInstance.audioConfig
            
            streamer?.uvMeter = VUMeter
            VUMeter.channels = LarixSettings.sharedInstance.audioConfig.channelCount
            
            DispatchQueue.main.async {
                let deviceOrientation = UIApplication.shared.statusBarOrientation
                let newOrientation = self.toAVCaptureVideoOrientation(deviceOrientation: deviceOrientation, defaultOrientation: AVCaptureVideoOrientation.portrait)
                if let stereoOrientation = AVAudioSession.StereoOrientation(rawValue: newOrientation.rawValue) {
                    self.streamer?.stereoOrientation = stereoOrientation
                }
            }
            
            try streamer?.startCapture(startAudio: true, startVideo: !audioOnly)
            
            let nc = NotificationCenter.default
            nc.addObserver(
                self,
                selector: #selector(orientationDidChange(notification:)),
                name: UIDevice.orientationDidChangeNotification,
                object: nil)
            
        } catch {
            DDLogError("can't start capture: \(error.localizedDescription)")
            canStartCapture = true
        }
    }
    
    func stopCapture() {
        DDLogVerbose("LiveBroadcastVC::stopCapture")
        canStartCapture = true
        
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.isIdleTimerDisabled = false
        
        invalidateTimers()
        
        retryList.removeAll()
        
        streamConditioner?.stop()
        streamConditioner = nil
        
        streamer?.stopCapture()
        streamer = nil

    }
    
    func setBackgroundCapture() {
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.isIdleTimerDisabled = false
        
        uiTimer?.invalidate()
        uiTimer = nil
        backgroundStream = true
        
    }

    func endBackgroundCapture() {
        UIApplication.shared.isIdleTimerDisabled = true

        let nc = NotificationCenter.default
        nc.addObserver(
            self,
            selector: #selector(orientationDidChange(notification:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)

        uiTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateInfo), userInfo: nil, repeats: true)
    }

    
    func invalidateTimers() {
        uiTimer?.invalidate()
        uiTimer = nil
        
        retryTimer?.invalidate()
        retryTimer = nil
        
        recordDurationTImer?.invalidate()
        recordDurationTImer = nil
    }
    
    // Method may be called on a background thread. Move UI update code inside the main queue.
    func captureStateDidChange(state: CaptureState, status: Error) {
        DispatchQueue.main.async {
            self.onCaptureStateChange(state: state, status: status)
        }
    }
    
    func onCaptureStateChange(state: CaptureState, status: Error) {
        DDLogVerbose("captureStateDidChange: \(state) \(status.localizedDescription)")
        
        switch (state) {
        case .CaptureStateStarted:
            Indicator.stopAnimating()
            Indicator.isHidden = true
            showUI()
            isMuted = false
            zoomFactor = streamer?.getCurrentZoom() ?? 1.0
            
            Message_Label.text = ""
            Message_Label.isHidden = true
            
            if let session = streamer?.session {
                if isMulticam {
                    backPreviewLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
                    guard backPreviewLayer != nil else {
                        return
                    }
                    frontPreviewLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
                    guard frontPreviewLayer != nil else {
                        return
                    }
                    if streamer?.connectPreview(back: backPreviewLayer!, front: frontPreviewLayer!) == false {
                        return
                    }
                    backPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
                    frontPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
                    
                    view.layer.addSublayer(backPreviewLayer!)
                    view.layer.insertSublayer(frontPreviewLayer!, above: backPreviewLayer!)
                    if frontPreviewLayer != nil {
                    }

                } else if !LarixSettings.sharedInstance.radioMode {
                    previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    guard previewLayer != nil else {
                        return
                    }
                    view.layer.addSublayer(previewLayer!)
                }
                updateOrientation()
                bringPreviewToBottom()
            }
            
            uiTimer?.invalidate()
            uiTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateInfo), userInfo: nil, repeats: true)
            
            // enable adaptive bitrate
            createStreamConditioner()
            
            //Subcribe to volume change to start capture
            volumeChangeTime = CACurrentMediaTime()
            NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(_:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
            
            if self.restartBroadcasting {
                self.restartBroadcasting = false
                
                Settings_Button.isHidden = true
                
                self.startAnimating(type: .lineScalePulseOut)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.stopAnimating()
                    self.startStream()
                }
            }
            
        case .CaptureStateFailed:
            if (streamer == nil) {
                DDLogWarn("Capture failed, but we're not running anyway")
                return
            }
            stopStream()
            removePreview()
            stopCapture()
            
            Indicator.stopAnimating()
            Indicator.isHidden = true
            
            hideUI()
            Settings_Button.isHidden = false
            Settings_Button.isEnabled = true
            Mode_Button.isHidden = false
            Mode_Button.isEnabled = true
            Resolution_Button.isHidden = false
            Resolution_Button.isUserInteractionEnabled = true
            
            showStatusMessage(message: String.localizedStringWithFormat(NSLocalizedString("Larix Broadcaster: %@.", comment: ""), status.localizedDescription))
            
        case .CaptureStateCanRestart:
            showStatusMessage(message: String.localizedStringWithFormat(NSLocalizedString("You can try to restart capture now.", comment: ""), status.localizedDescription))
            
        case .CaptureStateSetup:
            showStatusMessage(message: status.localizedDescription)
            
        default: break
        }
    }
    
    func removePreview() {
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        backPreviewLayer?.removeFromSuperlayer()
        backPreviewLayer = nil
        frontPreviewLayer?.removeFromSuperlayer()
        frontPreviewLayer = nil
    }
    
    // MARK: RTMP connection utitlites
    func createConnection(connection: Connection) {
        DDLogVerbose("connection: \(connection.name)")
        
        var id: Int32 = -1
        let url = URL.init(string: connection.url)
        var isSrt = false
        let audioOnly = LarixSettings.sharedInstance.radioMode
        
        if let scheme = url?.scheme?.lowercased(), let host = url?.host {
            let connMode = audioOnly ? .audioOnly : ConnectionMode.init(rawValue: connection.mode)!

            if connMode != .audioOnly && scheme.hasPrefix("rtmp") && streamer?.videoCodecType == kCMVideoCodecType_HEVC {
                let name = connection.name
                DispatchQueue.main.async {
                    let message = String.localizedStringWithFormat(NSLocalizedString("%@: RTMP support for HEVC is a non-standard experimental feature. In case of issues please contact our helpdesk.", comment: ""), name)
                    Toast(text: message, duration: Delay.long).show()
                }
            }
            if scheme.hasPrefix("rtmp") || scheme.hasPrefix("rtsp") {
                
                let config = ConnectionConfig()
                
                config.uri = URL(string: connection.url)!
                config.auth = ConnectionAuthMode.init(rawValue: connection.auth)!
                config.mode = connMode
                
                if let username = connection.username, let password = connection.password {
                    config.username = username
                    config.password = password
                }
                
                DDLogVerbose("url: \(config.uri.absoluteString)")
                DDLogVerbose("mode: \(config.mode.rawValue)")
                DDLogVerbose("auth: \(config.auth.rawValue)")
                DDLogVerbose("user: \(String(describing: connection.username))")
                DDLogVerbose("pass: \(String(describing: connection.password))")
                
                id = streamer?.createConnection(config: config) ?? -1
                
            } else if scheme == "srt", let port = url?.port {
                checkMaxBw(connection: connection)
                let config = SrtConfig()
                
                config.host = host
                config.port = Int32(port)
                config.mode = connMode
                config.connectMode = SrtConnectMode(rawValue: connection.srtConnectMode) ?? .caller
                config.pbkeylen = connection.pbkeylen
                config.passphrase = connection.passphrase
                config.latency = connection.latency
                config.maxbw = connection.maxbw
                config.streamid = connection.streamid
                config.retransmitAlgo = ConnectionRetransmitAlgo(rawValue: connection.retransmitAlgo) ?? .default
                
                DDLogVerbose("host: \(String(describing: config.host))")
                DDLogVerbose("port: \(config.port)")
                DDLogVerbose("mode: \(config.mode.rawValue)")
                DDLogVerbose("passphrase: \(String(describing: config.passphrase))")
                DDLogVerbose("pbkeylen: \(config.pbkeylen)")
                DDLogVerbose("latency: \(config.latency)")
                DDLogVerbose("maxbw: \(config.maxbw)")
                DDLogVerbose("streamid: \(String(describing: config.streamid))")
                
                id = streamer?.createConnection(config: config) ?? -1
                isSrt = true
            } else if scheme == "rist" {
                
                let config = RistConfig()
                
                config.uri = URL(string: connection.url)!
                config.mode = connMode
                config.profile = RistProfile(rawValue: connection.rist_profile) ?? .main

                id = streamer?.createRistConnection(config: config) ?? -1
                isSrt = true
            }
            
        }
        
        if id != -1 {
            connectionId[id] = connection
            connectionState[id] = .disconnected
            connectionStatistics[id] = ConnectionStatistics()
            connectionStatistics[id]?.isUdp = isSrt
            
            streamConditioner?.addConnection(id: id)
        } else {
            let message = String.localizedStringWithFormat(NSLocalizedString("Could not create connection \"%@\" (%@).", comment: ""), connection.name, connection.url)
            Toast(text: message).show()
        }
        DDLogVerbose("SwiftApp::create connection: \(id), \(connection.name), \(connection.url)" )
    }
    
    func checkMaxBw(connection: Connection) {
        if connection.maxbw == 0 || connection.maxbw > 10500 {
            return
        }
        let message = """
Notice that your "maxbw" parameter of SRT connection seem to have incorrect value, \
so we've set it to "0" to be relative to input rate. We recommend you using this value by default.
"""
        connection.maxbw = 0
        do {
            try dbQueue.write { (db) in
                try connection.save(db)
            }
        } catch {
            DDLogError("Update failed")
        }
        Toast(text: NSLocalizedString(message, comment: ""), duration: Delay.long).show()
    }
    
    func releaseConnection(id: Int32) {
        if id != -1 {
            DDLogVerbose("SwiftApp::release connection: \(id)")
            
            connectionId.removeValue(forKey: id)
            connectionState.removeValue(forKey: id)
            connectionStatistics.removeValue(forKey: id)
            
            streamConditioner?.removeConnection(id: id)
            
            streamer?.releaseConnection(id: id)
        }
    }
    
    // Method is called on a background thread. Move UI update code inside the main queue.
    func connectionStateDidChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]!) {
        DispatchQueue.main.async {
            self.onConnectionStateChange(id: id, state: state, status: status, info: info)
        }
    }
    
    func onConnectionStateChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]!) {
        DDLogVerbose("connectionStateDidChange id:\(id) state:\(state.rawValue) status:\(status.rawValue)")
        
        // ignore disconnect confirmation after releaseConnection call
        if let connection = connectionId[id], let _ = connectionState[id], let statistics = connectionStatistics[id] {
            
            connectionState[id] = state
            
            switch (state) {
                
            case .connected:
                let time = CACurrentMediaTime()
                statistics.startTime = time
                statistics.prevTime = time
                statistics.prevBytesDelivered = streamer?.bytesDelivered(connection: id) ?? 0
                statistics.prevBytesSent = streamer?.bytesSent(connection: id) ?? 0
                
            case .disconnected where isBroadcasting:
                let name = connection.name
                
                var retry = false
                
                releaseConnection(id: id)
                
                switch (status) {
                case .connectionFail:
                    let message = String.localizedStringWithFormat(NSLocalizedString("%@: Could not connect to server. Please check stream URL and network connection. Retrying in 3 seconds.", comment: ""), name)
                    Toast(text: message).show()
                    
                    retry = true
                    
                case .unknownFail:
                    var status: String?
                    if let info = info, info.count > 0 {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: info)
                            status = String(data: jsonData, encoding: .utf8)
                        } catch {
                        }
                    }
                    
                    let message: String
                    if let status = status {
                        message = String.localizedStringWithFormat(NSLocalizedString("%@: Error: \(status), retrying in 3 seconds.", comment: ""), name)
                    } else {
                        message = String.localizedStringWithFormat(NSLocalizedString("%@: Unknown connection error, retrying in 3 seconds.", comment: ""), name)
                    }
                    Toast(text: message).show()
                    
                    retry = true
                    
                case .authFail:
                    var badType = false
                    if let info = info, info.count > 0 {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: info)
                            if let json = String(data: jsonData, encoding: .utf8) {
                                if json.contains("authmod=adobe"), connection.auth != ConnectionAuthMode.rtmp.rawValue, connection.auth != ConnectionAuthMode.akamai.rawValue {
                                    badType = true
                                } else if json.contains("authmod=llnw"), connection.auth != ConnectionAuthMode.llnw.rawValue {
                                    badType = true
                                }
                            }
                        } catch {
                        }
                    }
                    
                    let message: String
                    if badType {
                        message = String.localizedStringWithFormat(NSLocalizedString("%@: Larix doesn't support this type of RTMP authorization. Please use rtmpauth URL parameter or other \"Target type\" for authorization.", comment: ""), name)
                    } else {
                        message = String.localizedStringWithFormat(NSLocalizedString("%@: Authentication error. Please check stream credentials.", comment: ""), name)
                    }
                    Toast(text: message).show()
                    
                case .success: break
                @unknown default: break
                }
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let canConnect = appDelegate.canConnect
                
                if retry, canConnect {
                    retryList.append(connection)
                    
                    retryTimer?.invalidate()
                    retryTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(autoRetry), userInfo: nil, repeats: false)
                }
                
                if !canConnect || (retryList.count == 0 && connectionId.count == 0) {
                    stopStream()
                }
                
            case .initialized, .setup, .record, .disconnected: break
            @unknown default: break
            }
        }
    }
    
    @objc func autoRetry() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if !appDelegate.canConnect {
            DispatchQueue.main.async {
                self.stopStream()
            }
        } else {
            for connection in retryList {
                createConnection(connection: connection)
            }
            retryList.removeAll()
        }
    }
    
    // MARK: mp4 record
    func startRecord() {
        if LarixSettings.sharedInstance.record {
            restartRecording = false
            streamer?.startRecord()
        }
    }
    
    @objc func restartRecord() {
        streamer?.stopRecord(restart: true)
    }
    
    
    func stopRecord() {
        recordDurationTImer?.invalidate()
        recordDurationTImer = nil
        
        streamer?.stopRecord(restart: false)
    }
    
    // MARK: Mute sound
    var isMuted: Bool = false {
        didSet {
            if isMuted {
                Mute_Button.layer.backgroundColor = UIColor.white.cgColor
                Mute_Button.setImage(#imageLiteral(resourceName: "mute_on"), for: .normal)
            } else {
                Mute_Button.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor
                Mute_Button.setImage(#imageLiteral(resourceName: "mute_off"), for: .normal)
            }
            streamer?.isMuted = isMuted
            
        }
    }
    
    // MARK: Can't change camera
    func notification(notification: StreamerNotification) {
        switch (notification) {
        case .ActiveCameraDidChange:
            DispatchQueue.main.async {
                self.zoomFactor = self.streamer?.getCurrentZoom() ?? 1.0
            }
        case .ChangeCameraFailed:
            DispatchQueue.main.async {
                let message = NSLocalizedString("The selected video size or frame rate is not supported by the destination camera. Decrease the video size or frame rate before switching cameras.", comment: "")
                Toast(text: message, duration: Delay.long).show()
            }
        case .FrameRateNotSupported:
            DispatchQueue.main.async {
                let message = (LarixSettings.sharedInstance.cameraPosition == .front) ?
                    NSLocalizedString("The selected frame rate is not supported by this camera. Try to start app with Back Camera.", comment: "") :
                    NSLocalizedString("The selected frame rate is not supported by this camera.", comment: "")
                Toast(text: message, duration: Delay.long).show()
            }
        }
    }
    
    // MARK: Device orientation
    @objc func orientationDidChange(notification: Notification) {
        DDLogVerbose("orientationDidChange")
        updateOrientation()
    }
    
    // 1 - Set the preview layer frame so that the frame of the preview layer changes when the screen rotates.
    // 2 - Rotate the preview layer connection with the rotation of the device.
    func updateOrientation() {
        DDLogVerbose("updateOrientation")
        previewLayer?.frame = view.layer.frame
        
        let deviceOrientation = UIApplication.shared.statusBarOrientation
        let newOrientation = toAVCaptureVideoOrientation(deviceOrientation: deviceOrientation, defaultOrientation: AVCaptureVideoOrientation.portrait)
        previewLayer?.connection?.videoOrientation = newOrientation

        if backPreviewLayer?.connection?.isVideoOrientationSupported ?? false {
            backPreviewLayer?.connection?.videoOrientation = newOrientation
        }
        if frontPreviewLayer?.connection?.isVideoOrientationSupported ?? false {
            frontPreviewLayer?.connection?.videoOrientation = newOrientation
        }
        
        if LarixSettings.sharedInstance.postprocess {
            streamer?.resetFocus()
            Focus_Label.isHidden = true
            
            if LarixSettings.sharedInstance.liveRotation {
                streamer?.orientation = newOrientation
            }
        }
        
        let frame = VUMeter.frame
        var w = frame.width
        var h = frame.height
        (w, h) = (min(w,h), max(w,h))
        
        var top = view.layer.frame.height - h - 16.0
        var left = CGFloat(10.0)
        if newOrientation == .landscapeRight || newOrientation == .landscapeLeft {
            top = (view.layer.frame.height - h) / 2
            left = Flip_Button.x + Flip_Button.width + 30
        }
        
        VUMeter.frame = CGRect(x: left, y: top, width: w, height: h)
        VUMeter.arrangeLayers()
        adjustPipPosition()
    }
    
    func toAVCaptureVideoOrientation(deviceOrientation: UIInterfaceOrientation, defaultOrientation: AVCaptureVideoOrientation) -> AVCaptureVideoOrientation {
        
        var captureOrientation: AVCaptureVideoOrientation
        
        switch (deviceOrientation) {
        case .portrait:
            // Device oriented vertically, home button on the bottom
            //DDLogVerbose("AVCaptureVideoOrientationPortrait")
            captureOrientation = AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown:
            // Device oriented vertically, home button on the top
            //DDLogVerbose("AVCaptureVideoOrientationPortraitUpsideDown")
            captureOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft:
            // Device oriented horizontally, home button on the right
            //DDLogVerbose("AVCaptureVideoOrientationLandscapeLeft")
            captureOrientation = AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            // Device oriented horizontally, home button on the left
            //DDLogVerbose("AVCaptureVideoOrientationLandscapeRight")
            captureOrientation = AVCaptureVideoOrientation.landscapeRight
        default:
            captureOrientation = defaultOrientation
        }
        return captureOrientation
    }
    
    // MARK: Request permissions
    var cameraAuthorized: Bool = false {
        // Swift has a simple and classy solution called property observers, and it lets you execute code whenever a property has changed. To make them work, you need to declare your data type explicitly (in our case we need an Bool), then use either didSet to execute code when a property has just been set, or willSet to execute code before a property has been set.
        didSet {
            if cameraAuthorized {
                DDLogVerbose("cameraAuthorized")
                checkMicAuthorizationStatus()
            } else {
                DispatchQueue.main.async {
                    self.presentCameraAccessAlert()
                }
            }
        }
    }
    
    var micAuthorized: Bool = false {
        didSet {
            if micAuthorized {
                DDLogVerbose("micAuthorized")
                startCapture()
            } else {
                DispatchQueue.main.async {
                    self.presentMicAccessAlert()
                }
            }
        }
    }
    
    var deviceAuthorized: Bool {
        get {
            return cameraAuthorized && micAuthorized
        }
    }
    
    func checkForAuthorizationStatus() {
        DDLogVerbose("checkForAuthorizationStatus")
        if (LarixSettings.sharedInstance.radioMode) {
            cameraAuthorized = true
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch (status) {
        case AVAuthorizationStatus.authorized:
            cameraAuthorized = true
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                granted in
                if granted {
                    DDLogVerbose("cam granted: \(granted)")
                    self.cameraAuthorized = true
                    DDLogVerbose("raw value: \(AVCaptureDevice.authorizationStatus(for: AVMediaType.video).rawValue)")
                } else {
                    self.cameraAuthorized = false
                }
            })
        default:
            cameraAuthorized = false
        }
    }
    
    func checkMicAuthorizationStatus() {
        DDLogVerbose("checkMicAuthorizationStatus")
        
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        
        switch (status) {
        case AVAuthorizationStatus.authorized:
            micAuthorized = true
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: {
                granted in
                if granted {
                    DDLogVerbose("mic granted: \(granted)")
                    self.micAuthorized = true
                    DDLogVerbose("raw value: \(AVCaptureDevice.authorizationStatus(for: AVMediaType.audio).rawValue)")
                } else {
                    self.micAuthorized = false
                }
            })
        default:
            micAuthorized = false
        }
    }
    
    func openSettings() {
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        if let url = settingsUrl {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    // MARK: UI utilities
    func showConnectionInfo() {
        let ids = Array(connectionId.keys).sorted(by: <)
        for i in 0..<name.count {
            if i < ids.count {
                if let connection = connectionId[ids[i]], let statistics = connectionStatistics[ids[i]] {
                    name[i].text = connection.name
                    
//                    let tr = trafficToString(bytes: statistics.prevBytesDelivered)
                    let bw = bandwidthToString(bps: statistics.bps)
                    bandWidth = bw
//                    status[i].text = bw + ", " + tr
                    status[i].text = bw
                    let packetsLost = streamer?.udpPacketsLost(connection: ids[i]) ?? 0

                    var color = UIColor.white
                    if statistics.isUdp && statistics.packetsLost != packetsLost {
                        statistics.packetsLost = packetsLost
                        color = UIColor.yellow
                    } else if !statistics.isUdp {
                        if statistics.latency > 5.0 {
                            color = UIColor.red
                        } else if statistics.latency > 1.0 {
                            color = UIColor.yellow
                        }
                    }
                    status[i].textColor = color
                    
                    name[i].isHidden = false
                    status[i].isHidden = false
                }
            } else {
                name[i].isHidden = true
                status[i].isHidden = true
                name[i].text = ""
                status[i].text = NSLocalizedString("Connecting...", comment: "")
            }
        }
    }
    
    func hideConnectionInfo() {
        for label in name {
            label.text = ""
            label.isHidden = true
        }
        let text = NSLocalizedString("Connecting...", comment: "")
        for label in status {
            label.text = text
            label.isHidden = true
        }
    }
    
    func showUI() {
        let audioOnly = LarixSettings.sharedInstance.radioMode

        Message_Label.isHidden = true
        
        Fps_Label.isHidden = audioOnly
        Focus_Label.isHidden = true
        
        Broadcast_Button.isHidden = false
        Settings_Button.isHidden = false
        Flip_Button.isHidden = audioOnly
        Mode_Button.isHidden = false
        Resolution_Button.isHidden = false
        Mute_Button.isHidden = false
        Shoot_Button.isHidden = audioOnly
        Flash_Button.isHidden = audioOnly
        VUMeter.isHidden = false
    }
    
    func hideUI() {
        Fps_Label.isHidden = true
        Focus_Label.isHidden = true
        
        Broadcast_Button.isHidden = true
        Settings_Button.isHidden = true
        Flip_Button.isHidden = true
        Mode_Button.isHidden = true
        Resolution_Button.isHidden = true
        Mute_Button.isHidden = true
        Shoot_Button.isHidden = true
        Flash_Button.isHidden = true
        VUMeter.isHidden = true
    }
    
    // Place the sublayer below the buttons (aka raise the buttons up in the layer).
    func bringPreviewToBottom() {
        view.bringSubviewToFront(VUMeter)
        
        view.bringSubviewToFront(Broadcast_Button)
        view.bringSubviewToFront(Settings_Button)
        view.bringSubviewToFront(Flip_Button)
        view.bringSubviewToFront(Mode_Button)
        view.bringSubviewToFront(Resolution_Button)
        view.bringSubviewToFront(Mute_Button)
        view.bringSubviewToFront(Shoot_Button)
        view.bringSubviewToFront(Shoot_Buttons_View)
        view.bringSubviewToFront(Flash_Button)
        
        view.bringSubviewToFront(Time_Label)
        view.bringSubviewToFront(Fps_Label)
        view.bringSubviewToFront(Focus_Label)
        
        for label in name {
            view.bringSubviewToFront(label)
        }
        for label in status {
            view.bringSubviewToFront(label)
        }
        
        view.bringSubviewToFront(Resolution_Label)
        
        view.bringSubviewToFront(Chat_Button)
        view.bringSubviewToFront(Chat_View)
        view.bringSubviewToFront(Reply_View)
        view.bringSubviewToFront(Battery_View)
        
        view.bringSubviewToFront(Broadcasting_View)
        view.bringSubviewToFront(Recording_View)
    }
    
    func makeRoundButttons() {
        let labelRadius: CGFloat = 13.0
        let btnRadius: CGFloat = 20.0
        
        for label in name {
            label.layer.masksToBounds = true
            label.layer.cornerRadius = labelRadius
        }
        
        for label in status {
            label.layer.masksToBounds = true
            label.layer.cornerRadius = labelRadius
        }
        
        Time_Label.layer.masksToBounds = true
        Time_Label.layer.cornerRadius = labelRadius
        
        Fps_Label.layer.masksToBounds = true
        Fps_Label.layer.cornerRadius = labelRadius
        
        Focus_Label.layer.masksToBounds = true
        Focus_Label.layer.cornerRadius = labelRadius
        
        Broadcast_Button.layer.cornerRadius = btnRadius
//        Settings_Button.layer.cornerRadius = btnRadius
        Resolution_Button.layer.cornerRadius = btnRadius
        Flip_Button.layer.cornerRadius = btnRadius
        Mute_Button.layer.cornerRadius = btnRadius
        Shoot_Button.layer.cornerRadius = btnRadius
        Flash_Button.layer.cornerRadius = btnRadius
    }
    
    func adjustPipPosition() {
        guard #available(iOS 13.0, *) else {
            return
        }
        if let pipStreamer =  streamer as? StreamerMultiCam {
            let pipPos = pipStreamer.pipDevicePosition
            if pipPos == .pip_back || pipPos == .pip_front {
            
                guard let fullLayer = pipPos == .pip_front ? backPreviewLayer : frontPreviewLayer,
                    let pipLayer = pipPos == .pip_back ? backPreviewLayer : frontPreviewLayer else {
                        return
                }
                let viewWidth = view.frame.width
                let viewHeight = view.frame.height
                
                pipLayer.removeFromSuperlayer()
                fullLayer.removeFromSuperlayer()
                pipLayer.frame = CGRect(x: viewWidth / 2, y: viewHeight / 2, width: viewWidth / 2, height: viewHeight / 2)
                fullLayer.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
                view.layer.addSublayer(fullLayer)
                view.layer.insertSublayer(pipLayer, above: fullLayer)
            } else {
                guard let leftLayer = pipPos == .left_front ? frontPreviewLayer : backPreviewLayer,
                    let rightLayer = pipPos == .left_front ? backPreviewLayer : frontPreviewLayer else {
                        return
                }
                let viewWidth = view.frame.width
                let viewHeight = view.frame.height
                if streamer?.videoConfig?.portrait == false {
                    leftLayer.frame = CGRect(x: 0, y: 0, width: viewWidth / 2, height: viewHeight)
                    rightLayer.frame = CGRect(x: viewWidth / 2, y: 0, width: viewWidth / 2, height: viewHeight)
                } else {
                    leftLayer.frame =  CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight / 2)
                    rightLayer.frame = CGRect(x: 0, y: viewHeight / 2, width: viewWidth, height: viewHeight / 2)
                }
            }
            bringPreviewToBottom()
        }
    }
    
    //    override var prefersStatusBarHidden: Bool {
    //        return true
    //    }
    
    // MARK: Alert dialogs
    func presentCameraAccessAlert() {
        let title = NSLocalizedString("Camera is disabled", comment: "")
        let message = NSLocalizedString("Allow the app to access the camera in your device's settings.", comment: "")
        presentAccessAlert(title: title, message: message)
    }
    
    func presentMicAccessAlert() {
        let title = NSLocalizedString("Microphone is disabled", comment: "")
        let message = NSLocalizedString("Allow the app to access the microphone in your device's settings.", comment: "")
        presentAccessAlert(title: title, message: message)
    }
    
    func presentAccessAlert(title: String, message: String) {
        let settingsButtonTitle = NSLocalizedString("Go to settings", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: settingsButtonTitle, style: .default) { [weak self] _ in
            self?.openSettings()
            self?.alertController = nil
        }
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { [weak self] _ in
            self?.alertController = nil
        }
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        presentAlertController(alertController)
        
        // Also update error message on screen, because user can occasionally cancel alert dialog
        showStatusMessage(message: NSLocalizedString("Larix Broadcaster doesn't have all permissions to use camera and microphone, please change privacy settings.", comment: ""))
    }
    
    func presentImportDialog() {
        let deepLink = DeepLink.sharedInstance
        let message = deepLink.getImportConfirmationBody()
        //Rewind to connections list if we're inside of it
        if let activeViews = navigationController?.viewControllers {
            for view in activeViews {
                if view is ConnectionsViewController {
                    navigationController?.popToViewController(view, animated: false)
                    break
                }
            }
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Import settings", comment: ""), message: "Import", preferredStyle: .alert)
        alertController.setValue(message, forKey: "attributedMessage")
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self] _ in
            deepLink.importSettings()
            let connCount = deepLink.getImportConnectionCount()
            let info = deepLink.getImportResultBody()
            deepLink.clear()
            if !info.isEmpty {
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                if connCount > 0 && appDelegate?.onConnectionsUpdate != nil {
                    appDelegate?.onConnectionsUpdate?()
                }
                let toast = Toast(text: info, duration: Delay.long)
                toast.show()
            }
            self?.resumeCapture(shouldRequestPermissions: true)
            self?.alertController = nil
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { [weak self] _ in
            deepLink.clear()
            self?.resumeCapture(shouldRequestPermissions: true)
            self?.alertController = nil
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        presentAlertController(alertController)
    }
    
    func dismissAlertController() {
        alertController?.dismiss(animated: false)
        alertController = nil
    }
    
    func presentAlertController(_ alertController: UIAlertController) {
        dismissAlertController()
        present(alertController, animated: false)
        self.alertController = alertController
    }
    
    func showStatusMessage(message: String) {
        Message_Label.isHidden = false
        Message_Label.text = message
    }
    
    // MARK: Connection status UI
    @objc func updateInfo() {
//        Fps_Label.text = String.localizedStringWithFormat(NSLocalizedString("%d fps", comment: ""), streamer?.fps ?? 0)
        
        if !isBroadcasting {
            return
        }
        
        let curTime = CACurrentMediaTime()
        let broadcastTime = curTime - broadcastStartTime
        Time_Label.text = timeToString(time: Int(broadcastTime))
        
        let ids = Array(connectionId.keys)
        for id in ids {
            if let state = connectionState[id], let statistics = connectionStatistics[id] {
                // some auth schemes require reconnection to same url multiple times, so connection will be silently closed and re-created inside library; app must not query connection statistics while auth phase is in progress
                if state == .record {
                    
                    statistics.duration = curTime - statistics.prevTime
                    
                    let bytesDelivered = streamer?.bytesDelivered(connection: id) ?? 0
                    let bytesSent = streamer?.bytesSent(connection: id) ?? 0
                    let delta = bytesDelivered > statistics.prevBytesDelivered ? bytesDelivered - statistics.prevBytesDelivered : 0
                    let deltaSent = bytesSent > statistics.prevBytesSent ? bytesSent - statistics.prevBytesSent : 0
                    if !statistics.isUdp {
                        if deltaSent > 0 {
                            statistics.latency =  bytesSent > bytesDelivered ? Double(bytesSent - bytesDelivered) / Double(deltaSent) : 0.0
                        }
                    } else {
                        statistics.packetsLost = streamer?.udpPacketsLost(connection: id) ?? 0
                    }
                    let timeDiff = curTime - statistics.prevTime
                    if timeDiff > 0 {
                        statistics.bps = 8.0 * Double(delta) / timeDiff
                    } else {
                        statistics.bps = 0
                    }
                    
                    statistics.prevTime = curTime
                    statistics.prevBytesDelivered = bytesDelivered
                    statistics.prevBytesSent = bytesSent
                }
            }
        }
        showConnectionInfo()
    }
    
    func timeToString(time: Int) -> String {
        let sec = Int(time % 60)
        let min = Int((time / 60) % 60)
        let hrs = Int(time / 3600)
        let str = String.localizedStringWithFormat(NSLocalizedString("%02d:%02d:%02d", comment: ""), hrs, min, sec)
        return str
    }
    
    func trafficToString(bytes: UInt64) -> String {
        if bytes < 1024 {
            // b
            return String.localizedStringWithFormat(NSLocalizedString("%4dB", comment: ""), bytes)
        } else if bytes < 1024 * 1024 {
            // Kb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fKB", comment: ""), Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            // Mb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fMB", comment: ""), Double(bytes) / (1024 * 1024))
        } else {
            // Gb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fGB", comment: ""), Double(bytes) / (1024 * 1024 * 1024))
        }
    }
    
    func bandwidthToString(bps: Double) -> String {
        if bps < 1000 {
            // b
            return String.localizedStringWithFormat(NSLocalizedString("%4dbps", comment: ""), Int(bps))
        } else if bps < 1000 * 1000 {
            // Kb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fKbps", comment: ""), bps / 1000)
        } else if bps < 1000 * 1000 * 1000 {
            // Mb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fMbps", comment: ""), bps / (1000 * 1000))
        } else {
            // Gb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fGbps", comment: ""), bps / (1000 * 1000 * 1000))
        }
    }
    
    // MARK: focus
    func showFocusView(at center: CGPoint, color: CGColor = UIColor.white.cgColor) {
        
        struct FocusView {
            static let focusView: UIView = {
                let focusView = UIView()
                let diameter: CGFloat = 100
                focusView.bounds.size = CGSize(width: diameter, height: diameter)
                focusView.layer.borderWidth = 2
                
                return focusView
            }()
        }
        FocusView.focusView.transform = CGAffineTransform.identity
        FocusView.focusView.center = center
        FocusView.focusView.layer.borderColor = color
        view.addSubview(FocusView.focusView)
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.1,
                       options: UIView.AnimationOptions(), animations: { () -> Void in
                        FocusView.focusView.transform = CGAffineTransform.identity.scaledBy(x: 0.6, y: 0.6)
        }) { (Bool) -> Void in
            FocusView.focusView.removeFromSuperview()
        }
    }
    
    @objc func tappedView() {
        //DDLogVerbose("tappedView")
        if tapRec.state == .recognized {
            if previewLayer != nil || backPreviewLayer != nil {
                let touchPoint = tapRec.location(in: view)
                let (focusPoint, postion) = getFocusTarget(touchPoint)

                DDLogVerbose("tap focus point (x,y): \(focusPoint?.x ?? -1.0) \(focusPoint?.y ?? -1.0)")
                guard focusPoint != nil else {
                    return
                }
                Focus_Label.isHidden = true
                showFocusView(at: touchPoint)
                streamer?.continuousFocus(at: focusPoint!, position: postion)
            }
        }
    }
    
    @objc func longPressedView() {
        //DDLogVerbose("longPressedView")
        if previewLayer != nil || backPreviewLayer != nil {
            let touchPoint = longPressRec.location(in: view)
            if Broadcast_Button.frame.contains(touchPoint) {
                if ( longPressRec.state == .recognized) {
                    Broadcast_LongTap(Broadcast_Button)
                }                
                return
            }
            if longPressRec.state == .recognized {
                let (focusPoint, postion) = getFocusTarget(touchPoint)
                DDLogVerbose("long tap focus point (x,y): \(focusPoint?.x ?? -1.0) \(focusPoint?.y ?? -1.0)")
                guard focusPoint != nil else {
                    return
                }
                Focus_Label.isHidden = false
                showFocusView(at: touchPoint, color: UIColor.yellow.cgColor)
                streamer?.autoFocus(at: focusPoint!, position: postion)
            }
        }
    }
    
    func getFocusTarget(_ touchPoint: CGPoint) -> (CGPoint?, AVCaptureDevice.Position) {
        var focusPoint: CGPoint?
        var position: AVCaptureDevice.Position = .unspecified
        var previewPosition: MultiCamPicturePosition = streamer?.previewPositionPip ?? .off
        guard let backPreview = backPreviewLayer ?? previewLayer else { return (focusPoint, position) }
        var withinFront = false
        if let frontPreview = frontPreviewLayer {
            if previewPosition == .left_front || previewPosition == .left_back {
                withinFront = frontPreview.frame.contains(touchPoint)
            } else if previewPosition != .off {
                withinFront = (previewPosition == .pip_front && frontPreview.frame.contains(touchPoint)) || (previewPosition == .pip_back && !backPreview.frame.contains(touchPoint))
            }
            position = withinFront ? .front : .back
            if withinFront {
                let fpConvereted = view.layer.convert(touchPoint, to: frontPreview)
                focusPoint = frontPreview.captureDevicePointConverted(fromLayerPoint: fpConvereted)
                previewPosition = streamer?.previewPosition ?? .off
            }
        }
        if focusPoint == nil {
            let fpConvereted = view.layer.convert(touchPoint, to: backPreview)
            focusPoint = backPreview.captureDevicePointConverted(fromLayerPoint: fpConvereted)
        }
        if focusPoint == nil || focusPoint!.x < 0.0 || focusPoint!.x > 1.0 || focusPoint!.y < 0.0 || focusPoint!.y > 1.0 {
            return (nil, .unspecified)
        }
        if position == .unspecified {
            switch previewPosition {
            case .pip_back:
                position = .back
            case .pip_front:
                position = .front
            default:
                position = .unspecified
            }
        }
        if streamer?.canFocus(position: position) != true {
            return (nil, .unspecified)
        }
        return (focusPoint, position)
    }

    @objc func pinchHandler(recognizer: UIPinchGestureRecognizer) {
        if streamer != nil && streamer!.maxZoomFactor > 1 {
            zoomFactor = recognizer.scale * zoomFactor
            zoomFactor = max(1, min(zoomFactor, streamer!.maxZoomFactor))
            DDLogVerbose("zoom=\(zoomFactor)")
            streamer?.zoomTo(factor: zoomFactor)
            recognizer.scale = 1
        }
    }
    
    // Start/stop broadcast on volume keys
    @objc func volumeChanged(_ notification: NSNotification) {
        if !LarixSettings.sharedInstance.volumeKeysCapture {
            return
        }
        guard let info = notification.userInfo,
            let volume = info["AVSystemController_AudioVolumeNotificationParameter"] as? Float,
            let reason = info["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String,
            reason == "ExplicitVolumeChange"
        else {
            return
        }
        
        DDLogVerbose("volume: \(volume)")
        let now = CACurrentMediaTime()
        defer {
            volumeChangeTime = now
        }
        if now - volumeChangeTime < 1.0 {
            return
        }
        if !isBroadcasting {
            startStream()
        } else {
            stopStream()
        }
    }
    
    //MARK: Adaptive bitrate
    func createStreamConditioner() {
        guard let streamer = self.streamer else {
            return
        }
        switch LarixSettings.sharedInstance.abrMode {
        case 1:
            streamConditioner = StreamConditionerMode1(streamer: streamer)
        case 2:
            streamConditioner = StreamConditionerMode2(streamer: streamer)
        case 3:
            streamConditioner = StreamConditionerMode3(streamer: streamer)
        default:
            break
        }
    }
    
    
    func photoSaved(fileUrl: URL) {
        let dest = LarixSettings.sharedInstance.recordStorage
        cloudUtils.movePhoto(fileUrl: fileUrl, to: dest)
        if dest == .local {
            DispatchQueue.main.async {
                Toast(text: String.localizedStringWithFormat(NSLocalizedString("%@ saved to app's documents folder.", comment: ""), fileUrl.lastPathComponent), duration: Delay.short).show()
            }
        }
        
        if isShootAndSend {
            uploadPhoto(fileUrl)
        }
    }
    
    func videoSaved(fileUrl: URL) {
        let dest = LarixSettings.sharedInstance.recordStorage
        //Can't put audio in photo library
        if !(fileUrl.pathExtension == "m4a" && dest == .photoLibrary) {
            cloudUtils.moveVideo(fileUrl: fileUrl, to: dest)
        }
    }
    
    func videoRecordStarted() {
        let duration = Double(LarixSettings.sharedInstance.recordDuration)
        if duration > 0 && recordDurationTImer?.isValid != true {
            let offset = 0.5
            //Trigger switch slighly earlier to made more consistent to key frames
            let firstTime = Date(timeIntervalSinceNow: (duration - offset))
            recordDurationTImer = Timer(fireAt: firstTime, interval: duration, target: self, selector: #selector(self.restartRecord), userInfo: nil, repeats: true)
            RunLoop.main.add(recordDurationTImer!, forMode: .common)
        }
    }
    
    // MARK: CloudNotificationDelegate functions
    func movedToCloud(source: URL) {
        let ext = source.pathExtension
        if ext == "jpg" || ext == "heic" {
            let name = source.lastPathComponent
            DispatchQueue.main.async {
                Toast(text: String.localizedStringWithFormat(NSLocalizedString("%@ saved to iCloud", comment: ""), name), duration: Delay.short).show()
            }
        }
    }
    
    func movedToPhotos(source: URL) {
        let ext = source.pathExtension
        if ext == "jpg" || ext == "heic" {
            let name = source.lastPathComponent
            let album = cloudUtils.photoAlbumName ?? ""
            DispatchQueue.main.async {
                Toast(text: String.localizedStringWithFormat(NSLocalizedString("%@ saved to \"%@\" album in Photos", comment: ""), name, album), duration: Delay.short).show()
            }
        }
    }
    
    func moveToPhotosFailed(source: URL) {
        DispatchQueue.main.async {
            Toast(text: NSLocalizedString("Saving to Photos failed, stored in to app's documents folder instead", comment: ""), duration: Delay.short).show()
        }
    }
    
    func moveToCloudFailed(source: URL) {
        DispatchQueue.main.async {
            Toast(text: NSLocalizedString("Saving to iCloud failed, stored in to app's documents folder instead", comment: ""), duration: Delay.short).show()
        }
    }
    
}
