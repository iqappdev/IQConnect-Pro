import CoreImage
import CocoaLumberjack

class StreamerSingleCam: Streamer {
    
    enum CameraSwitchingState {
        case none
        case preparing
        case switching
    }
    
    // video
    private var captureDevice: AVCaptureDevice?
    private var videoIn: AVCaptureDeviceInput?
    private var videoOut: AVCaptureVideoDataOutput?
    private var videoConnection: AVCaptureConnection?
    private var transform: ImageTransform?
    private var cameraSwitching: CameraSwitchingState = .none
    
    private var blackFrameTimer: Timer?
    private var blackFrameTime:CFTimeInterval = 0
    private var blackFrameOffset:CFTimeInterval = 0
    private var lastAudioFrameTime: Double = 0.0

    // jpeg capture
    private var imageOut: AVCaptureOutput?

    override var postprocess: Bool {
        return LarixSettings.sharedInstance.postprocess
    }

    override func createSession() -> AVCaptureSession? {
        return AVCaptureSession()
    }
   
    override func setupVideoIn() throws {
        // start video input configuration
         var position = LarixSettings.sharedInstance.cameraPosition
         if #available(iOS 10.0, *) {
             if position == .back {
                 captureDevice = LarixSettings.sharedInstance.getDefaultBackCamera(probe: self.probeCam)
             } else {
                 captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
             }
         } else {
             let cameras: [AVCaptureDevice] = AVCaptureDevice.devices(for: .video)
             for camera in cameras {
                 if camera.position == position {
                     captureDevice = camera
                 }
             }
         }
        
        if captureDevice == nil {
            // wrong cameraID? ok, pick default one
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        }
        
        guard captureDevice != nil else {
            DDLogError("streamer fail: can't open camera device")
            throw StreamerError.SetupFailed
        }
        
        position = captureDevice!.position
        
        do {
            videoIn = try AVCaptureDeviceInput(device: captureDevice!)
        } catch {
            DDLogError("streamer fail: can't allocate video input: \(error)")
            throw StreamerError.SetupFailed
        }
        
