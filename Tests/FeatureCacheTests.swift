//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

@MainActor
final class FeatureCacheTests: XCTestCase {

    func test_save_fetchSingle() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)

        cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        let fetched1 = cache.fetch(feature1)
        XCTAssertEqual(fetched1 as? MockFeature, feature1)

        let fetched2 = cache.fetch(feature2)
        XCTAssertEqual(fetched2 as? RatingBox, feature2)
    }

    func test_save_fetchMultiple() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)

        var fetched = cache.fetch(all: [feature1, feature2])
        XCTAssertTrue(fetched.isEmpty, "No features should be returned when cache is empty")

        cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        fetched = cache.fetch(all: [feature1, feature2])
        XCTAssertEqual(fetched[0] as? MockFeature, feature1)
        XCTAssertEqual(fetched[1] as? RatingBox, feature2)
    }

    func test_remove() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)

        cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        cache.remove(feature1)
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 1)

        let fetched = cache.fetch(all: [feature1, feature2])
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0] as? RatingBox, feature2)
    }

    func test_removeAll() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)

        cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        cache.removeAll()
        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)
    }

    func test_remove_withSameName() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = RatingBox(productName: "first", productPrice: 1)
        let feature2 = RatingBox(productName: "second", productPrice: 2)

        cache.save(all: [feature1, feature2])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)

        cache.remove(feature1)
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 1)
        XCTAssertTrue(cache.contains(feature2))
    }

    func test_removeAllWithName() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = RatingBox(productName: "first", productPrice: 1)
        let feature2 = RatingBox(productName: "second", productPrice: 2)
        let feature3 = MockFeature()

        cache.save(all: [feature1, feature2, feature3])
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 3)

        cache.removeAllWithName("RatingBox")
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 1)

        XCTAssertFalse(cache.contains(feature1))
        XCTAssertFalse(cache.contains(feature2))
    }

    func test_contains() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = MockFeature()
        let feature2 = RatingBox(productName: "name", productPrice: 0)
        cache.save(feature1)

        XCTAssertTrue(cache.contains(feature1))
        XCTAssertFalse(cache.contains(feature2))
    }

    func test_contains_SameFeatureDifferentArgs() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature1 = RatingBox(productName: "first", productPrice: 1)
        let feature2 = RatingBox(productName: "second", productPrice: 2)
        cache.save(feature1)

        XCTAssertTrue(cache.contains(feature1))
        XCTAssertFalse(cache.contains(feature2))
    }

    func test_filtered() {
        let cache = FeatureCache()
        XCTAssertTrue(cache.isEmpty)

        let feature0 = MockFeature()
        let feature1 = RatingBox(productName: "first", productPrice: 1)
        let feature2 = RatingBox(productName: "second", productPrice: 2)
        let feature3 = RatingBox(productName: "third", productPrice: 3)
        cache.save(all: [feature0, feature1])

        let all = [feature0, feature1, feature2, feature3] as [any FeatureProtocol]

        let filtered = cache.filter(notIncluded: all)
        XCTAssertEqual(filtered.count, 2)

        let filteredIds = filtered.map { $0.id }
        XCTAssertTrue(filteredIds.contains(feature2.id))
        XCTAssertTrue(filteredIds.contains(feature3.id))
    }
}
