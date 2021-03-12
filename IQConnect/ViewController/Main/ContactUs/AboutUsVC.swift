//
//  AboutUsVC.swift
//  IQConnect
//
//  Created by SuperDev on 13.01.2021.
//

import UIKit
import WebKit

class AboutUsVC: UIViewController {
    
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var mapWebView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributedString = messageTextView.attributedText.mutableCopy() as! NSMutableAttributedString
        attributedString.mutableString.replaceOccurrences(of: "mcr@iqbroadcast.tv", with: SharedManager.sharedInstance.getContactEmail(), range: NSMakeRange(0, attributedString.mutableString.length))
        messageTextView.attributedText = attributedString
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mapWebView.loadHTMLString("<iframe src=\"https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2483.4441446986702!2d-0.022865183913129923!3d51.50506717963465!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x487603402d46423f%3A0x486ff1cece819d88!2sIQ+SAT!5e0!3m2!1sen!2sin!4v1543581236848\" width=\"100%\" height=\"100%\" frameborder=\"0\" style=\"border:0\" allowfullscreen></iframe>", baseURL: nil)
    }
    
    @IBAction func onMenuButtonClick(_ sender: UIButton) {
        self.view.endEditing(true)
        sideMenuController?.revealMenu()
    }


}
