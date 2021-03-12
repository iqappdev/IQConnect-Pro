import Foundation
import Eureka

class RecordSettingsViewController: BundleSettingsViewController {
    
    override func loadSettings() {
        super.loadSettings()
        if let section = form.allSections.first {
            section <<< TextAreaRow() {
                $0.value = NSLocalizedString("Stream could be recorded only while application is in foreground due to iOS restrictions", comment: "")
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 20.0)
                $0.hidden = Condition.function(["pref_record_stream"], { _ in
                    !(LarixSettings.sharedInstance.radioMode && LarixSettings.sharedInstance.record)
                })
            }.cellSetup { (cell, row) in
                row.textAreaMode = .readOnly
                cell.textView.font = .systemFont(ofSize: 14)
            }
        }
    }
    
    override func getHideCondition(tag: String) -> Condition? {
        if tag == "pref_record_duration" {
            return Condition.function(["pref_record_stream"], { form in
                if let record = form.rowBy(tag: "pref_record_stream") as? SwitchRow {
                    return record.value != true
                }
                return true
            })
        }
        return nil
    }
}
