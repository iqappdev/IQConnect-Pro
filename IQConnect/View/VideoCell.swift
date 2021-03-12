//
//  VideoCell.swift
//  IQConnect
//
//  Created by SuperDev on 18.01.2021.
//

import UIKit
import AVKit

protocol VideoCellDelegate: class {
    func onDeleteAction(_ file: VideoFile)
    func onRenameAction(_ file: VideoFile)
    func onUploadAction(_ file: VideoFile)
    func onShareAction(_ file: VideoFile, on button: UIButton)
}

class VideoCell: UITableViewCell {

    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    weak var delegate: VideoCellDelegate?

    var file: VideoFile? {
        didSet {
            guard let file = file else { return }
            
            thumbImageView.image = file.videoThumbnail
            filenameLabel.text = file.url.lastPathComponent
            
            dateLabel.text = ""
            if let attrs = try? file.url.resourceValues(forKeys: [.creationDateKey]) {
                if let date = attrs.creationDate {
                    let dateFmt = DateFormatter()
                    dateFmt.dateStyle = .medium
                    dateFmt.timeStyle = .short
                    dateFmt.doesRelativeDateFormatting = true
                    dateLabel.text = dateFmt.string(from: date)
                }
            }
            
            self.durationLabel.text = file.videoDuration
        }
    }
    
    @IBAction func onVideoClick(_ sender: UIButton) {
        guard let file = file else { return }
        
        if file.url.pathExtension == "mov" {
            let player = AVPlayer(url: file.url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.parentViewController?.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
    }
    
    @IBAction func onMoreButtonClick(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Upload", style: .default, handler: { (_) in
            if let file = self.file {
                self.delegate?.onUploadAction(file)
            }
        }))
        alert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { (_) in
            if let file = self.file {
                self.delegate?.onRenameAction(file)
            }
        }))
        alert.addAction(UIAlertAction(title: "Share", style: .default, handler: { (_) in
            if let file = self.file {
                self.delegate?.onShareAction(file, on: sender)
            }
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
            if let file = self.file {
                self.delegate?.onDeleteAction(file)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.sourceView = sender.superview
        alert.popoverPresentationController?.sourceRect = sender.frame
        self.parentViewController?.present(alert, animated: true, completion: nil)
    }
    
}
