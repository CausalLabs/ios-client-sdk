//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class ObserverStoreTests: XCTestCase {
    private var sut: ObserverStore!

    override func setUp() {
        super.setUp()
        var index = 0
        sut = ObserverStore {
            index += 1
            return "token\(index)"
        }
    }

    // MARK: init

    func test_init_SHOULD_defaultTokenFactoryToReturnUUID() {
        let sut = ObserverStore()
        let token = sut.add(item: .mock())
        let result = UUID(uuidString: token)
        XCTAssertNotNil(result)
    }

    func test_init_SHOULD_defaultTokenFactoryToReturnUUIDOnEachCall() {
        let sut = ObserverStore()
        let token1 = sut.add(item: .mock())
        let token2 = sut.add(item: .mock())
        let token3 = sut.add(item: .mock())

        XCTAssertNotEqual(token1, token2)
        XCTAssertNotEqual(token2, token3)
        XCTAssertNotEqual(token1, token3)
    }

    // MARK: add

    func test_add_SHOULD_returnToken() {
        XCTAssertEqual(sut.add(item: .mock()), "token1")
    }

    func test_add_SHOULD_addItemToStore() async {
        _ = sut.add(item: .mock())
        let result = sut.fetch(keys: [.mock()])
        XCTAssertEqual(result.count, 1)
    }

    // MARK: remove

    func test_remove_SHOULD_removeItemFromStore() {
        let token = sut.add(item: .mock())
        sut.remove(token: token)
        XCTAssertEqual(sut.fetch(keys: [.mock()]).count, 0)
    }

    // MARK: fetch

    func test_fetch_SHOULD_returnTheCorrectHandler() async {
        let isDone = expectation(description: #function)
        isDone.expectedFulfillmentCount = 4
        isDone.assertForOverFulfill = true

        _ = sut.add(
            item: .mock(name: "1") {
                isDone.fulfill()
            }
        )
        _ = sut.add(
            item: .mock(name: "1") {
                isDone.fulfill()
            }
        )
        _ = sut.add(
            item: .mock(name: "2") {
                isDone.fulfill()
                XCTFail("Unexpected call")
            }
        )
        _ = sut.add(
            item: .mock(name: "2") {
                isDone.fulfill()
                XCTFail("Unexpected call")
            }
        )
        _ = sut.add(
            item: .mock(name: "3") {
                isDone.fulfill()
            }
        )
        _ = sut.add(
            item: .mock(name: "3") {
                isDone.fulfill()
            }
        )

        let result = sut.fetch(keys: [.mock(name: "1"), .mock(name: "3")])
        XCTAssertEqual(result.count, 4)
        for handler in result {
            handler()
        }
        await fulfillment(of: [isDone], timeout: 0.1)
    }
}

private extension FeatureKey {
    static func mock(name: String = "name") -> FeatureKey {
        FeatureKey(name: name, argsJson: [:])
    }
}

private extension ObserverStoreItem {
    static func mock(name: String = "name", handler: @escaping ObserverHandler = {}) -> ObserverStoreItem {
        ObserverStoreItem(featureKey: .mock(name: name), handler: handler)
    }
}
