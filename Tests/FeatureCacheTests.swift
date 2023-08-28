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

    // MARK: save(item:) & contains(key:)

    func test_save_item_SHOULD_addItemToCache() throws {
        sut.save(item: .mock(name: "feature1"))
        XCTAssertEqual(sut.count, 1)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertTrue(sut.contains(key: .mock(name: "feature1")))
    }

    // MARK: save(items:) & contains(key:)

    func test_save_items_SHOULD_addItemsToCache() throws {
        sut.save(items: [
            .mock(name: "feature1"),
            .mock(name: "feature2"),
            .mock(name: "feature3")
        ])
        XCTAssertEqual(sut.count, 3)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertTrue(sut.contains(key: .mock(name: "feature1")))
        XCTAssertTrue(sut.contains(key: .mock(name: "feature2")))
        XCTAssertTrue(sut.contains(key: .mock(name: "feature3")))
    }

    // MARK: fetch(key:)

    func test_fetch_key_SHOULD_returnNilIfItemNotPresent() {
        sut.save(items: [
            .mock(name: "feature1"),
            .mock(name: "feature2"),
            .mock(name: "feature3")
        ])

        XCTAssertNil(sut.fetch(key: .mock(name: "feature4")))
    }

    func test_fetch_key_SHOULD_returnItemIfPresent() {
        sut.save(items: [
            .mock(name: "feature1"),
            .mock(name: "feature2"),
            .mock(name: "feature3")
        ])

        let item = sut.fetch(key: .mock(name: "feature2"))
        XCTAssertEqual(item, FeatureCacheItem(key: .mock(name: "feature2"), status: .mock))
    }

    // MARK: fetch(keys:)

    func test_fetch_keys_SHOULD_returnItemsIfAllArePresent() {
        sut.save(items: [
            .mock(name: "feature1"),
            .mock(name: "feature2"),
            .mock(name: "feature3"),
            .mock(name: "feature4"),
            .mock(name: "feature5")
        ])

        let items = sut.fetch(keys: [.mock(name: "feature2"), .mock(name: "feature4")])
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items.contains(.mock(name: "feature2")))
        XCTAssertTrue(items.contains(.mock(name: "feature4")))
    }

    func test_fetch_keys_SHOULD_returnEmptyArrayIfNotAllRequestedFeaturesArePresent() {
        sut.save(items: [
            .mock(name: "feature1"),
            .mock(name: "feature2"),
            .mock(name: "feature3"),
            .mock(name: "feature4"),
            .mock(name: "feature5")
        ])

        let items = sut.fetch(keys: [.mock(name: "feature2"), .mock(name: "feature4"), .mock(name: "feature10")])
        XCTAssertEqual(items.count, 0)
    }

    // MARK: removeAll()

    func test_removeAll_SHOULD_removeAllItemsInTheCache() throws {
        sut.save(items: [
            .mock(name: "feature1"),
            .mock(name: "feature2"),
            .mock(name: "feature3"),
            .mock(name: "feature4"),
            .mock(name: "feature5")
        ])
        sut.removeAll()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.count, 0)
    }

    func test_removeAll_SHOULD_returnRemovedItems() throws {
        sut.save(items: [
            .mock(name: "feature1"),
            .mock(name: "feature2"),
            .mock(name: "feature3"),
            .mock(name: "feature4"),
            .mock(name: "feature5")
        ])
        let result = sut.removeAll()
        XCTAssertEqual(result.count, 5)
        XCTAssertTrue(result.contains(.mock(name: "feature1")))
        XCTAssertTrue(result.contains(.mock(name: "feature2")))
        XCTAssertTrue(result.contains(.mock(name: "feature3")))
        XCTAssertTrue(result.contains(.mock(name: "feature4")))
        XCTAssertTrue(result.contains(.mock(name: "feature5")))
    }

    // MARK: removeAll(names:)

    func test_removeAll_names_SHOULD_removeAllItemsInTheCacheThatMatchTheInputNames() throws {
        sut.save(items: [
            .mock(name: "feature1", numberOfArgs: 1),
            .mock(name: "feature1", numberOfArgs: 2),
            .mock(name: "feature2", numberOfArgs: 1),
            .mock(name: "feature2", numberOfArgs: 2),
            .mock(name: "feature3", numberOfArgs: 1),
            .mock(name: "feature3", numberOfArgs: 2),
            .mock(name: "feature4", numberOfArgs: 1),
            .mock(name: "feature4", numberOfArgs: 2)
        ])
        sut.removeAll(named: ["feature1", "feature3"])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 4)
    }

    func test_removeAll_names_SHOULD_returnRemovedItems() throws {
        sut.save(items: [
            .mock(name: "feature1", numberOfArgs: 1),
            .mock(name: "feature1", numberOfArgs: 2),
            .mock(name: "feature2", numberOfArgs: 1),
            .mock(name: "feature2", numberOfArgs: 2),
            .mock(name: "feature3", numberOfArgs: 1),
            .mock(name: "feature3", numberOfArgs: 2),
            .mock(name: "feature4", numberOfArgs: 1),
            .mock(name: "feature4", numberOfArgs: 2)
        ])
        let result = sut.removeAll(named: ["feature1", "feature3"])
        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result.contains(.mock(name: "feature1", numberOfArgs: 1)))
        XCTAssertTrue(result.contains(.mock(name: "feature1", numberOfArgs: 2)))
        XCTAssertTrue(result.contains(.mock(name: "feature3", numberOfArgs: 1)))
        XCTAssertTrue(result.contains(.mock(name: "feature3", numberOfArgs: 2)))
    }
}

private extension FeatureKey {
    static func mock(name: String, numberOfArgs: Int = 1) -> FeatureKey {
        var argsJson = JSONObject()
        for index in 0...numberOfArgs {
            argsJson["arg\(index)"] = "argValue\(index)"
        }

        return FeatureKey(name: name, argsJson: argsJson)
    }
}

private extension EncodedFeatureStatus {
    static var mock: EncodedFeatureStatus {
        .on(outputsJson: ["output1": "outputValue1"])
    }
}

private extension FeatureCacheItem {
    static func mock(name: String = "name", numberOfArgs: Int = 1) -> FeatureCacheItem {
        FeatureCacheItem(
            key: .mock(name: name, numberOfArgs: numberOfArgs),
            status: .mock
        )
    }
}
