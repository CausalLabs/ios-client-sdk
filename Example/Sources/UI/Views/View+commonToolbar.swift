//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import SwiftUI

extension View {
    /// Adds a toolbar to the view with a button to register the device for QA.
    /// - Returns: The modified view.
    func commonToolbar() -> some View {
        modifier(CommonToolbar())
    }
}

private struct CommonToolbar: ViewModifier {
    @State private var isRegistrationViewPresented = false

    @Environment(\.deviceId)
    private var deviceId

    func body(content: Content) -> some View {
        content
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isRegistrationViewPresented.toggle()
                    } label: {
                        Label("Register Device", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    }
                }
            }
            .sheet(isPresented: $isRegistrationViewPresented) {
                DeviceRegistrationView(deviceId: deviceId)
            }
    }
}
