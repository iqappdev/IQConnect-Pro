//
//  Helper.swift
//  TNDL
//
//  Created by SuperDev on 28.12.2020.
//

import Foundation
import SwiftMessages
import MessageUI
import UIKit
import ImageIO
import MobileCoreServices
import Foundation
import AVFoundation
import Photos
import CoreLocation

enum ImageSize {
    case small
    case medium
    case large
}

class UIHelper {
    static func getAddressString(latitude: Double, longitude: Double, completion: @escaping (String?, Error?) -> ())  {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { if let error = $1 {
                completion(nil, error)
                return
            }
            
            if let placemark = $0?.first {
                var addresses = [String]()
                
                if let locality = placemark.locality, !locality.isEmpty {
                    addresses.append(locality)
                }
                
                if let subAdminArea = placemark.subAdministrativeArea, !subAdminArea.isEmpty {
                    addresses.append(subAdminArea)
                } else if let administrativeArea = placemark.administrativeArea, !administrativeArea.isEmpty {
                    addresses.append(administrativeArea)
                }
                
                completion(addresses.joined(separator: ", "), nil)
            }
        }
    }
    
    static func viewControllerWith(_ vcIdentifier: String, storyboardName: String = "Main") -> UIViewController? {
        var newStoryboardName = storyboardName
        if UIDevice.current.userInterfaceIdiom == .pad {
            newStoryboardName = storyboardName.appending("_iPad")
        }
        let storyboard = UIStoryboard.init(name: newStoryboardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: vcIdentifier)
    }
    
    static func showError(title: String = "Error", message: String) {
        let error = MessageView.viewFromNib(layout: .tabView)
        error.configureTheme(.error)
        error.configureContent(title: title, body: message)
        error.button?.setTitle("Ok", for: .normal)
        var errorConfig = SwiftMessages.defaultConfig
        errorConfig.duration = .forever
        SwiftMessages.show(view: error)
    }
    
    static func showMessage(_ title: String?,
                            body: String?,
                            theme: Theme,
                            layout: MessageView.Layout = .cardView,
                            presentationStyle: SwiftMessages.PresentationStyle = .top,
                            backgroundColor: UIColor? = nil) {
        let messageView = MessageView.viewFromNib(layout: layout)
        messageView.configureTheme(theme)
        messageView.configureContent(title: title, body: body, iconImage: self.iconImage(forTheme: theme), iconText: nil, buttonImage: nil, buttonTitle: nil, buttonTapHandler: nil)
        messageView.button?.isHidden = true
        if let backgroundColor = backgroundColor {
            messageView.backgroundView.backgroundColor = backgroundColor
        }
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = presentationStyle
        SwiftMessages.show(config: config, view: messageView)
    }
    
    static func showStatusLineMessage(_ title: String?,
                                      body: String?,
                                      theme: Theme,
                                      layout: MessageView.Layout = .statusLine,
                                      presentationStyle: SwiftMessages.PresentationStyle = .top, backgroundColor: UIColor? = nil) {
        let messageView = MessageView.viewFromNib(layout: layout)
        messageView.configureTheme(theme)
        messageView.configureContent(title: title, body: body, iconImage: self.iconImage(forTheme: theme), iconText: nil, buttonImage: nil, buttonTitle: nil, buttonTapHandler: nil)
        messageView.button?.isHidden = true
        if let backgroundColor = backgroundColor {
            messageView.backgroundView.backgroundColor = backgroundColor
        }
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = presentationStyle
        SwiftMessages.show(config: config, view: messageView)
    }
    
    
    // MARK: Images
    
    static func iconImage(forTheme theme: Theme) -> UIImage? {
        var image: UIImage?
        let imageSize: CGSize = CGSize(width: 25.0, height: 25.0)
        
        switch theme {
        case .info:
            
            image = UIImage(systemName: "info.circle.fill")?.imageWithSize(imageSize)
            image?.withTintColor(.white)
            
        case .success:
            
            image = UIImage(systemName: "checkmark.circle.fill")?.imageWithSize(imageSize).withRenderingMode(.alwaysOriginal)
            image?.withTintColor(.green)
            
        case .error:
            image = UIImage(systemName: "xmark.circle.fill")?.imageWithSize(imageSize).withRenderingMode(.alwaysOriginal)
            image?.withTintColor(.red)
            
        case .warning:

            image = UIImage(systemName: " exclamationmark.triangle.fill")?.imageWithSize(imageSize).withRenderingMode(.alwaysOriginal)
            image?.withTintColor(.yellow)
        }
        return image
    }
    
}

extension UIImage {
    func imageWithSize(_ size: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth:CGFloat = size.width / self.size.width
        let aspectHeight:CGFloat = size.height / self.size.height
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        self.draw(in: scaledImageRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}

extension UIAlertController {
    func addImage(image: UIImage) {
        let maxSize = CGSize(width: 245, height: 245)
        let imageSize = image.size
        
        var ratio: CGFloat!
        if (imageSize.width > imageSize.height) {
            ratio = maxSize.width / imageSize.width
        } else {
            ratio = maxSize.height / imageSize.height
        }
        let scaledSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        
        var resizedImage = image.imageWithSize(scaledSize)
        if (imageSize.height > imageSize.width) {
            let left = (maxSize.width - resizedImage.size.width) / 2
            resizedImage = resizedImage.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -left, bottom: 0, right: 0))
        }
        
        let imageAction = UIAlertAction(title: "", style: .default, handler: nil)
        imageAction.isEnabled = false
        imageAction.setValue(resizedImage.withRenderingMode(.alwaysOriginal), forKey: "image")
        self.addAction(imageAction)
    }
}
