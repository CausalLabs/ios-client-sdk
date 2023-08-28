//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK

final class MockFeatureA: BaseMockFeature, FeatureProtocol {
    static var name: String {
        "MockFeatureA"
    }

    func clone() -> MockFeatureA {
        MockFeatureA(arg1: args.arg1)
    }
}

final class MockFeatureB: BaseMockFeature, FeatureProtocol {
    static var name: String {
        "MockFeatureB"
    }

    func clone() -> MockFeatureB {
        MockFeatureB(arg1: args.arg1)
    }
}

final class MockFeatureC: BaseMockFeature, FeatureProtocol {
    static var name: String {
        "MockFeatureC"
    }

    func clone() -> MockFeatureC {
        MockFeatureC(arg1: args.arg1)
    }
}

class BaseMockFeature {
    struct Args: Codable, Hashable {
        let arg1: String
    }

    struct Outputs: FeatureOutputsProtocol {
        let _impressionId: ImpressionId?
        let out1: String
        let out2: Int

        fileprivate func with(impressionId: ImpressionId) -> Self {
            Self(
                _impressionId: impressionId,
                out1: self.out1,
                out2: self.out2
            )
        }

        static let defaultValues = Self(_impressionId: nil, out1: "default out1", out2: -1)
    }

    enum Event: FeatureEventProvider {
        case one

        var eventDetails: any FeatureEvent {
            switch self {
            case .one:
                return One()
            }
        }

        struct One: FeatureEvent {
            static let name: String = "One_Name"
            static let featureName: String = "One_FeatureName"

            func serialized() throws -> JSONObject {
                JSONObject()
            }
        }
    }

    init(arg1: String) {
        self.args = Args(arg1: arg1)
    }

    var args: Args
    var status: FeatureStatus<Outputs> = .unrequested

    var id: FeatureId {
        "MockFeature_Id_\(args.arg1)"
    }

    private(set) var updateCalls = [FeatureUpdateRequest]()
    func update(request: FeatureUpdateRequest) throws {
        updateCalls.append(request)
        switch request {
        case .off:
            status = .off

        case let .on(outputJson, impressionId):
            let cachedOutputs = try Outputs.decodeFromJSONObject(outputJson)

            if let impressionId {
                let outputsWithImpressionId = cachedOutputs.with(impressionId: impressionId)
                self.status = .on(outputs: outputsWithImpressionId)
            } else {
                self.status = .on(outputs: cachedOutputs)
            }

        case .defaultStatus:
            self.status = .on(outputs: .defaultValues)
        }
    }

    private(set) var eventCalls = [Event]()
    private(set) var eventResult: FeatureEventPayload?
    func event(_ event: Event) -> FeatureEventPayload? {
        eventCalls.append(event)
        return eventResult
    }
}
