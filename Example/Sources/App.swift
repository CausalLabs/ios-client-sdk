//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import Foundation
import SwiftUI

@main
struct ExampleApp: App {
    init() {
        CausalClient.shared.impressionServer = URL(string: "https://tools.causallabs.io/sandbox-iserver")!
        CausalClient.shared.session = Session(deviceId: UUID().uuidString)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Rating", systemImage: "star.fill")
                    }

                OtherView()
                    .tabItem {
                        Label("Other", systemImage: "circle.fill")
                    }
            }
        }
    }
}
