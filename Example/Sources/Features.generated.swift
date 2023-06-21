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
    var deviceId: String
}

private struct _SessionKeys: Codable, Hashable {
    var deviceId: String
}


struct Session: SessionProtocol {
    // MARK: Arguments

    private var _args: _SessionArgs

    var deviceId: String {
        _args.deviceId
    }

    // MARK: Outputs

    private var _outputs: _SessionOutputs = _SessionOutputs()


    init(deviceId: String) {
        self._args = _SessionArgs(deviceId:deviceId)
    }

    var id: SessionId {
        generateIdFrom(name: "Session", args: self._args)
    }

    func keys() throws -> JSONObject {
        let keys = _SessionKeys(deviceId:_args.deviceId)
        return try encodeObject(keys)
    }

    func args() throws -> JSONObject {
        try encodeObject(self._args)
    }

    mutating func updateFrom(json: JSONObject) throws {
        self._outputs = try decodeObject(from: json, to: _SessionOutputs.self)
    }
}

// MARK: Session Events


// MARK: - RatingBox

private struct _RatingBoxOutputs: Codable, Hashable {
    var callToAction: String = "Rate this product!"
    var actionButton: String = "Send Review"
    var impressionIds: [ImpressionId] = []
}

private struct _RatingBoxArgs: Codable, Hashable {
    var product: String
}

/// Describes a rating box that we can put on various product pages
/// to collect ratings from our users.
struct RatingBox: FeatureProtocol {
    static let name = "RatingBox"

    var isActive = true

    var impressionIds: [ImpressionId] {
        get {
            self._outputs.impressionIds
        }
        set {
            self._outputs.impressionIds = newValue
        }
    }

    // MARK: Arguments
    private var _args: _RatingBoxArgs

    /// The product for which we are collecting ratings.
    var product: String {
        self._args.product
    }

    // MARK: Outputs

    private var _outputs: _RatingBoxOutputs = _RatingBoxOutputs()

    /// The prompts for the user to rate the product.
    var callToAction: String {
        self._outputs.callToAction
    }
    /// The button text for the user submit a review.
    var actionButton: String {
        self._outputs.actionButton
    }

    // MARK: Initializer
    init(product: String = "") {
        self._args = _RatingBoxArgs(product: product)
    }

    var id: FeatureId {
        generateIdFrom(name: "RatingBox", args: self._args)
    }

    // MARK: FeatureProtocol
    func args() throws -> JSONObject {
        try encodeObject(self._args)
    }

    mutating func updateFrom(json: JSONObject) throws {
        self._outputs = try decodeObject(from: json, to: _RatingBoxOutputs.self)
    }
}

// MARK: RatingBox Events

// MARK: - Rating
extension RatingBox {
    /// Occurs each time a rating is collected.
    struct Rating: EventProtocol {
        /// The name of the feature for which this event is associated.
        public static let featureName = "RatingBox"

        /// The name of this event.
        public static let name = "Rating"

        var stars: Int

        func serialized() throws -> JSONObject {
            let json = try encodeObject(self)
            return json
        }
    }

    /// - Parameter stars: 
    /// - Throws: A ``CausalError``.
    func signalRating(stars: Int) async throws {
        let event = Rating(stars: stars)
        try await CausalClient.shared.signalEvent(
            event: event,
            impressionId: self.impressionIds.first ?? ""
        )
    }
}

// MARK: - RatingBox View Model

final class RatingBoxViewModel: ObservableObject, FeatureViewModel {
    @Published var feature: RatingBox?

    // MARK: Arguments

    let product: String
    let impressionId: ImpressionId

    // MARK: Init

    init(product: String="", impressionId: ImpressionId = .newId()) {
        self.product = product
        self.impressionId = impressionId
    }

    // MARK: Feature request

    @MainActor
    func requestFeature() async throws {
        var _feature = RatingBox(product: self.product)
        _feature.impressionIds = [self.impressionId]

        do {
            self.feature = try await CausalClient.shared.requestFeature(
                feature: _feature,
                impressionId: self.impressionId
            )
        } catch {
            self.feature = _feature
            throw error
        }
    }

    // MARK: Events

    func signalRating(stars: Int, onError: ((Error) -> Void)? = nil) {
        Task {
            do {
                try await self.feature?.signalRating(stars: stars)
            } catch {
                onError?(error)
            }
        }
    }
}

// MARK: - ProductInfo

private struct _ProductInfoOutputs: Codable, Hashable {
    var impressionIds: [ImpressionId] = []
}

private struct _ProductInfoArgs: Codable, Hashable {
}

/// An empty feature to use only as a kill switch
struct ProductInfo: FeatureProtocol {
    static let name = "ProductInfo"

    var isActive = true

