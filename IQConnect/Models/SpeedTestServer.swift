//
//  SpeedTestServer.swift
//  IQConnect
//
//  Created by SuperDev on 10.01.2021.
//

import UIKit
import SWXMLHash

public struct SpeedTestServer: XMLIndexerDeserializable {
    public let url: String
    public let lat: Double
    public let lon: Double
    public let name: String
    public let country: String
    public let cc: String
    public let sponsor: String
    public let id: Int
    public let host: String
    
    public static func deserialize(_ node: XMLIndexer) throws -> SpeedTestServer {
        return try SpeedTestServer(
            url: node.value(ofAttribute: "url"),
            lat: node.value(ofAttribute: "lat"),
            lon: node.value(ofAttribute: "lon"),
            name: node.value(ofAttribute: "name"),
            country: node.value(ofAttribute: "country"),
            cc: node.value(ofAttribute: "cc"),
            sponsor: node.value(ofAttribute: "sponsor"),
            id: node.value(ofAttribute: "id"),
            host: node.value(ofAttribute: "host")
        )
    }
}
