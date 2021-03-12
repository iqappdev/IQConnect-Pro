import Foundation
import GRDB
import UIKit
import Toaster

class ExportGroveController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var linkTextView: UITextView!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var itemsTableView: UITableView!
    
    var connections: [Connection] = []
    var selectedParams: Set<Int> = []
    var selectedConnections: Set<Int> = []
    var enableSelection: Bool = true
    let paramsSection = ["Video", "Audio", "Record"]
    let videoParamIndex = 0
    let audioParmIndex = 1
    let recordParmIndex = 2
    
    override open var shouldAutorotate: Bool {
       return false
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       return .portrait
    }
    
    @IBAction func onCopyClick(_ sender: Any) {
        if let text = linkTextView.text, let url = URL(string: text) {
            let pb = UIPasteboard.general
            pb.url = url
            let message = NSLocalizedString("Link copied", comment: "")
            Toast(text: message).show()
        }
    }

    @IBAction func onShareClick(_ sender: Any) {
        let description = NSLocalizedString("Larix Grove link", comment: "")
        let url: NSURL = NSURL(string: linkTextView.text)!
        
        let shareController = UIActivityViewController(activityItems: [description, url], applicationActivities: nil)
        
        // This lines is for the popover you need to show in iPad
        shareController.popoverPresentationController?.sourceView = (sender as! UIButton)
        
        if #available(iOS 13.0, *) {
            // Pre-configuring activity items
            shareController.activityItemsConfiguration = [
                UIActivity.ActivityType.message,
                UIActivity.ActivityType.mail
            ] as? UIActivityItemsConfigurationReading
            
            shareController.isModalInPresentation = true
        }
        self.present(shareController, animated: true, completion: nil)
    }
    
    override func loadView() {
        super.loadView()
        if enableSelection {
            itemsTableView.dataSource = self
            itemsTableView.delegate = self
        } else {
            itemsTableView.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        linkTextView.textContainer.maximumNumberOfLines = 1
        linkTextView.textContainer.lineBreakMode = .byClipping
        if enableSelection {
            connections = dbQueue.read { db in
                try! Connection.order(Column("name").asc).fetchAll(db)
            }
            selectedConnections.removeAll()
            for i in 0..<connections.count {
                if connections[i].active {
                    selectedConnections.insert(i)
                }
            }
        }
        updateQr()
    }
    
    func updateQr() {
        let linkStr = generateLink()
        linkTextView.text = linkStr
        let data = linkStr.data(using: String.Encoding.utf8)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 2, y: 2)

            if let output = filter.outputImage?.transformed(by: transform) {
                qrImageView.image = UIImage(ciImage: output)
            }
        }
    }
    
    func generateLink() -> String {
        
        guard var urlData = URLComponents(string: "larix://set/v1") else { return "" }
        var parsms: [URLQueryItem] = []
        if selectedParams.contains(videoParamIndex) {
            parsms += LarixSettings.sharedInstance.groveVideoConfig()
        }
        if selectedParams.contains(audioParmIndex) {
            parsms += LarixSettings.sharedInstance.groveAudioConfig()
        }
        if selectedParams.contains(recordParmIndex) {
            parsms += LarixSettings.sharedInstance.groveRecordConfig()
        }
        for i in selectedConnections {
            let conn = connections[i]
            parsms += conn.toGrove()
        }
        urlData.queryItems = parsms
        return urlData.string ?? ""
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? paramsSection.count : connections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = section == 0 ? "Parameters" : "Connections"
        return NSLocalizedString(title, comment: "")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var title: String = ""
        var selected:Bool = true
        if indexPath.section == 0 {
            title = paramsSection[indexPath.row]
            selected = selectedParams.contains(indexPath.row)
        } else {
            let record = connections[indexPath.row]
            title = record.name
            selected = selectedConnections.contains(indexPath.row)
        }
        let cell = UITableViewCell(style: .default, reuseIdentifier: "row")
        cell.textLabel?.text = title
        cell.accessoryType = selected ? .checkmark : .none
        cell.setSelected(selected, animated: false)
        cell.selectionStyle = .none
        return cell

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemsTableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        if indexPath.section == 0 {
            selectedParams.insert(indexPath.row)
        } else {
            selectedConnections.insert(indexPath.row)
        }
        updateQr()
      }

      func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        itemsTableView.cellForRow(at: indexPath)?.accessoryType = .none
        if indexPath.section == 0 {
            selectedParams.remove(indexPath.row)
        } else {
            selectedConnections.remove(indexPath.row)
        }
        updateQr()
      }

}
