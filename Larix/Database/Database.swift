import GRDB
import UIKit

// The shared database queue
var dbQueue: DatabaseQueue!

func setupDatabase(_ application: UIApplication) throws {
    
    // Connect to the database
    // See https://github.com/groue/GRDB.swift/#database-connections
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
    let databasePath = documentsPath.appendingPathComponent("db.sqlite")
    dbQueue = try DatabaseQueue(path: databasePath)
    
    // Use DatabaseMigrator to setup the database
    // See https://github.com/groue/GRDB.swift/#migrations
    
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("v1") { db in
        
        // Create a table
        // See https://github.com/groue/GRDB.swift#create-tables
        
        try db.create(table: "connections") { t in
            // An integer primary key auto-generates unique IDs
            t.column("id", .integer).primaryKey()
            
            // Sort connection names in a localized case insensitive fashion by default
            // See https://github.com/groue/GRDB.swift/#unicode
            t.column("name", .text).notNull().collate(.localizedCaseInsensitiveCompare)
            t.column("url", .text).notNull().collate(.localizedCaseInsensitiveCompare)
            t.column("mode", .integer).notNull()
            t.column("active", .boolean).notNull()
            t.column("auth", .integer).notNull()
            t.column("username", .text).collate(.localizedCompare)
            t.column("password", .text).collate(.localizedCompare)            
        }
    }

    migrator.registerMigration("import") { db in

        struct ConnectionV1: PersistableRecord, Encodable {
            static let databaseTableName = "connections"
            var name: String
            var url: String
            var mode: Int32
            var active: Bool
            var auth: Int32
            var username: String?
            var password: String?
        }

        //var prefStr: String?
        //prefStr = "rtsp://user:password@192.168.1.46:554/live/myStream"
        //prefStr = "rtmp://user:password@192.168.1.46/live/myStream"

        let prefStr = UserDefaults.standard.string(forKey: "connectionUri0")

        if let str = prefStr, let url = URL(string: str) {
            let connUri = ConnectionUri(url: url)
            if let uri = connUri.uri, let scheme = connUri.scheme {
                let name = connUri.host ?? "Connection #0"
                var connection = ConnectionV1(name: name,
                                              url: uri,
                                              mode: ConnectionMode.videoAudio.rawValue,
                                              active: true,
                                              auth: ConnectionAuthMode.default.rawValue,
                                              username: nil,
                                              password: nil)
                if scheme == "rtsp", let username = connUri.username, let password = connUri.password {
                    connection.username = username
                    connection.password = password
                }
                try connection.insert(db)
            }
        }
    }

    migrator.registerMigration("v2") { db in

        try db.alter(table: "connections") { t in
            t.add(column: "passphrase", .text).collate(.localizedCompare)
            t.add(column: "pbkeylen", .integer).notNull().defaults(to: 16)
            t.add(column: "latency", .integer).notNull().defaults(to: 0)
            t.add(column: "maxbw", .integer).notNull().defaults(to: 0)
        }
    }
    
    // New GRDB 3 migration:
    // - Rename tables so that they look like Swift identifiers (singular and camelCased)
    // - Make integer primary keys auto-incremented
    migrator.registerMigration("GRDB3") { db in

        try db.create(table: "connection") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull().collate(.localizedCaseInsensitiveCompare)
            t.column("url", .text).notNull().collate(.localizedCaseInsensitiveCompare)
            t.column("mode", .integer).notNull()
            t.column("active", .boolean).notNull()
            t.column("auth", .integer).notNull()
            t.column("username", .text).collate(.localizedCompare)
            t.column("password", .text).collate(.localizedCompare)
            t.column("passphrase", .text).collate(.localizedCompare)
            t.column("pbkeylen", .integer).notNull()
            t.column("latency", .integer).notNull()
            t.column("maxbw", .integer).notNull()
        }
        try db.execute(sql: """
        INSERT INTO connection SELECT * FROM connections;
        """)
        try db.drop(table: "connections")
    }
    
    migrator.registerMigration("v3") { db in

        try db.alter(table: "connection") { t in
            t.add(column: "streamid", .text).collate(.localizedCompare)
        }
    }

    migrator.registerMigration("v4") { db in

        try db.alter(table: "connection") { t in
            t.add(column: "rist_profile", .integer).notNull().defaults(to: 1)
        }
    }
    
    migrator.registerMigration("incoming_v1") { db in
        try db.create(table: "incoming_connection") { t in

            t.column("id", .integer).primaryKey(autoincrement: true)
            t.column("active", .boolean).notNull()
            t.column("name", .text).notNull().collate(.localizedCaseInsensitiveCompare)
            t.column("url", .text).notNull().collate(.localizedCaseInsensitiveCompare)
            t.column("mode", .integer).notNull()
            t.column("srt_connect_mode", .integer).notNull().defaults(to: 1)
            t.column("passphrase", .text).collate(.localizedCompare)
            t.column("pbkeylen", .integer).notNull().defaults(to: 16)
            t.column("latency", .integer).notNull().defaults(to: 0)
            t.column("streamid", .text).collate(.localizedCompare)
            t.column("rist_profile", .integer).notNull().defaults(to: 1)
            t.column("buffering", .integer).notNull().defaults(to: 500)
            t.column("offset", .integer).notNull().defaults(to: 0)
        }
        
        try db.alter(table: "connection") { t in
            t.add(column: "srt_connect_mode", .integer).notNull().defaults(to: 0)
            t.add(column: "retransmit_algo", .integer).notNull().defaults(to: 0)

        }
    }

    
    /*
    migrator.registerMigration("teste") { db in
        try Connection(name: "wowza", url: "rtmp://192.168.1.46:1935/live/myStream", mode: ConnectionMode.videoAudio, active: true).insert(db)
        try Connection(name: "nimble", url: "rtmp://192.168.1.46:1937/live/stream", mode: ConnectionMode.videoAudio, active: true).insert(db)
        try Connection(name: "rtsp", url: "rtsp://larix:larix@104.236.22.65:554/larix/sales", mode: ConnectionMode.videoAudio, active: true).insert(db)
    }

    migrator.registerMigration("randomize") { db in
        // Populate the persons table with random data
        for _ in 0..<8 {
            try Connection(name: Connection.randomName(), url: "rtmp://192.168.1.46:1935/live/myStream", mode: ConnectionMode.videoAudio, active: false).insert(db)
        }
    }
*/
    try migrator.migrate(dbQueue)
}
