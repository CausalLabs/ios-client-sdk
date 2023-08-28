//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import Foundation
import SwiftUI

@main
struct ExampleApp: App {
    private let deviceRepository: DeviceRepositoryProtocol = DeviceRepository()

    init() {
        // Set the url for the impression server
        CausalClient.shared.impressionServer = URL(string: "https://dev.causallabs.io/sandbox-iserver")!

        // Update the client with an initial Session value
        CausalClient.shared.session = Session(deviceId: deviceRepository.deviceId)

        // Enable verbose debugging
        //
        // - Warning: This is primarily intended for feature debugging and QA purposes
        CausalClient.shared.debugLogging = .verbose

        // Preload the Causal cache on app start up with features.
        Task {
            do {
                try await CausalClient.shared.requestCacheFill(features: [RatingBox(product: "SwiftUIExampleView")])
            } catch {
                print("Error encountered while filling the Causal Cache on app startup: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    MVVMExampleView()
                        .navigationTitle("MVVM Example")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label("MVVM Example", systemImage: "square.fill")
                }

                NavigationStack {
                    SwiftUIExampleView()
                        .navigationTitle("View Model Example")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label("Basic SwiftUI Example", systemImage: "circle.fill")
                }
            }
            .environment(\.deviceId, deviceRepository.deviceId)
        }
    }
}
