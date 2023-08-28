//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import SwiftUI

struct RatingView: View {
    @Binding private var rating: Int
    private let title: String
    private let buttonTitle: String
    private let buttonAction: () -> Void

    init(rating: Binding<Int>, title: String, buttonTitle: String, buttonAction: @escaping () -> Void) {
        self._rating = rating
        self.title = title
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)

            HStack {
                ForEach(1..<6) { rating in
                    Button {
                        self.rating = rating
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .foregroundColor(rating <= self.rating ? .accentColor : .secondary)
                    }
                }
            }

            Button {
                buttonAction()
            } label: {
                Text(buttonTitle)
            }
            .buttonStyle(.bordered)
        }
    }
}
