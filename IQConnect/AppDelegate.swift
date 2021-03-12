//
//  AppDelegate.swift
//  IQConnect
//
//  Created by SuperDev on 06.01.2021.
//

import UIKit
import IQKeyboardManagerSwift
import Firebase
import SideMenuSwift
import Network
import OneSignal
import Siren
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    static var shared = UIApplication.shared.delegate as! AppDelegate
    
    weak var signInVC: SignInVC?
    weak var mainView: ApplicationStateObserver?
    var onConnectionsUpdate: (()->Void)?
    
    @available(iOS 12.0, *)
    lazy private(set) var monitor = NWPathMonitor()
    var canConnect = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        hyperCriticalRulesExample()
                
        // Remove this method to stop OneSignal Debugging
          OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)

          // OneSignal initialization
          OneSignal.initWithLaunchOptions(launchOptions)
          OneSignal.setAppId("fee8224f-8ddb-4b80-bc52-417acc0b30a8")

          // promptForPushNotifications will show the native iOS notification permission prompt.
          // We recommend removing the following code and instead using an In-App Message to prompt for notification permission (See step 8)
          OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
          })
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.disabledToolbarClasses = [MessagesVC.self]
        IQKeyboardManager.shared.disabledTouchResignedClasses = [MessagesVC.self]
        IQKeyboardManager.shared.disabledDistanceHandlingClasses = [MessagesVC.self]
        
        SideMenuController.preferences.basic.menuWidth = UIDevice.current.userInterfaceIdiom == .pad ? 500 : 300
        SideMenuController.preferences.basic.defaultCacheKey = "home"
        
        if #available(iOS 12.0, *) {
            monitor.pathUpdateHandler = { [weak self] path in
                if path.status == .satisfied {
                    print("Yay! We have internet!")
                    self?.canConnect = true
                } else {
                    print("No internet connection?")
                    self?.canConnect = false
                }
            }
            monitor.start(queue: DispatchQueue.global(qos: .background))
        }
        
        return true
    }

    func hyperCriticalRulesExample() {
           let siren = Siren.shared
           siren.rulesManager = RulesManager(globalRules: .critical,
                                             showAlertAfterCurrentVersionHasBeenReleasedForDays: 0)

           siren.wail { results in
               switch results {
               case .success(let updateResults):
                   print("AlertAction ", updateResults.alertAction)
                   print("Localization ", updateResults.localization)
                   print("Model ", updateResults.model)
                   print("UpdateType ", updateResults.updateType)
               case .failure(let error):
                   print(error.localizedDescription)
               }
           }
       }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func showSignInScreen() {
        if let signInVC = UIHelper.viewControllerWith("SignInVC", storyboardName: "Landing") {
            UIWindow.key?.rootViewController = signInVC
        }
    }
    
    func showMainScreen() {
        if let vc = UIHelper.viewControllerWith("SideMenu") {
            UIWindow.key?.rootViewController = vc
        }
    }

    // MARK: - Handle audio sessions
    struct holder {
        static var isAudioSessionActive = false
    }
    
    func startAudio() {
        // Each app running in iOS has a single audio session, which in turn has a single category. You can change your audio session’s category while your app is running.
        // You can refine the configuration provided by the AVAudioSessionCategoryPlayback, AVAudioSessionCategoryRecord, and AVAudioSessionCategoryPlayAndRecord categories by using an audio session mode, as described in Audio Session Modes.
        // https://developer.apple.com/reference/avfoundation/avaudiosession
        
        // While AVAudioSessionCategoryRecord works for the builtin mics and other bluetooth devices it did not work with AirPods. Instead, setting the category to AVAudioSessionCategoryPlayAndRecord allows recording to work with the AirPods.

        // AVAudioSession is completely managed by application, libmbl2 doesn't modify AVAudioSession settings.

        observeAudioSessionNotifications(true)
        activateAudioSession()
    }
    
    func activateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if #available (iOS 10.0, *) {
                try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetooth])
            } else {
                // https://stackoverflow.com/questions/52413107/avaudiosession-setcategory-availability-in-swift-4-2
                try AudioSessionHelper.setAudioSession()
            }
            try audioSession.setActive(true)
            holder.isAudioSessionActive = true
        } catch {
            holder.isAudioSessionActive = false
            print("activateAudioSession: \(error.localizedDescription)")
        }
        print("\(#function) isActive:\(holder.isAudioSessionActive), AVAudioSession Activated with category:\(audioSession.category)")
    }
    
    class var isAudioSessionActive: Bool {
        return holder.isAudioSessionActive
    }
    
    func stopAudio() {
        deactivateAudioSession()
        observeAudioSessionNotifications(false)
    }
    
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            holder.isAudioSessionActive = false
        } catch {
            print("deactivateAudioSession: \(error.localizedDescription)")
        }
        print("\(#function) isActive:\(holder.isAudioSessionActive)")
    }
    
    func observeAudioSessionNotifications(_ observe:Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        let center = NotificationCenter.default
        if observe {
            center.addObserver(self, selector: #selector(handleAudioSessionInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: audioSession)
            center.addObserver(self, selector: #selector(handleAudioSessionMediaServicesWereLost(notification:)), name: AVAudioSession.mediaServicesWereLostNotification, object: audioSession)
            center.addObserver(self, selector: #selector(handleAudioSessionMediaServicesWereReset(notification:)), name: AVAudioSession.mediaServicesWereResetNotification, object: audioSession)
        } else {
            center.removeObserver(self, name: AVAudioSession.interruptionNotification, object: audioSession)
            center.removeObserver(self, name: AVAudioSession.mediaServicesWereLostNotification, object: audioSession)
            center.removeObserver(self, name: AVAudioSession.mediaServicesWereResetNotification, object: audioSession)
        }
    }
    
    @objc func handleAudioSessionInterruption(notification: Notification) {
        
        if let value = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber, let interruptionType = AVAudioSession.InterruptionType(rawValue: UInt(value.intValue)) {
            
            let isAppActive = UIApplication.shared.applicationState == UIApplication.State.active ? true:false
            print("\(#function) [Main:\(Thread.isMainThread)] [Active:\(isAppActive)] AVAudioSession Interruption:\(String(describing: notification.object)) withInfo:\(String(describing: notification.userInfo))")
            
            switch interruptionType {
            case AVAudioSessionInterruptionType.began:
                deactivateAudioSession()
            case AVAudioSessionInterruptionType.ended:
                activateAudioSession()
            default:
                break
            }
        }
    }
    
    // MARK: Respond to the media server crashing and restarting
    // https://developer.apple.com/library/archive/qa/qa1749/_index.html
    
    @objc func handleAudioSessionMediaServicesWereLost(notification: Notification) {
        print("\(#function) [Main:\(Thread.isMainThread)] Object:\(String(describing: notification.object)) withInfo:\(String(describing: notification.userInfo))")
        mainView?.mediaServicesWereLost()
    }
    
    @objc func handleAudioSessionMediaServicesWereReset(notification: Notification) {
        print("\(#function) [Main:\(Thread.isMainThread)] Object:\(String(describing: notification.object)) withInfo:\(String(describing: notification.userInfo))")
        deactivateAudioSession()
        activateAudioSession()
        mainView?.mediaServicesWereReset()
    }
}

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}

