//
//  LiveDetailVC.swift
//  IQConnect
//
//  Created by SuperDev on 10.01.2021.
//

import UIKit
import DropDown
import CoreLocation

class LiveDetailVC: UIViewController {
    
    let videoResolutionPixels = ["360P", "480P", "720P", "1080P"]
    let videoCodecs = ["H.264", "HEVC"]

    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var eventDescriptionTextField: UITextField!
    @IBOutlet weak var codecView: UIView!
    @IBOutlet weak var codecTextField: UITextField!
    @IBOutlet weak var resolutionView: UIView!
    @IBOutlet weak var resolutionTextField: UITextField!
    
    let locationService = LocationService.sharedInstance
    var videoResolutions = [VideoResolution]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SharedManager.sharedInstance.setVideoCodec("H.264")
        codecTextField.text = "H.264"
        
        eventNameTextField.text = SharedManager.sharedInstance.getEventName()
        cityTextField.text = SharedManager.sharedInstance.getCity()
        
        locationService.startUpdatingLocation()
        locationService.delegate = self
        
        getVideoResolutions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        let videoResolutionIndex = SharedManager.sharedInstance.getVideoResolutionIndex()
        resolutionTextField.text = videoResolutionPixels[videoResolutionIndex]
    }
    
    @IBAction func onBackButtonClick(_ sender: UIButton) {
        self.navigationController?.popViewController()
    }
    
    @IBAction func onCodecButtonClick(_ sender: UIButton) {
        let dropDown = DropDown()
        dropDown.anchorView = codecView
        dropDown.dataSource = videoCodecs
        dropDown.show()
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.codecTextField.text = item
            SharedManager.sharedInstance.setVideoCodec(item)
        }
    }
    
    @IBAction func onResolutionButtonClick(_ sender: UIButton) {
        let dropDown = DropDown()
        dropDown.anchorView = resolutionView
        dropDown.dataSource = videoResolutionPixels
        dropDown.show()
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.resolutionTextField.text = item
            SharedManager.sharedInstance.setVideoResolutionIndex(index)
        }
    }
    
    @IBAction func onResolutionInfoButtonClick(_ sender: UIButton) {
        if videoResolutions.count == 0 {
            return
        }
        
        var message = ""
        for videoResolution in videoResolutions {
            message += "\n\(videoResolution.pixel ?? "") (\(videoResolution.width)X\(videoResolution.height)) Video \(videoResolution.video_bitrate)K  Audio \(videoResolution.audio_bitrate)K"
        }
        
        let alert = UIAlertController(title: "IQ Connect Pro", message: "", preferredStyle: .alert)
        let messageAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)]
        let messageString = NSAttributedString(string: message, attributes: messageAttributes)
        alert.setValue(messageString, forKey: "attributedMessage")
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onNextButtonClick(_ sender: UIButton) {
        guard let eventName = eventNameTextField.text?.trimmed, !eventName.isEmpty else {
            UIHelper.showError(message: "Enter the event name")
            return
        }
        
        guard let city = cityTextField.text?.trimmed, !city.isEmpty else {
            UIHelper.showError(message: "Enter the city")
            return
        }
        
        let alert = UIAlertController(title: "IQ Connect Pro", message: "We recommended you to enable \"Do Not Disturb\" option from phone settings for uninterrupted streaming, Would you like to turn on?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .cancel, handler: { (_) in
            guard let settingsUrl = URL(string: "App-Prefs:root=DO_NOT_DISTURB") else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "SKIP", style: .default, handler: { (_) in
            let eventDescription = self.eventDescriptionTextField.text?.trimmed ?? ""
            
            SharedManager.sharedInstance.setEventName(eventName)
            SharedManager.sharedInstance.setCity(city)
            SharedManager.sharedInstance.setEventDescription(eventDescription)
            
            // apply resolution to Larix
            let videoResolutionIndex = SharedManager.sharedInstance.getVideoResolutionIndex()
            SharedManager.sharedInstance.setVideoResolutionIndex(videoResolutionIndex)
            
            self.performSegue(withIdentifier: "goLiveSegue", sender: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func getVideoResolutions() {
        let channelID = SharedManager.sharedInstance.getChannelID()
        Service_API.getVideoResolutions(channelID: channelID) { (videoResolutionsList, error) in
            guard let videoResolutionsList = videoResolutionsList, error == nil else {
                return
            }
            
            self.videoResolutions = videoResolutionsList.videos
        }
    }
}

extension LiveDetailVC: LocationServiceDelegate {
    func tracingLocation(currentLocation: CLLocation) {
        UIHelper.getAddressString(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude) { (city, error) in
            guard let city = city, error == nil else {
                return
            }
            
            self.cityTextField.text = city
        }
    }
    
    func tracingLocationDidFailWithError(error: NSError) {
        
    }
}
