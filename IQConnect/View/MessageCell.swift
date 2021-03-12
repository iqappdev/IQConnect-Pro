//
//  MessageCell.swift
//  IQConnect
//
//  Created by SuperDev on 13.01.2021.
//

import UIKit

protocol MessageCellDelegate: class {
    func onEditAction(_ message: Message)
    func onDeleteAction(_ message: Message)
    func onMessageClickAction(_ message: Message)
}

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    weak var delegate: MessageCellDelegate?

    var message: Message? {
        didSet {
            guard let message = message else { return }
            messageLabel.text = message.msg
        }
    }
    
    @IBAction func onItemClick(_ sender: UIButton) {
        if let message = self.message {
            self.delegate?.onMessageClickAction(message)
        }
    }

    @IBAction func onMoreButtonClick(_ sender: UIButton) {
        self.parentViewController?.view.endEditing(true)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { (_) in
            if let message = self.message {
                self.delegate?.onEditAction(message)
            }
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            if let message = self.message {
                self.delegate?.onDeleteAction(message)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.sourceView = sender.superview
        alert.popoverPresentationController?.sourceRect = sender.frame
        self.parentViewController?.present(alert, animated: true, completion: nil)
    }
}
