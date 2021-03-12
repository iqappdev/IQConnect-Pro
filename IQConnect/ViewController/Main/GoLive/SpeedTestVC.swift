//
//  SpeedTestVC.swift
//  IQConnect
//
//  Created by SuperDev on 10.01.2021.
//

import UIKit

class SpeedTestVC: UIViewController {
    
    @IBOutlet weak var speedTestView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var pingMsLabel: UILabel!
    @IBOutlet weak var downloadSpeedLabel: UILabel!
    @IBOutlet weak var uploadSpeedLabel: UILabel!
    @IBOutlet weak var pingTestView: Chart!
    @IBOutlet weak var downloadTestView: Chart!
    @IBOutlet weak var uploadTestView: Chart!
    
    var speedTestServer: SpeedTestServer?
    var pingPoints = [Double]()
    var downloadSpeedPoints = [Double]()
    var uploadSpeedPoints = [Double]()
    var uploadSpeed: Speed?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        startSpeedTest()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "liveDetailSegue" {
            SharedManager.sharedInstance.setVideoResolutionSuggested(true)
        }
    }
    
    @IBAction func onBackButtonClick(_ sender: UIButton) {
        self.navigationController?.popViewController()
    }
    
    @IBAction func onStartTestButtonCick(_ sender: UIButton) {
        self.startSpeedTest()
    }
    
    func setupUI() {
        speedTestView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        speedTestView.layer.cornerRadius = 5
        
        pingTestView.showXLabelsAndGrid = false
        pingTestView.showYLabelsAndGrid = false
        downloadTestView.showXLabelsAndGrid = false
        downloadTestView.showYLabelsAndGrid = false
        uploadTestView.showXLabelsAndGrid = false
        uploadTestView.showYLabelsAndGrid = false
    }

    func startSpeedTest() {
        self.uploadSpeed = nil
        applyButton.isHidden = true
        skipButton.isHidden = true
        startButton.isEnabled = false
        startButton.setTitle("Selecting best server based on ping...", for: .normal)
        resultLabel.text = "Getting the best resolution settings based on the internet speed..."
        
        Service_API.getSpeedTestServers { (speedTestServers, error) in
            guard let speedTestServers = speedTestServers, error == nil else {
                UIHelper.showError(message: "No Connection...")
                self.startButton.isEnabled = true
                self.startButton.setTitle("Restart Test", for: .normal)
                return
            }
            
            self.speedTestServer = speedTestServers[0]
            for server in speedTestServers {
                if server.id == SharedManager.sharedInstance.getSpeedTestServerID() {
                    self.speedTestServer = server
                    break
                }
            }
            
            guard let speedTestServer = self.speedTestServer else {
                self.startButton.setTitle("There was a problem in getting Host Location. Try again later.", for: .normal)
                return
            }
            
            self.startButton.setTitle("Host Location: \(speedTestServer.name)", for: .normal)
        
            self.startPingTest()
        }
    }
    
    func startPingTest() {
        pingPoints.removeAll()
        downloadSpeedPoints.removeAll()
        uploadSpeedPoints.removeAll()
        pingTestView.removeAllSeries()
        downloadTestView.removeAllSeries()
        uploadTestView.removeAllSeries()
        pingMsLabel.text = "0 ms"
        downloadSpeedLabel.text = "0 Mbps"
        uploadSpeedLabel.text = "0 Mbps"
        
        runPing(10)
    }
    
    func runPing(_ count: Int) {
        if count == 0 {
            startDownloadTest()
            return
        }
        
        guard let speedTestServer = speedTestServer else { return }
        SpeedTest.sharedInstance.ping(host: speedTestServer, timeout: 5) { (result) in
            var pingMs = 0
            switch result {
            case .value(let ping):
                pingMs = ping
            case .error(let error):
                print(error.localizedDescription)
                pingMs = 0
            }
            
            DispatchQueue.main.async {
                self.pingMsLabel.text = "\(pingMs) ms"
                
                self.pingPoints.append(Double(pingMs))
                let series = ChartSeries(self.pingPoints)
                series.area = true
                self.pingTestView.removeAllSeries()
                self.pingTestView.add(series)
            }
            
            self.runPing(count - 1)
        }
    }
    
    func startDownloadTest() {
        guard let speedTestServer = speedTestServer else { return }
        
        downloadSpeedPoints.removeAll()
        SpeedTest.sharedInstance.runDownloadTest(for: URL(string: speedTestServer.url)!, size: 32 * 1024 * 1024, timeout: 300) { (speed, avgSpeed) in
            
            DispatchQueue.main.async {
                self.downloadSpeedLabel.text = avgSpeed.pretty.description
                self.downloadSpeedPoints.append(Double(speed.value))
                let series = ChartSeries(self.downloadSpeedPoints)
                series.area = true
                self.downloadTestView.removeAllSeries()
                self.downloadTestView.add(series)
            }
        
        } final: { (result) in
            switch result {
            case .value(let speed):
                self.downloadSpeedLabel.text = speed.pretty.description
            case .error(let error):
                print("download test error = \(error.localizedDescription)")
            }
            self.startUploadTest()
        }

    }
    
    func startUploadTest() {
        guard let speedTestServer = speedTestServer else { return }
        
        uploadSpeedPoints.removeAll()
        
        SpeedTest.sharedInstance.runUploadTest(for: URL(string: speedTestServer.url)!, size: 10 * 1024 * 1024, timeout: 300) { (speed, avgSpeed) in
            
            if self.uploadSpeed != nil {
                return
            }
            
            DispatchQueue.main.async {
                self.uploadSpeedLabel.text = avgSpeed.pretty.description
                self.uploadSpeedPoints.append(Double(speed.value))
                let series = ChartSeries(self.uploadSpeedPoints)
                series.area = true
                self.uploadTestView.removeAllSeries()
                self.uploadTestView.add(series)
            }
        
        } final: { (result) in
            
            if self.uploadSpeed != nil {
                return
            }
            
            var uploadSpeed = Speed(value: 0, units: .Kbps)
            switch result {
            case .value(let speed):
                uploadSpeed = speed
                self.uploadSpeedLabel.text = speed.pretty.description
            case .error(let error):
                print("upload test error = \(error.localizedDescription)")
            }
            self.uploadSpeed = uploadSpeed
            
            print("downloadSpeed=\(uploadSpeed.pretty.description)")
            
            DispatchQueue.main.async {
                self.applyButton.isHidden = false
                self.startButton.isEnabled = true
                self.startButton.setTitle("Restart Test", for: .normal)
                let uploadSpeedInMB = uploadSpeed.value * Double(pow(1024.0, Double(uploadSpeed.units.rawValue + 1))) / (1024.0 * 1024.0)
                var selectedResolution = 0
                if uploadSpeedInMB < 0.5 {
                    SharedManager.sharedInstance.setVideoResolutionIndex(0)
                    selectedResolution = 360
                } else if uploadSpeedInMB < 1.0 {
                    SharedManager.sharedInstance.setVideoResolutionIndex(1)
                    selectedResolution = 480
                } else if uploadSpeedInMB < 2.0 {
                    SharedManager.sharedInstance.setVideoResolutionIndex(2)
                    selectedResolution = 720
                } else {
                    SharedManager.sharedInstance.setVideoResolutionIndex(3)
                    selectedResolution = 1080
                }
                self.resultLabel.text = "We suggest \(selectedResolution)p based on your current result"
            }
        }

    }
}
