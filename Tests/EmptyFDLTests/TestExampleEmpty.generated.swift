// DO NOT EDIT -- file automatically generated by CausalLabsSDK.
// https://www.causallabs.io

// swiftformat:disable all
// swiftlint:disable all

import CausalLabsSDK
import Foundation
import SwiftUI

private func encodeObject<T: Codable>(_ object: T) throws -> JSONObject {
    let data = try JSONEncoder().encode(object)
    let jsonObject = try JSONSerialization.jsonObject(with: data) as? JSONObject
    return jsonObject ?? [:]
}

private func decodeObject<T: Codable>(from jsonObject: JSONObject, to type: T.Type) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: jsonObject)
    return try JSONDecoder().decode(T.self, from: data)
}

private struct _IdObject<T: Codable>: Codable {
    var name: String
    var args: T
}

private func generateIdFrom<T: Codable>(name: String, args: T) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    let idObject = _IdObject(name: name, args: args)
    if let jsonData = try? encoder.encode(idObject),
       let id = String(data: jsonData, encoding: .utf8) {
        return id
    }
    return "invalidFeatureId"
}


// MARK: - ImpressionTime

struct ImpressionTime: Hashable, Codable {
    var impressionId: String

    var impressionTime: Int

}

// MARK: - Session

private struct _SessionOutputs: Codable, Hashable {
}

private struct _SessionArgs: Codable, Hashable {
    var deviceId: String?
}

private struct _SessionKeys: Codable, Hashable {
    var deviceId: String?
}


struct Session: SessionProtocol {
    var persistentId: DeviceId? {
        self.deviceId
    }

    // MARK: Arguments

    private var _args: _SessionArgs

    var deviceId: String? {
        _args.deviceId
    }

    // MARK: Outputs

    private var _outputs: _SessionOutputs = _SessionOutputs()


    init(deviceId: String) {
        self._args = _SessionArgs(deviceId:deviceId)
    }

    var id: SessionId {
        generateIdFrom(name: "session", args: self._args)
    }

    func keys() throws -> JSONObject {
        let keys = _SessionKeys(deviceId:_args.deviceId)
        return try encodeObject(keys)
    }

    func args() throws -> JSONObject {
        try encodeObject(self._args)
    }

    mutating func updateFrom(json: JSONObject) throws {
        self._args = try decodeObject(from: json, to: _SessionArgs.self)
        self._outputs = try decodeObject(from: json, to: _SessionOutputs.self)
    }
}

extension Session {
    private init(_args: _SessionArgs) {
        self._args = _args
    }

    static func fromDeviceId(_ deviceId: String) -> Session {
        Session(_args: _SessionArgs(deviceId: deviceId))
    }

}

// MARK: Session Events

extension Session {
    /// Details all possible session events
    enum Event: SessionEventProvider {

        var eventDetails: any SessionEvent {
            switch self {
            }
        }     
    }
}

extension CausalClientProtocol {
    /// Signal a session event occurred to the impression service.
    ///
    /// An alternative to `signalAndWait(sessionEvent:)` that is "fire-and-forget" and ignores errors.
    ///
    /// - Parameter sessionEvent: The session event that occurred.    
    func signal(sessionEvent: Session.Event) {
        signal(sessionEvent: sessionEvent.eventDetails)
    }

    /// Signal a session event occurred to the impression service.
    ///
    /// - Parameter sessionEvent: The session event that occurred.
    func signalAndWait(sessionEvent: Session.Event) async throws {
        try await signalAndWait(sessionEvent: sessionEvent.eventDetails)
    }    
}



// swiftformat:enable all
// swiftlint:enable all
