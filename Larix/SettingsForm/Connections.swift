import CocoaLumberjack
import Eureka
import GRDB
import Toaster

extension BaseConnection {
    func dump() {
        DDLogVerbose(self.name)
        DDLogVerbose(self.url)
        DDLogVerbose("\(self.active)")
        let mode = ConnectionMode.init(rawValue: self.mode)
        if mode == ConnectionMode.audioOnly {
            DDLogVerbose("ConnectionMode.audioOnly")
        }
        if mode == ConnectionMode.videoOnly {
            DDLogVerbose("ConnectionMode.videoOnly")
        }
        if mode == ConnectionMode.videoAudio {
            DDLogVerbose("ConnectionMode.videoAudio")
        }
    }
}

class BaseConnectionListController<Record>: FormViewController where Record: BaseConnection {
    var activeCount = 0
    var needRefresh = false
    var idList: [Int64] = []
    
    @objc func addButtonPressed(_ sender: UIBarButtonItem) {
        let holder = DataHolder.sharedInstance
        let conn = Record()
        holder.connecion = conn
        if let editorView = createEditor() {
            self.navigationController?.pushViewController(editorView, animated: true)
        }
    }
    
    @objc func editAction(barButtonItem: UIBarButtonItem) {
        //self.performSegue(withIdentifier: "openConnectionManager", sender: self)
        if let editorView = createManager() {
            self.navigationController?.pushViewController(editorView, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initForm()

        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let edit = UIBarButtonItem(title: NSLocalizedString("Manage", comment: ""), style: .plain, target: self, action: #selector(editAction(barButtonItem:)))
        toolbarItems = [flexible, edit]
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addButtonPressed(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isToolbarHidden = true
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.onConnectionsUpdate = nil
        needRefresh = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if needRefresh {
            updateList()
            needRefresh = false
        }
    }
    
    internal func updateList() {

        guard var section = form.sectionBy(tag: "connections") else { return }
        tableView?.beginUpdates()
        let connections = dbQueue.read { db in
            try! Record.order(Column("name").asc).fetchAll(db)
        }
        if connections.count < section.count {
            let deleteRange = connections.count..<section.count
            for _ in deleteRange {
                section.removeLast()
            }
            //section.removeSubrange(deleteRange)
        }
        let rowCount = section.count
        for i in 0..<connections.count {
            let conn = connections[i]
            if i < rowCount {
                if let row = section[i] as? CheckRow {
                    setupRecord(row, conn: conn)
                }
            } else {
                section <<< CheckRow() { self.setupRecord($0, conn: conn) }
                    .onChange(self.onCheck)
            }
        }
        tableView?.endUpdates()

        idList = connections.map { $0.id ?? 0 }
        self.navigationController?.isToolbarHidden = connections.isEmpty
    }
    
    
    internal func initForm() {
        
        let connections = dbQueue.read { db in
            try! Record.order(Column("name").asc).fetchAll(db)
        }

        let section = Section() {
            $0.tag = "connections"
        }
        for c in connections {
            //c.dump()
            section
                <<< CheckRow() { self.setupRecord($0, conn: c) }
                .onChange(self.onCheck)
        }
        
        form +++ section
        if connections.count > 0 {
            navigationController?.isToolbarHidden = false
        }
        idList = connections.map { $0.id ?? 0 }

    }
    
    internal func setupRecord(_ row: CheckRow, conn: Record) {
        let deleteAction = SwipeAction(
            style: .destructive,
            title: NSLocalizedString("Delete", comment: ""),
            handler: { (action, row, completionHandler) in
                if let i = row.indexPath?.row, i < self.idList.count {
                    let id = self.idList[i]
                    var connection: Record?
                    dbQueue.read { db in
                        connection = try! Record.fetchOne(db, key: id)
                    }
                    if let connection = connection {
                        _ = try! dbQueue.write { db in
                            try! connection.delete(db)
                        }
                        dbQueue.read { db in
                            try! self.activeCount = Record.filter(sql: "active=?", arguments: ["1"]).order(Column("name")).fetchCount(db)
                            let count = try! Record.fetchCount(db)
                            if count == 0 {
                                self.navigationController?.isToolbarHidden = true
                            }
                        }
                        let message = String.localizedStringWithFormat(NSLocalizedString("Deleted: \"%@\"", comment: ""), connection.name)
                        Toast(text: message).show()
                    }
                    self.idList.remove(at: i)
                }
                completionHandler?(true)
        })
        let editAction = SwipeAction(
            style: .normal,
            title: NSLocalizedString("Edit", comment: ""),
            handler: { (action, row, completionHandler) in
                guard let i = row.indexPath?.row, i < self.idList.count else {
                    completionHandler?(false)
                    return
                }
                let id = self.idList[i]
                let holder = DataHolder.sharedInstance
                let connection = dbQueue.read { db in
                    try? Record.fetchOne(db, key: id)
                }
                if let conn = connection {
                    holder.connecion = conn
                    if let editorView = self.createEditor() {
                        self.navigationController?.pushViewController(editorView, animated: true)
                    }
                }
                completionHandler?(true)
        })
        

        row.title = conn.name
        row.value = conn.active
        if row.tag?.isEmpty != false {
            row.tag = UUID().uuidString
        }

        row.trailingSwipe.actions = [deleteAction, editAction]
        row.trailingSwipe.performsFirstActionWithFullSwipe = true
    }
    
    internal func onCheck(row: CheckRow) {
        
    }
    
    internal func createEditor() -> FormViewController? {
        return nil
    }

    internal func createManager() -> FormViewController? {
        return nil
    }

}

class ConnectionsViewController: BaseConnectionListController<Connection> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Connections", comment: "")
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.onConnectionsUpdate = {[weak self] in
            self?.updateList()
        }
    }
    
    override func initForm() {
        super.initForm()
        
        form +++ Section()
            <<< ButtonRow() {
                $0.title = NSLocalizedString("Import Grove setting", comment: "")
                $0.onCellSelection { (_, _) in
                    self.performSegue(withIdentifier: "openImportGrove", sender: self)
                }
            }
            <<< ButtonRow() {
                $0.title = NSLocalizedString("Export Grove settings", comment: "")
                $0.onCellSelection { (_, _) in
                    self.performSegue(withIdentifier: "openExportGrove", sender: self)
                }
            }

        form +++ Section()
            <<< ButtonRow() {
                $0.title = NSLocalizedString("Watch video tutorial", comment: "")
                $0.onCellSelection { (_, _) in
                    if let url = URL(string: "https://www.youtube.com/watch?v=Dhj0_QbtfTw") {
                        UIApplication.shared.open(url, options: [:])
                    }
                }
            }
    }
    
    override func setupRecord(_ row: CheckRow, conn: Connection) {
        super.setupRecord(row, conn: conn)
        if #available(iOS 11.0, *) {

            let shareAction = SwipeAction(
                style: .normal,
                title: NSLocalizedString("Grove", comment: ""),
                handler: { (action, row, completionHandler) in
                    if let i = row.indexPath?.row, i < self.idList.count {
                        let id =  self.idList[i]
                        let record = dbQueue.read { db in
                            try? Connection.filter(key: id).fetchOne(db)
                        }
                        if let conn = record {
                            let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
                            if let exportView = storyboard.instantiateViewController(withIdentifier: "exportGrove") as? ExportGroveController {
                                exportView.enableSelection = false
                                exportView.connections = [conn]
                                exportView.selectedConnections = [0]
                                self.navigationController?.pushViewController(exportView, animated: true)
                            }
                        }
                    }
                    completionHandler?(true)
            })
            row.leadingSwipe.actions = [shareAction]
        }
    }
    
    override func onCheck(row: CheckRow) {
        if let active = row.value, let i = row.indexPath?.row {
            if !active {
                // deselection
                let id = idList[i]
                try! dbQueue.write { db in
                    let connection = try! Connection.fetchOne(db, key: id)
                    connection?.active = false
                    try! connection?.update(db)
                }
            } else {
                if self.activeCount < 3 {
                    let id = idList[i]
                    try! dbQueue.write { db in
                        let connection = try! Connection.fetchOne(db, key: id)
                        connection?.active = true
                        try! connection?.update(db)
                    }
                } else {
                    row.value = false
                    let message = NSLocalizedString("Maximum count of simultaneous connections is 3.", comment: "")
                    Toast(text: message).show()
                }
            }
        }
        dbQueue.read { db in
            try! self.activeCount = Connection.filter(sql: "active=?", arguments: ["1"]).fetchCount(db)
        }
    }
    
    override func createEditor() -> FormViewController? {
        return ConnectionEditorViewController()
    }

    override func createManager() -> FormViewController? {
        return ConnectionManagerViewController()
    }

}

