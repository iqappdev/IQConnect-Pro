//
//  VideoCell.swift
//  IQConnect
//
//  Created by SuperDev on 08.01.2021.
//

import UIKit
import CircleProgressBar

class UploadingFileCell: UITableViewCell {
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var progressBar: CircleProgressBar!
    @IBOutlet weak var successImageView: UIImageView!
    @IBOutlet weak var failureImageView: UIImageView!
    
    var file: UploadFile? {
        didSet {
            guard let file = file else { return }
            
            //thumbnail
            let ext = file.url.pathExtension
            switch ext {
            case "jpg", "heic":
                thumbImageView.image = try? UIImage(url: file.url)
            case "mov":
                thumbImageView.image = file.url.thumbnail()
            case "m4a":
                thumbImageView.image = UIImage(systemName: "mic")
            default:
                thumbImageView.image = UIImage(systemName: "doc")
            }
            
            // file name
            filenameLabel.text = file.url.lastPathComponent
            
            // file size
            var fileSizeStr = ""
            if let attrs = try? file.url.resourceValues(forKeys: [.fileSizeKey]) {
                let size = attrs.fileSize ?? 0
                fileSizeStr = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
            fileSizeLabel.text = fileSizeStr
            
            // status
            switch file.status {
            case .uploading:
                if progressBar.isHidden {
                    progressBar.isHidden = false
                }
                progressBar.setProgress(file.progress, animated: false)
                successImageView.isHidden = true
                failureImageView.isHidden = true
            case .success:
                successImageView.isHidden = false
                progressBar.isHidden = true
                failureImageView.isHidden = true
            case .failure:
                failureImageView.isHidden = false
                progressBar.isHidden = true
                successImageView.isHidden = true
            case .none:
                progressBar.isHidden = false
                progressBar.setProgress(0, animated: false)
                successImageView.isHidden = true
                failureImageView.isHidden = true
            }
        }
    }
}
