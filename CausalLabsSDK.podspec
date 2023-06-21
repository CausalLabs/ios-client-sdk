Pod::Spec.new do |p|
  p.name = "CausalLabsSDK"
  p.version = "0.1.0"

  p.summary = "iOS SDK for Causal Labs"
  p.description = "The Causal Labs iOS SDK integrates Causal with native iOS apps."
  p.documentation_url = "https://causallabs.github.io/ios-client-sdk"

  p.homepage = "https://www.causallabs.io"
  p.license = "LICENSE.txt"
  p.author = { "Causal Labs, Inc." => "support@causallabs.io" }

  p.source = { :git => "https://github.com/causallabs/ios-client-sdk.git", :tag => p.version }
  p.source_files = "Sources/**/*.swift"
  p.ios.resource_bundle = { "CausalCompiler" => "compiler/**/*" }

  p.ios.deployment_target = "13.0"
  p.swift_version = "5.8"
end