        if session!.canAddInput(videoIn!) {
            session!.addInput(videoIn!)
        } else {
            DDLogError("streamer fail: can't add video input")
            throw StreamerError.SetupFailed
        }
        // video input configuration completed
    }
    
    override func setupVideoOut() throws {
        guard let format = setCameraParams(camera: captureDevice!) else {
            throw StreamerError.SetupFailed
        }
        maxZoomFactor = findMaxZoom(camera: captureDevice!, format: format)

        let videoOut = AVCaptureVideoDataOutput()
        videoOut.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: PixelFormat_YUV)]
        videoOut.alwaysDiscardsLateVideoFrames = true
        videoOut.setSampleBufferDelegate(self, queue: workQueue)
        
        if session!.canAddOutput(videoOut) {
            session!.addOutput(videoOut)
        } else {
            DDLogError("streamer fail: can't add video output")
            throw StreamerError.SetupFailed
        }
        
        guard let videoConnection = videoOut.connection(with: AVMediaType.video) else {
            DDLogError("streamer fail: can't allocate video connection")
            throw StreamerError.SetupFailed
        }
        videoConnection.videoOrientation = self.videoOrientation
        videoConnection.automaticallyAdjustsVideoMirroring = false
        videoConnection.isVideoMirrored = false
        setVideoStabilizationMode(connection: videoConnection, camera: captureDevice!)
        
        self.videoOut = videoOut
        self.videoConnection = videoConnection
        
        if postprocess {
            let videoSize = CMVideoDimensions(width: Int32(streamWidth), height: Int32(streamHeight))
            transform = ImageTransform(size: videoSize)
            transform?.portraitVideo = videoConfig!.portrait
            self.transform?.postion = captureDevice!.position

        }
        // video output configuration completed
    }
    

    override func isValidFormat(_ format: AVCaptureDevice.Format) -> Bool {
        return CMFormatDescriptionGetMediaType(format.formatDescription) == kCMMediaType_Video &&
            CMFormatDescriptionGetMediaSubType(format.formatDescription) == PixelFormat_YUV
    }

    override func setupStillImage() throws {
        if #available(iOS 11.0,*) {
            imageOut = AVCapturePhotoOutput()
        } else {
            let stillPhotoOut = AVCaptureStillImageOutput()
            stillPhotoOut.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG, AVVideoQualityKey:0.85] as [String : Any]
            self.imageOut = stillPhotoOut
        }
        if session!.canAddOutput(imageOut!) {
            session!.addOutput(imageOut!)
        } else {
            DDLogError("streamer fail: can't add still image output")
            throw StreamerError.SetupFailed
        }
    }
    
    override func stopCapture() {
        stopBlackFrameTimer()
        super.stopCapture()
    }
    
    override func releaseCapture() {
        // detach compression sessions and mp4 recorder
        videoOut?.setSampleBufferDelegate(nil, queue: nil)

        super.releaseCapture()
        
        videoConnection = nil
        videoIn = nil
        videoOut = nil
        imageOut = nil
        captureDevice = nil
        recordDevice = nil
        ciContext = nil
        session = nil
        transform = nil
        blackFrame = nil
    }
    
    override func changeCamera() {
        
        let discovery = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        let cameras = discovery.devices
        
        if cameras.count < 2 {
            DDLogError("device has only one camera, this is impossible")
            return
        }
        guard cameraSwitching == .none else {
            return
        }
        cameraSwitching = .preparing
        
        workQueue.async {
            guard self.session != nil, self.captureDevice != nil, self.videoIn != nil, self.videoOut != nil else {
                return
            }
            
            var preferredPosition: AVCaptureDevice.Position = .front
            let currentPosition: AVCaptureDevice.Position = self.captureDevice!.position
            
            // find next camera
            switch (currentPosition) {
            case .unspecified, .front:
                preferredPosition = .back
            case .back:
                preferredPosition = .front
            @unknown default: break
            }
            var videoDevice: AVCaptureDevice?
            if #available(iOS 10.0, *) {
                if preferredPosition == .back {
                    videoDevice = LarixSettings.sharedInstance.getDefaultBackCamera(probe: self.probeCam)
                } else {
                    videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition)
                }
            } else {
                for camera in cameras {
                    if camera.position == preferredPosition {
                        videoDevice = camera
                    }
                }
            }
            guard videoDevice != nil else {
                DDLogError("next camera not found, this is impossible")
                return
            }
            
            // check that next camera can produce same resolution and fps as active camera
            var newFormat: AVCaptureDevice.Format?
            for format in videoDevice!.formats {
                
                if CMFormatDescriptionGetMediaType(format.formatDescription) != kCMMediaType_Video {
                    continue
                }
                if CMFormatDescriptionGetMediaSubType(format.formatDescription) != self.PixelFormat_YUV {
                    continue
                }
                
                let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                if resolution.width == self.videoConfig!.videoSize.width, resolution.height == self.videoConfig!.videoSize.height {
                    for range in format.videoSupportedFrameRateRanges {
                        if range.maxFrameRate >= self.videoConfig!.fps, range.minFrameRate <= self.videoConfig!.fps {
                            newFormat = format
                            DDLogVerbose("\(videoDevice!.localizedName) set \(resolution.width)x\(resolution.height) [\(range.minFrameRate)..\(range.maxFrameRate)]")
                            break
                        }
                    }
                    if newFormat != nil {
                        break
                    }
                }
            }
            guard newFormat != nil else {
                self.delegate?.notification(notification: StreamerNotification.ChangeCameraFailed)
                self.cameraSwitching = .none
                return
            }
            self.cameraSwitching = .switching
            self.startBlackFrameTimer(fps: self.videoConfig!.fps)
            DDLogInfo("cameraSwitching start")

            do {
                try videoDevice!.lockForConfiguration()
                videoDevice!.activeFormat = newFormat!
                
                // https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/04_MediaCapture.html
                // If you change the focus mode settings, you can return them to the default configuration as follows:
                if videoDevice!.isFocusModeSupported(.continuousAutoFocus) {
                    if videoDevice!.isFocusPointOfInterestSupported {
                        //DDLogVerbose("reset focusPointOfInterest")
                        videoDevice!.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    }
                    //DDLogVerbose("reset focusMode")
                    videoDevice!.focusMode = .continuousAutoFocus
                }
                let initZoom = self.getInitZoomFactor(forDevice: videoDevice!)
                videoDevice!.videoZoomFactor = initZoom
                self.maxZoomFactor = self.findMaxZoom(camera: videoDevice!, format: newFormat!)
                
                videoDevice!.unlockForConfiguration()
                
                self.session?.beginConfiguration()
                self.session?.removeInput(self.videoIn!)
                
                self.captureDevice = videoDevice
                self.position = self.captureDevice!.position
                self.transform?.postion = self.position
                self.videoIn = try AVCaptureDeviceInput(device: self.captureDevice!)
                
                if self.session!.canAddInput(self.videoIn!) {
                    self.session!.addInput(self.videoIn!)
                } else {
                    throw StreamerError.SetupFailed
                }
                
                guard let videoConnection = self.videoOut!.connection(with: AVMediaType.video) else {
                    DDLogError("streamer fail: can't allocate video connection")
                    throw StreamerError.SetupFailed
                }
                videoConnection.videoOrientation = self.videoOrientation
                self.videoConnection = videoConnection
                self.setVideoStabilizationMode(connection: self.videoConnection!, camera: self.captureDevice!)
                
                // On iOS, the receiver's activeVideoMinFrameDuration resets to its default value if receiver's activeFormat changes; Should first change activeFormat, then set fps
                try self.captureDevice!.lockForConfiguration()
                self.captureDevice!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(self.videoConfig!.fps))
                self.captureDevice!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(self.videoConfig!.fps))
                self.captureDevice!.videoZoomFactor = initZoom
                self.captureDevice!.unlockForConfiguration()
                self.session!.commitConfiguration()
                self.cameraSwitching = .none
                DDLogInfo("cameraSwitching done")
                
            } catch {
                DDLogError("can't change camera: \(error)")
                self.delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: error)
            }
            
            self.delegate?.notification(notification: StreamerNotification.ActiveCameraDidChange)
        }
    }
    
    func probeCam(camera: AVCaptureDevice, size: CMVideoDimensions, fps: Double) -> Bool {
        let supported = camera.formats.contains { (format) in
            let camResolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let camFps = format.videoSupportedFrameRateRanges
            return CMFormatDescriptionGetMediaType(format.formatDescription) == kCMMediaType_Video &&
                camResolution.width >= size.width && camResolution.height >= size.height &&
                camFps.contains{ (range) in
                    range.minFrameRate <= fps && fps <= range.maxFrameRate }
        }
        return supported
    }
    
    override func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput videoDataOutput: AVCaptureVideoDataOutput) {
        if videoDataOutput != videoOut {
            return
        }
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if isPaused {
            outputBlackFrame(withPresentationTime: sampleTime)
            return
        }
        if (self.cameraSwitching != .switching) {
            self.stopBlackFrameTimer()
        } else {
            let seconds = CACurrentMediaTime()
            blackFrameOffset = sampleTime.seconds - seconds
        }
        if blackFrameTime > 0 {
            if sampleTime.seconds < blackFrameTime + 0.001 {
                DDLogInfo("Skip frame after black frame")
                return
            } else {
                blackFrameTime = 0
            }
        }
        
        //DDLogVerbose("didOutput sampleBuffer: video \(DispatchTime.now())")
        
        // apply CoreImage filters to video; if postprocessing is not required, then just pass buffer directly to encoder and mp4 writer
        if postprocess {
            // rotateAndEncode will also send frame to mp4 writer
            rotateAndEncode(sampleBuffer: sampleBuffer)
        } else {
            engine.didOutputVideoSampleBuffer(sampleBuffer)
        }
    }
    
    override func processsAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput audioDataOutput: AVCaptureAudioDataOutput) {
        let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)

        if self.blackFrameTimer != nil {
            let ts_time = ts.seconds
            let dt = ts_time - lastAudioFrameTime
            if dt > 0.05 {
                let count = CMSampleBufferGetNumSamples(sampleBuffer)
                if let format = CMSampleBufferGetFormatDescription(sampleBuffer),
                    let audioDesc =  CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee {
                    var deltaSamples = Int(ceil((ts.seconds - lastAudioFrameTime) * audioDesc.mSampleRate))
                    deltaSamples -= deltaSamples % 2
                    var pts_val = Int64(lastAudioFrameTime * audioDesc.mSampleRate)
                    while deltaSamples > 0 {
                        let samples = deltaSamples > count * 3 / 2 ? count : deltaSamples //Generate block with at most 1.5x of input block length
                        DDLogInfo("black frame: generatng \(samples) empty samples @ \(audioDesc.mSampleRate)")
                        let pts = CMTime(value: pts_val, timescale: CMTimeScale(audioDesc.mSampleRate))
                        if let buf = generatePCM(pts: pts, frameCount: samples, format: format) {
                            engine.didOutputAudioSampleBuffer(buf)
                        }
                        pts_val += Int64(samples)
                        deltaSamples -= samples
                    }
                }
                
            }
        }
        lastAudioFrameTime = ts.seconds + duration.seconds
        super.processsAudioSampleBuffer(sampleBuffer, fromOutput: audioDataOutput)
    }

    private func generatePCM(pts: CMTime, frameCount: CMItemCount, format: CMAudioFormatDescription) -> CMSampleBuffer? {
        guard var audioDesc =  CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee else {return nil}

        var sampleBuffer: CMSampleBuffer? = nil
        
        let dataLen:Int = Int(frameCount) * Int(audioDesc.mChannelsPerFrame) * 2
        var bbuf: CMBlockBuffer? = nil

        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                        memoryBlock: nil,
                                                        blockLength: dataLen,
                                                        blockAllocator: nil,
                                                        customBlockSource: nil,
                                                        offsetToData: 0,
                                                        dataLength: dataLen,
                                                        flags: 0,
                                                        blockBufferOut: &bbuf)
        
        guard status == kCMBlockBufferNoErr, bbuf != nil else {
            DDLogError("Failed to create memory block")
            return nil
        }

        status = CMBlockBufferFillDataBytes(with: 0, blockBuffer: bbuf!, offsetIntoDestination: 0, dataLength: dataLen)
        guard status == kCMBlockBufferNoErr else {
            DDLogError("Failed to fill memory block")
            return nil
        }
        
        var formatDesc: CMAudioFormatDescription?
        status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                                asbd: &audioDesc,
                                                layoutSize: 0,
                                                layout: nil,
                                                magicCookieSize: 0,
                                                magicCookie: nil,
                                                extensions: nil,
                                                formatDescriptionOut: &formatDesc)
        guard status == noErr, formatDesc != nil else {
            DDLogError("Failed to create format description")
            return nil
        }

        status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault,
                                                                      dataBuffer: bbuf!,
                                                                      formatDescription: formatDesc!,
                                                                      sampleCount: frameCount,
                                                                      presentationTimeStamp: pts,
                                                                      packetDescriptions: nil,
                                                                      sampleBufferOut: &sampleBuffer)

        guard  status == noErr, sampleBuffer != nil else {
            DDLogError("Failed to create sampleBuffer")
            return nil
        }
        return sampleBuffer
    }

    
    // MARK: jpeg capture
    override func captureStillImage() {
        guard cameraSwitching == .none else {
            return
        }
        let df = DateFormatter()
        df.dateFormat = "yyyyMMddHHmmss"
        photoFileName = "IMG_" + df.string(from: Date())
        if #available(iOS 11.0,*) {
            if let out = self.imageOut as? AVCapturePhotoOutput{
                var codecs: [AVVideoCodecType] = []
                if LarixSettings.sharedInstance.snapshotFormat == .heic {
                    codecs = out.supportedPhotoCodecTypes(for: .heic)
                    if codecs.isEmpty {
                        DDLogWarn("HEIC is not available, fallback to JPEG")
                    } else {
                        photoFileName?.append(".heic")
                    }
                }
                if codecs.isEmpty {
                    codecs = out.supportedPhotoCodecTypes(for: .jpg)
                    photoFileName?.append(".jpg")
                }
                if let codec = codecs.first {
                    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey:codec])
                    let videoConnection = out.connection(with: .video)
                    videoConnection?.videoOrientation = self.orientation

                    out.capturePhoto(with: settings, delegate: self)
                }
            }
        } else {
            photoFileName?.append(".jpg")
            guard let out = self.imageOut as? AVCaptureStillImageOutput else {return}
            workQueue.async {
                search: for connection in out.connections {
                    for port in connection.inputPorts {
                        if port.mediaType == AVMediaType.video {
                            connection.videoOrientation = self.orientation
                            out.captureStillImageAsynchronously(from: connection, completionHandler: self.saveStillImage)
                            break search
                        }
                    }
                }
            }
        }
    }
    
    private func saveStillImage(imageBuffer: CMSampleBuffer?, error: Error?) {
        if error == nil, let buffer = imageBuffer {
            do {
                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) {
                    let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let fileUrl = documents.appendingPathComponent(photoFileName!)
                    try imageData.write(to: fileUrl, options: .atomic)
                    self.delegate?.photoSaved(fileUrl: fileUrl)
                    DDLogVerbose("save jpeg to \(fileUrl.absoluteString)")
                }
            } catch {
                DDLogError("failed to save jpeg: \(error)")
            }
        }
    }

    @available(iOS 11.0,*)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil, let imageData = photo.fileDataRepresentation() {
            do {
                let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let fileUrl = documents.appendingPathComponent(photoFileName!)
                
                try imageData.write(to: fileUrl, options: .atomic)
                self.delegate?.photoSaved(fileUrl: fileUrl)
                DDLogVerbose("save photo to \(fileUrl.absoluteString)")
            } catch {
                DDLogError("failed to photo jpeg: \(error)")
            }
        }
    }

    // MARK: Live rotation
    private func rotateAndEncode(sampleBuffer: CMSampleBuffer) {
        
        let outputOptions = [kCVPixelBufferOpenGLESCompatibilityKey as String: NSNumber(value: true),
                             kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as [String : Any]
        
        var outputBuffer: CVPixelBuffer? = nil
        
        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault,
                                                   streamWidth, streamHeight,
                                                   PixelFormat_RGB,
                                                   outputOptions as CFDictionary?,
                                                   &outputBuffer)
        
        guard status == kCVReturnSuccess, outputBuffer != nil else {
            DDLogError("error in CVPixelBufferCreate")
            return
        }
        
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        let sourceBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        transform?.orientation = orientation
       
        let sourceImage = CIImage(cvPixelBuffer: sourceBuffer, options: [CIImageOption.colorSpace: NSNull()])
        
        var outputImage: CIImage = sourceImage
        let bounds = CGRect(x: 0, y: 0, width: streamWidth, height: streamHeight)

        guard let transformMatrix = transform?.getMatrix(extent: bounds) else {
            DDLogError("Failed to get transformation")
            return
        }
        let wCam: Float = Float(videoConfig!.videoSize.width)  // 1920
        let hCam: Float = Float(videoConfig!.videoSize.height) // 1080

        // "overlay" is demo function, it is not used in stock Larix application
        func overlay() {
//            let colorSpace = CGColorSpaceCreateDeviceRGB()
//            let alphaInfo = CGImageAlphaInfo.premultipliedLast.rawValue
//
//            let bitmapContext = CGContext(
//                data: nil,
//                width: Int(wCam),
//                height: Int(hCam),
//                bitsPerComponent: 8,
//                bytesPerRow: 0,
//                space: colorSpace,
//                bitmapInfo: alphaInfo)!
//
//            bitmapContext.setAlpha(0.5)
//            bitmapContext.setTextDrawingMode(CGTextDrawingMode.fill)
//            bitmapContext.textPosition = CGPoint(x: 20, y: 20)
//
//            let displayLineTextWhite = CTLineCreateWithAttributedString(NSAttributedString(string: todayString(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 50)]))
//            CTLineDraw(displayLineTextWhite, bitmapContext)
//
//            let textCGImage = bitmapContext.makeImage()!
//            let textImage = CIImage(cgImage: textCGImage)
            guard let watermarkImage = MainVC.watermarkImage?.sd_resizedImage(with: CGSize(width: Int(wCam), height: Int(hCam)), scaleMode: .aspectFill) else { return }
            let watermarkCIImage = CIImage(image: watermarkImage)
            
            let combinedFilter = CIFilter(name: "CISourceOverCompositing")!
//            combinedFilter.setValue(textImage, forKey: "inputImage")
            combinedFilter.setValue(watermarkCIImage, forKey: "inputImage")
            combinedFilter.setValue(outputImage, forKey: "inputBackgroundImage")
            
            outputImage = combinedFilter.outputImage!
        }
        outputImage = outputImage.transformed(by: transformMatrix)

        // Demo of additional CoreImage filter: "overlay" text on top of stream using "CISourceOverCompositing"
        overlay()
        
        if let context = ciContext {
            context.render(outputImage, to: outputBuffer!, bounds: outputImage.extent, colorSpace: nil)
            engine.didOutputVideoPixelBuffer(outputBuffer!, withPresentationTime:sampleTime)
        }
    }
    
    func todayString() -> String {
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        return String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
    }
    
    // MARK: Autofocus
    override func continuousFocus(at focusPoint: CGPoint, position _: AVCaptureDevice.Position = .unspecified) {
        focus(at: focusPoint, mode: .continuousAutoFocus, camera: captureDevice)
    }
    
    override func autoFocus(at focusPoint: CGPoint, position _: AVCaptureDevice.Position = .unspecified) {
        focus(at: focusPoint, mode: .autoFocus, camera: captureDevice)
    }
    
    override func canFocus(position: AVCaptureDevice.Position = .unspecified) -> Bool {
        return focusSupported(camera: captureDevice)
    }

    
    override func resetFocus() {
        workQueue.async {
            if let camera = self.captureDevice {
                do {
                    try camera.lockForConfiguration()
                    self.defaultFocus(camera: camera)
                    camera.unlockForConfiguration()
                } catch {
                    DDLogError("can't lock video device for configuration: \(error)")
                }
            }
        }
    }

    override func zoomTo(factor: CGFloat) {
        workQueue.async {
            if let camera = self.captureDevice {
                do {
                    if factor > camera.activeFormat.videoMaxZoomFactor || factor < 1.0 {
                        return
                    }
                    try camera.lockForConfiguration()
                    camera.videoZoomFactor = factor
                    camera.unlockForConfiguration()
                } catch {
                    DDLogError("can't lock video device for configuration: \(error)")
                }
            } else {
                DDLogError("No camera")
            }
        }
    }
    
    override func getCurrentZoom() -> CGFloat {
        return self.captureDevice?.videoZoomFactor ?? 1.0
    }
    
    override func findMaxZoom(camera: AVCaptureDevice, format: AVCaptureDevice.Format) -> CGFloat {
        if camera.position != .back {
            return 1
        }
        return format.videoMaxZoomFactor
    }
    
    override func updateFps(newBitrate: Int32) {
        guard videoConfig != nil && videoConfig!.bitrate != 0 else {
            return
        }
        let bitrateRel:Double = Double(newBitrate) / Double(videoConfig!.bitrate)
        var relFps = videoConfig!.fps
        if bitrateRel < 0.5 {
            relFps = max(15.0, floor(videoConfig!.fps * bitrateRel * 2.0 / 5.0) * 5.0)
        }
        if abs(relFps - currentFps) < 1.0 {
            return
        }
        let format = captureDevice!.activeFormat
        let ranges = format.videoSupportedFrameRateRanges
        var newFormat: AVCaptureDevice.Format?
//        for range in ranges {
//            NSLog("Range \(range.minFrameRate) - \(range.maxFrameRate) FPS")
//        }
        if ranges.first(where:{ $0.maxFrameRate >= relFps && $0.minFrameRate <= relFps } ) == nil {
            //Need to switch to another format
            newFormat = findFormat(fps: &relFps, camera: captureDevice)
        }
        if let camera = captureDevice {
            do {
                try camera.lockForConfiguration()
                if newFormat != nil {
                    camera.activeFormat = newFormat!
                }
                camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(relFps))
                camera.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(relFps))
                camera.unlockForConfiguration()
                currentFps = relFps
            } catch {
                DDLogError("can't lock video device for configuration: \(error)")
            }
        }
    }
    
    override func toggleFlash() -> Bool {
        guard cameraSwitching == .none else {
            return false
        }
        return toggleFlash(camera: captureDevice)
    }
    
    func startBlackFrameTimer(fps: Double) {
        let interval:TimeInterval = fps < 1.0 ? 1.0/30.0 : 1.0 / fps
        
        if let timer = blackFrameTimer {
            timer.invalidate()
        }
        blackFrameTime = 0
        DDLogVerbose("Start black frame timer at \(fps) FPS  offset \(blackFrameOffset)")
        DispatchQueue.main.async {
            self.blackFrameTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.drawBlackFrame), userInfo: nil, repeats: true)
        }
    }
    
    func stopBlackFrameTimer() {
        if let timer = blackFrameTimer {
            timer.invalidate()
            DDLogVerbose("Stop black frame timer")
        }
        blackFrameTimer = nil
    }
    
    @objc func drawBlackFrame() {
        let seconds = CACurrentMediaTime() + blackFrameOffset
        blackFrameTime = seconds
        let time = CMTime(seconds: seconds, preferredTimescale: 1000)
        outputBlackFrame(withPresentationTime: time)
    }
}
