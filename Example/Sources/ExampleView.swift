//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import Foundation
import SwiftUI

struct ExampleView: View {
    @StateObject var viewModel = RatingBoxViewModel(product: "my product")

    // MARK: Event inputs

    @State var stars: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            Text(self.viewModel.feature?.callToAction ?? "")

            HStack {
                ForEach(1..<6) { stars in
                    Button {
                        self.stars = stars
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .foregroundColor(stars <= self.stars ? .accentColor : .secondary)
                    }
                }
            }

            Button {
                self.viewModel.signalRating(stars: self.stars)
            } label: {
                Text(self.viewModel.feature?.actionButton ?? "")
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem {
                Button("Clear Cache") {
                    Task {
                        await CausalClient.shared.clearCache()
                    }
                }
            }
        }
        .padding()
        .requestFeature(self.viewModel)
    }
}
