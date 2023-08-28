//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import SwiftUI

public struct DeviceRegistrationView: View {
    @State private var isToastPresented = false
    private let deviceId: DeviceId

    @Environment(\.presentationMode)
    private var presentationMode

    /// A screen which can register the current device, based on the input `deviceId`
    /// to the Causal web tools.
    /// - Parameter deviceId: The persistent device id for this device.
    public init(deviceId: DeviceId) {
        self.deviceId = deviceId
    }

    public var body: some View {
        NavigationView {
            contentView
                .navigationBarTitle("Device Registration", displayMode: .inline)
                .navigationBarItems(
                    leading: cancelButton,
                    trailing: shareButton
                )
        }
    }

    @ViewBuilder private var shareButton: some View {
        if #available(iOS 16.0, *) {
            ShareLink(item: deviceId) {
                Image(systemName: "square.and.arrow.up")
            }
        } else {
            Button {
                presentShareSheet()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private var contentView: some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(spacing: 32) {
                // swiftlint:disable:next line_length
                Text("In order to effectively use Causal's Web Tools, you need to identify your devices to the system. This enables Causal to show you your events and push changes to your device for preview and QA.")
                        .font(.body)

                HStack {
                    VStack(alignment: .leading) {
                        Text("DeviceId")
                            .font(.headline)

                        Text(deviceId)
                            .font(.body)
                    }

                    Spacer()
                }
            }

            if let registrationUrl {
                if #available(iOS 15.0, *) {
                    Link("Register Device", destination: registrationUrl)
                        .buttonStyle(.bordered)
                } else {
                    Button("Register Device") {
                        UIApplication.shared.open(registrationUrl)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(15)
                }
            } else {
                Text("Error encountered generating registration URL")
            }

            Spacer()
        }
        .padding()
    }

    private func presentShareSheet() {
        let activityVC = UIActivityViewController(activityItems: [deviceId], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.topViewController.present(activityVC, animated: true, completion: nil)
    }

    private var registrationUrl: URL? {
        URL(string: "https://tools.causallabs.io/QA?persistentId=\(deviceId)")
    }
}

struct DeviceRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceRegistrationView(deviceId: .newId())
    }
}

private extension UIViewController {
    var topViewController: UIViewController {
        presentedViewController ?? self
    }
}