    var impressionIds: [ImpressionId] {
        get {
            self._outputs.impressionIds
        }
        set {
            self._outputs.impressionIds = newValue
        }
    }

    // MARK: Arguments
    private var _args: _ProductInfoArgs


    // MARK: Outputs

    private var _outputs: _ProductInfoOutputs = _ProductInfoOutputs()


    // MARK: Initializer
    init() {
        self._args = _ProductInfoArgs()
    }

    var id: FeatureId {
        generateIdFrom(name: "ProductInfo", args: self._args)
    }

    // MARK: FeatureProtocol
    func args() throws -> JSONObject {
        try encodeObject(self._args)
    }

    mutating func updateFrom(json: JSONObject) throws {
        self._outputs = try decodeObject(from: json, to: _ProductInfoOutputs.self)
    }
}

// MARK: ProductInfo Events


// MARK: - ProductInfo View Model

final class ProductInfoViewModel: ObservableObject, FeatureViewModel {
    @Published var feature: ProductInfo?

    // MARK: Arguments

    let impressionId: ImpressionId

    // MARK: Init

    init(impressionId: ImpressionId = .newId()) {
        self.impressionId = impressionId
    }

    // MARK: Feature request

    @MainActor
    func requestFeature() async throws {
        var _feature = ProductInfo()
        _feature.impressionIds = [self.impressionId]

        do {
            self.feature = try await CausalClient.shared.requestFeature(
                feature: _feature,
                impressionId: self.impressionId
            )
        } catch {
            self.feature = _feature
            throw error
        }
    }

    // MARK: Events

}

// MARK: - Feature2

private struct _Feature2Outputs: Codable, Hashable {
    var exampleOutput: String = "Example output"
    var impressionIds: [ImpressionId] = []
}

private struct _Feature2Args: Codable, Hashable {
    var exampleArg: String
}

/// Another feature just for demonstration purposes
struct Feature2: FeatureProtocol {
    static let name = "Feature2"

    var isActive = true

    var impressionIds: [ImpressionId] {
        get {
            self._outputs.impressionIds
        }
        set {
            self._outputs.impressionIds = newValue
        }
    }

    // MARK: Arguments
    private var _args: _Feature2Args

    /// Example args
    var exampleArg: String {
        self._args.exampleArg
    }

    // MARK: Outputs

    private var _outputs: _Feature2Outputs = _Feature2Outputs()

    /// Example output
    var exampleOutput: String {
        self._outputs.exampleOutput
    }

    // MARK: Initializer
    init(exampleArg: String = "") {
        self._args = _Feature2Args(exampleArg: exampleArg)
    }

    var id: FeatureId {
        generateIdFrom(name: "Feature2", args: self._args)
    }

    // MARK: FeatureProtocol
    func args() throws -> JSONObject {
        try encodeObject(self._args)
    }

    mutating func updateFrom(json: JSONObject) throws {
        self._outputs = try decodeObject(from: json, to: _Feature2Outputs.self)
    }
}

// MARK: Feature2 Events

// MARK: - ExampleEvent
extension Feature2 {
    /// Example event
    struct ExampleEvent: EventProtocol {
        /// The name of the feature for which this event is associated.
        public static let featureName = "Feature2"

        /// The name of this event.
        public static let name = "ExampleEvent"

        var data: String

        func serialized() throws -> JSONObject {
            let json = try encodeObject(self)
            return json
        }
    }

    /// - Parameter data: 
    /// - Throws: A ``CausalError``.
    func signalExampleEvent(data: String) async throws {
        let event = ExampleEvent(data: data)
        try await CausalClient.shared.signalEvent(
            event: event,
            impressionId: self.impressionIds.first ?? ""
        )
    }
}

// MARK: - Feature2 View Model

final class Feature2ViewModel: ObservableObject, FeatureViewModel {
    @Published var feature: Feature2?

    // MARK: Arguments

    let exampleArg: String
    let impressionId: ImpressionId

    // MARK: Init

    init(exampleArg: String="", impressionId: ImpressionId = .newId()) {
        self.exampleArg = exampleArg
        self.impressionId = impressionId
    }

    // MARK: Feature request

    @MainActor
    func requestFeature() async throws {
        var _feature = Feature2(exampleArg: self.exampleArg)
        _feature.impressionIds = [self.impressionId]

        do {
            self.feature = try await CausalClient.shared.requestFeature(
                feature: _feature,
                impressionId: self.impressionId
            )
        } catch {
            self.feature = _feature
            throw error
        }
    }

    // MARK: Events

    func signalExampleEvent(data: String, onError: ((Error) -> Void)? = nil) {
        Task {
            do {
                try await self.feature?.signalExampleEvent(data: data)
            } catch {
                onError?(error)
            }
        }
    }
}


// swiftformat:enable all
// swiftlint:enable all
