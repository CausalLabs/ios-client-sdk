//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

struct OtherView: View {
    @State var isPresenting = false

    @State var push = false

    @State var modal = false

    @Environment(\.dismiss)
    var dismiss

    var body: some View {
        NavigationStack {
            Color.white
                .ignoresSafeArea()
                .overlay {
                    VStack(spacing: 20) {
                        Text("Hello, world!").font(.title)

                        Button("Show Rating Box") {
                            self.isPresenting = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .navigationTitle("Other View")
                .toolbar {
                    ToolbarItem {
                        Button("Dismiss") {
                            self.dismiss()
                        }
                    }
                }
        }
        .sheet(isPresented: self.$isPresenting) {
            NavigationStack {
                ExampleView()
                    .navigationTitle("Rating Box")
                    .toolbar {
                        ToolbarItem {
                            NavigationLink("Push") {
                                Self()
                            }
                        }

                        ToolbarItem {
                            Button("Modal") {
                                self.modal = true
                            }
                        }
                    }
                    .fullScreenCover(isPresented: self.$modal) {
                        Self()
                    }
            }
        }
    }
}