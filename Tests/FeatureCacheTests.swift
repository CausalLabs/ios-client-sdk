//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

@MainActor
final class FeatureCacheTests: XCTestCase {

    func test_save_fetchSingle() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)

        try cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        let fetched1 = cache.fetch(feature1)
        XCTAssertTrue(try feature1.isEqual(to: fetched1))

        let fetched2 = cache.fetch(feature2)
        XCTAssertTrue(try feature2.isEqual(to: fetched2))
    }

    func test_save_fetchMultiple() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)

        var fetched = cache.fetch(all: [feature1, feature2])
        XCTAssertTrue(fetched.isEmpty, "No features should be returned when cache is empty")

        try cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        fetched = cache.fetch(all: [feature1, feature2])
        XCTAssertTrue(try feature1.isEqual(to: fetched[0]))
        XCTAssertTrue(try feature2.isEqual(to: fetched[1]))
    }

    func test_remove() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)

        try cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        cache.remove(feature1)
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 1)

        let fetched = cache.fetch(all: [feature1, feature2])
        XCTAssertEqual(fetched.count, 1)
        XCTAssertTrue(try feature2.isEqual(to: fetched[0]))
    }

    func test_removeAll() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)

        try cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        cache.removeAll()
        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)
    }

    func test_remove_withSameName() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = RatingBox(productName: "first", productPrice: 1)
        let feature2 = RatingBox(productName: "second", productPrice: 2)

        try cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        cache.remove(feature1)
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 1)
        XCTAssertTrue(cache.contains(feature2))
    }

    func test_removeAllWithNames_OneFeature() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = RatingBox(productName: "first", productPrice: 1)
        let feature2 = RatingBox(productName: "second", productPrice: 2)
        let feature3 = MockFeature()

        try cache.save(all: [feature1, feature2, feature3])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 3)

        cache.removeAllWithNames(["RatingBox"])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 1)

        XCTAssertFalse(cache.contains(feature1))
        XCTAssertFalse(cache.contains(feature2))
        XCTAssertTrue(cache.contains(feature3))
    }

    func test_removeAllWithNames_MultipleFeatures() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = RatingBox(productName: "first", productPrice: 1)
        let feature2 = RatingBox(productName: "second", productPrice: 2)
        let feature3 = MockFeature()
        let feature4 = ProductInfo()

        try cache.save(all: [feature1, feature2, feature3, feature4])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 4)

        cache.removeAllWithNames([feature1.name, feature2.name, feature3.name])
        XCTAssertEqual(cache.count, 1)

        XCTAssertFalse(cache.contains(feature1))
        XCTAssertFalse(cache.contains(feature2))
        XCTAssertFalse(cache.contains(feature3))
        XCTAssertTrue(cache.contains(feature4))
    }

    func test_contains() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)
        try cache.save(feature1)

        XCTAssertTrue(cache.contains(feature1))
        XCTAssertFalse(cache.contains(feature2))
    }

    func test_contains_SameFeatureDifferentArgs() throws {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = RatingBox(productName: "first", productPrice: 1)
        let feature2 = RatingBox(productName: "second", productPrice: 2)
        try cache.save(feature1)

        XCTAssertTrue(cache.contains(feature1))
        XCTAssertFalse(cache.contains(feature2))
    }
}

private extension FeatureProtocol {
    func isEqual(to cacheItem: FeatureCache.CacheItem?) throws -> Bool {
        guard let cacheItem else { return false }
        let outputs = try outputs()

        return cacheItem.name == name &&
        cacheItem.isActive == isActive &&
        cacheItem.outputs == outputs &&
        cacheItem.impressionId == impressionId
    }
}
