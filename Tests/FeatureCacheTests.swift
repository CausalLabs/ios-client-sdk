//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class FeatureCacheTests: XCTestCase {
    private var sut: FeatureCache!

    override func setUp() async throws {
        sut = FeatureCache()
        try await super.setUp()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: init

    func test_init_SHOULD_defaultToEmptyCache() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.count, 0)
    }

    // MARK: save(feature:) & fetch(feature:)

    func test_save_SHOULD_saveActiveFeature() throws {
        let feature = MockFeatureA(arg1: "on feature")
        feature.status = .on(outputs: .init(_impressionId: "impression_id", out1: "out1", out2: 2))

        try sut.save(feature)
        XCTAssertEqual(sut.count, 1)

        let fetched = sut.fetch(feature)
        XCTAssertTrue(try feature.isEqual(to: fetched))
    }

    func test_save_SHOULD_saveInactiveFeature() throws {
        let feature = MockFeatureA(arg1: "off feature")
        feature.status = .off

        try sut.save(feature)
        XCTAssertEqual(sut.count, 1)

        let fetched1 = sut.fetch(feature)
        XCTAssertTrue(try feature.isEqual(to: fetched1))
    }

    func test_save_SHOULD_throwWhenSavingActiveFeatureWithoutImpressionId() throws {
        let feature = MockFeatureA(arg1: "on feature - nil impression id")
        feature.status = .on(outputs: .init(_impressionId: nil, out1: "out1", out2: 2))

        XCTAssertThrowsError(try sut.save(feature)) { error in
            XCTAssertEqual(error as? FeatureCache.FeatureCacheError, .invalidFeature)
        }
        XCTAssertTrue(sut.isEmpty)
    }

    func test_save_SHOULD_throwWhenSavingUnrequestedFeature() throws {
        let feature = MockFeatureA(arg1: "unrequested feature")
        feature.status = .unrequested

        XCTAssertThrowsError(try sut.save(feature)) { error in
            XCTAssertEqual(error as? FeatureCache.FeatureCacheError, .invalidFeature)
        }
        XCTAssertTrue(sut.isEmpty)
    }

    // MARK: save(all:) & fetch(all:)

    func test_saveAll_SHOULD_saveActiveAndInactiveFeatures() throws {
        let feature1 = MockFeatureA(arg1: "on feature")
        feature1.status = .on(outputs: .init(_impressionId: "impression_id", out1: "out1", out2: 2))
        let feature2 = MockFeatureB(arg1: "off feature")
        feature2.status = .off

        try sut.save(all: [feature1, feature2])
        XCTAssertEqual(sut.count, 2)

        let fetched = sut.fetch(all: [feature1, feature2])
        XCTAssertEqual(fetched.count, 2)
        XCTAssertTrue(try feature1.isEqual(to: fetched[0]))
        XCTAssertTrue(try feature2.isEqual(to: fetched[1]))
    }

    func test_saveAll_SHOULD_throwWhenSavingActiveFeatureWithoutImpressionId() throws {
        let feature1 = MockFeatureA(arg1: "on feature - no impression id")
        feature1.status = .on(outputs: .init(_impressionId: nil, out1: "out1", out2: 2))
        let feature2 = MockFeatureB(arg1: "off feature")
        feature2.status = .off

        XCTAssertThrowsError(try sut.save(all: [feature2, feature1])) { error in
            XCTAssertEqual(error as? FeatureCache.FeatureCacheError, .invalidFeature)
        }
        XCTAssertTrue(sut.isEmpty)
    }

    func test_saveAll_SHOULD_throwWhenSavingUnrequestedFeature() throws {
        let feature1 = MockFeatureA(arg1: "on feature")
        feature1.status = .on(outputs: .init(_impressionId: "impressionId", out1: "out1", out2: 2))
        let feature2 = MockFeatureB(arg1: "off feature")
        feature2.status = .unrequested

        XCTAssertThrowsError(try sut.save(all: [feature1, feature2])) { error in
            XCTAssertEqual(error as? FeatureCache.FeatureCacheError, .invalidFeature)
        }
        XCTAssertTrue(sut.isEmpty)
    }

    // MARK: remove(feature:)

    func test_remove_SHOULD_removeFeatureFromTheCache() throws {
        let feature1 = MockFeatureA(arg1: "feature1")
        feature1.status = .off
        let feature2 = MockFeatureB(arg1: "feature2")
        feature2.status = .off

        try sut.save(all: [feature1, feature2])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 2)

        sut.remove(feature1)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 1)

        let fetched = sut.fetch(all: [feature1, feature2])
        XCTAssertEqual(fetched.count, 1)
        XCTAssertTrue(try feature2.isEqual(to: fetched[0]))
    }

    // MARK: removeAll()

    func test_removeAll_SHOULD_removeAllFeaturesFromTheCache() throws {
        let feature1 = MockFeatureA(arg1: "feature1")
        feature1.status = .off
        let feature2 = MockFeatureB(arg1: "feature2")
        feature2.status = .off

        try sut.save(all: [feature1, feature2])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 2)

        sut.removeAll()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.count, 0)
    }

    // MARK: removeAllWithNames(namesToRemove:)

    func test_removeAllWithNames_SHOULD_doNothingIfNameNotFound() throws {
        let featureA1 = MockFeatureA(arg1: "featureAa")
        featureA1.status = .off
        let featureA2 = MockFeatureA(arg1: "featureA2")
        featureA2.status = .off
        let featureB1 = MockFeatureB(arg1: "featureB1")
        featureB1.status = .off
        let featureB2 = MockFeatureB(arg1: "featureB2")
        featureB2.status = .off
        let featureC1 = MockFeatureC(arg1: "featureC1")
        featureC1.status = .off
        let featureC2 = MockFeatureC(arg1: "featureC2")
        featureC2.status = .off

        try sut.save(all: [featureA1, featureA2, featureB1, featureB2, featureC1, featureC2])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 6)

        sut.removeAllWithNames(["unknown1", "unknown2"])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 6)
        XCTAssertTrue(sut.contains(featureA1))
        XCTAssertTrue(sut.contains(featureA2))
        XCTAssertTrue(sut.contains(featureB1))
        XCTAssertTrue(sut.contains(featureB2))
        XCTAssertTrue(sut.contains(featureC1))
        XCTAssertTrue(sut.contains(featureC2))
    }

    func test_removeAllWithNames_SHOULD_removeAllFeaturesWithThatNameFromTheCache_oneName() throws {
        let featureA1 = MockFeatureA(arg1: "featureAa")
        featureA1.status = .off
        let featureA2 = MockFeatureA(arg1: "featureA2")
        featureA2.status = .off
        let featureB1 = MockFeatureB(arg1: "featureB1")
        featureB1.status = .off
        let featureB2 = MockFeatureB(arg1: "featureB2")
        featureB2.status = .off
        let featureC1 = MockFeatureC(arg1: "featureC1")
        featureC1.status = .off
        let featureC2 = MockFeatureC(arg1: "featureC2")
        featureC2.status = .off

        try sut.save(all: [featureA1, featureA2, featureB1, featureB2, featureC1, featureC2])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 6)

        sut.removeAllWithNames([MockFeatureB.name])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 4)
        XCTAssertTrue(sut.contains(featureA1))
        XCTAssertTrue(sut.contains(featureA2))
        XCTAssertFalse(sut.contains(featureB1))
        XCTAssertFalse(sut.contains(featureB2))
        XCTAssertTrue(sut.contains(featureC1))
        XCTAssertTrue(sut.contains(featureC2))
    }

    func test_removeAllWithNames_SHOULD_removeAllFeaturesWithThatNameFromTheCache_multipleNames() throws {
        let featureA1 = MockFeatureA(arg1: "featureAa")
        featureA1.status = .off
        let featureA2 = MockFeatureA(arg1: "featureA2")
        featureA2.status = .off
        let featureB1 = MockFeatureB(arg1: "featureB1")
        featureB1.status = .off
        let featureB2 = MockFeatureB(arg1: "featureB2")
        featureB2.status = .off
        let featureC1 = MockFeatureC(arg1: "featureC1")
        featureC1.status = .off
        let featureC2 = MockFeatureC(arg1: "featureC2")
        featureC2.status = .off

        try sut.save(all: [featureA1, featureA2, featureB1, featureB2, featureC1, featureC2])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 6)

        sut.removeAllWithNames([MockFeatureB.name, MockFeatureC.name])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 2)
        XCTAssertTrue(sut.contains(featureA1))
        XCTAssertTrue(sut.contains(featureA2))
        XCTAssertFalse(sut.contains(featureB1))
        XCTAssertFalse(sut.contains(featureB2))
        XCTAssertFalse(sut.contains(featureC1))
        XCTAssertFalse(sut.contains(featureC2))
    }

    func test_removeAllWithNames_SHOULD_removeAllFeaturesWithThatNameFromTheCache_allNames() throws {
        let featureA1 = MockFeatureA(arg1: "featureAa")
        featureA1.status = .off
        let featureA2 = MockFeatureA(arg1: "featureA2")
        featureA2.status = .off
        let featureB1 = MockFeatureB(arg1: "featureB1")
        featureB1.status = .off
        let featureB2 = MockFeatureB(arg1: "featureB2")
        featureB2.status = .off
        let featureC1 = MockFeatureC(arg1: "featureC1")
        featureC1.status = .off
        let featureC2 = MockFeatureC(arg1: "featureC2")
        featureC2.status = .off

        try sut.save(all: [featureA1, featureA2, featureB1, featureB2, featureC1, featureC2])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 6)

        sut.removeAllWithNames([MockFeatureB.name, MockFeatureC.name, MockFeatureA.name])
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.count, 0)
        XCTAssertFalse(sut.contains(featureA1))
        XCTAssertFalse(sut.contains(featureA2))
        XCTAssertFalse(sut.contains(featureB1))
        XCTAssertFalse(sut.contains(featureB2))
        XCTAssertFalse(sut.contains(featureC1))
        XCTAssertFalse(sut.contains(featureC2))
    }

    // MARK: contains(feature:)

    func test_contains_SHOULD_returnTrueIfInCacheFalseOtherwise() throws {
        let feature1 = MockFeatureA(arg1: "feature1")
        feature1.status = .off
        let feature2 = MockFeatureB(arg1: "feature2")
        feature2.status = .off
        try sut.save(feature1)

        XCTAssertTrue(sut.contains(feature1))
        XCTAssertFalse(sut.contains(feature2))
    }

    func test_contains_SHOULD_differentiateBetweenMultipleInstancesOfTheSameFeature() throws {
        let feature1 = MockFeatureA(arg1: "feature1")
        feature1.status = .off
        let feature2 = MockFeatureA(arg1: "feature2")
        feature2.status = .off
        try sut.save(feature1)

        XCTAssertTrue(sut.contains(feature1))
        XCTAssertFalse(sut.contains(feature2))
    }
}

private extension FeatureProtocol {
    func isEqual(to cacheItem: FeatureCache.CacheItem?) throws -> Bool {
        guard let cacheItem else { return false }

        switch status {
        case .unrequested:
            return false

        case .off:
            return cacheItem == .init(name: name, status: .off)

        case let .on(outputs):
            guard let impressionId = outputs._impressionId,
                  let outputsJson = try? outputs.encodeToJSONObject() else {
                return false
            }

            return cacheItem == .init(name: name, status: .on(outputsJson: outputsJson, cachedImpressionId: impressionId))
        }
    }
}
