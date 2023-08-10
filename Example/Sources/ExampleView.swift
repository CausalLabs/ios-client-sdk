//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import Foundation
import SwiftUI

struct ExampleView: View {
    @StateObject private var viewModel = RatingBoxViewModel(product: "my product")

    // MARK: Event inputs

    @State private var stars: Int = 0

    var body: some View {
        VStack {
            contentView
                .toolbar(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem {
                        Button("Clear Cache") {
                            CausalClient.shared.clearCache()
                        }
                    }
                }
                .padding()
                .requestFeature(viewModel)
        }

    }

    @ViewBuilder private var contentView: some View {
        switch viewModel.state {
        case .loading:
            loadingView

        case let .on(outputs):
            loadedView(outputs: outputs)

        case .off:
            offView
        }
    }

    private var loadingView: some View {
        Text("Loading Feature")
    }

    private var offView: some View {
        Text("Feature is OFF")
    }

    private func loadedView(outputs: RatingBox.Outputs) -> some View {
        VStack(spacing: 16) {
            Text(outputs.callToAction)

            HStack {
                ForEach(1..<6) { rating in
                    Button {
                        stars = rating
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .foregroundColor(rating <= stars ? .accentColor : .secondary)
                    }
                }
            }

            Button {
                viewModel.signal(event: .rating(stars: stars))
            } label: {
                Text(outputs.actionButton)
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
}
