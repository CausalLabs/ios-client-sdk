//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import Foundation
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            RatingBoxView()
                .navigationTitle("Causal Labs Example")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
