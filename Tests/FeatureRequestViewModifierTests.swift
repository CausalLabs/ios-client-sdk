//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import SwiftUI
import UIKit
import XCTest

final class FeatureRequestViewModifierTests: XCTestCase {

    func test_viewModifier_requestFeature_exactlyOnce() {
        let expectation = self.expectation(description: #function)

        let mockViewModel = MockFeatureViewModel()
        mockViewModel.stubbedRequestFeature = {
            expectation.fulfill()
        }

        let window = UIWindow()
        let controller = FakeViewController(viewModel: mockViewModel)
        window.rootViewController = controller
        window.makeKeyAndVisible()

        // simulate view lifecycle multiple times
        controller.simulateViewAppearance()
        controller.simulateViewDisappearance()

        controller.simulateViewAppearance()
        controller.simulateViewDisappearance()

        controller.simulateViewAppearance()
        controller.simulateViewDisappearance()

        self.waitForExpectations(timeout: 5)
    }
}

struct FakeFeatureView: View {
    var viewModel: MockFeatureViewModel

    var body: some View {
        EmptyView()
            .requestFeature(self.viewModel)
    }
}

final class FakeHostingController: UIHostingController<FakeFeatureView> { }

final class FakeViewController: UIViewController {
    var viewModel: MockFeatureViewModel

    init(viewModel: MockFeatureViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let childVC = FakeHostingController(rootView: FakeFeatureView(viewModel: self.viewModel))
        self.addChild(childVC)
        self.view.addSubview(childVC.view)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childVC.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            childVC.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        childVC.didMove(toParent: self)
    }
}

extension UIViewController {
    func simulateViewAppearance() {
        self.beginAppearanceTransition(true, animated: false)
        self.endAppearanceTransition()
    }

    func simulateViewDisappearance() {
        self.beginAppearanceTransition(false, animated: false)
        self.endAppearanceTransition()
    }
}
