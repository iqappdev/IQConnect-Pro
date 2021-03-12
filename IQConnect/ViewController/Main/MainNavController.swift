//
//  MainNavController.swift
//  IQConnect
//
//  Created by SuperDev on 12.01.2021.
//

import UIKit
import SideMenuSwift

extension SideMenuController {
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return self.contentViewController.supportedInterfaceOrientations
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.contentViewController.preferredInterfaceOrientationForPresentation
    }
    
    override open var shouldAutorotate: Bool {
        return self.contentViewController.shouldAutorotate
    }
}

class MainNavController: UINavigationController {
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get {
            if visibleViewController is LiveBroadcastVC {
                //DDLogVerbose("ViewController")
                return .landscapeRight
            }
            return .portrait
        }
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        get {
            if visibleViewController is LiveBroadcastVC {
                //DDLogVerbose("ViewController")
                return .landscapeRight
            }
            return .portrait
        }
    }
    
    override open var shouldAutorotate : Bool {
        get {
            return true
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
