//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes an event generated from the Causal SDK.
public protocol EventProtocol: Hashable, Codable {
    /// The name of the feature for which this event is associated.
    static var featureName: String { get }

    /// The name of the event.
    static var name: String { get }

    /// Serializes this event to JSON.
    func serialized() throws -> JSONObject
}

/// Describes a session specific event generated from the Causal SDK.
public protocol SessionEvent: EventProtocol {}

/// Describes a feature specific event generated from the Causal SDK.
public protocol FeatureEvent: EventProtocol {}

/// Describes an entity which can provide a session event.
public protocol SessionEventProvider {
    var eventDetails: any SessionEvent { get }
}

/// Describes an entity which can provide a feature event.
public protocol FeatureEventProvider {
    var eventDetails: any FeatureEvent { get }
}

/// Describes the combination of a feature event with the corresponding
/// impression id of the feature when the event occurred.
public typealias FeatureEventPayload = (event: any FeatureEvent, impressionId: ImpressionId)

extension EventProtocol {
    var featureName: String {
        Self.featureName
    }

    var name: String {
        Self.name
    }
}
