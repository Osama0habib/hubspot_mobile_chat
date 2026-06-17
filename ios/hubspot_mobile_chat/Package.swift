// swift-tools-version: 5.9
// Flutter SPM package for the plugin's iOS implementation. Declares HubSpot's
// SPM-only Mobile Chat SDK so the `HubspotMobileSDK` module resolves.
import PackageDescription

let package = Package(
  name: "hubspot_mobile_chat",
  platforms: [
    .iOS("15.0"),
  ],
  products: [
    .library(name: "hubspot-mobile-chat", targets: ["hubspot_mobile_chat"]),
  ],
  dependencies: [
    // iOS SDK latest is 1.0.7 (no 1.0.8 tag); Android is on 1.0.8. Each is its
    // platform's latest published version.
    .package(url: "https://github.com/HubSpot/mobile-chat-sdk-ios", from: "1.0.7"),
  ],
  targets: [
    .target(
      name: "hubspot_mobile_chat",
      dependencies: [
        .product(name: "HubspotMobileSDK", package: "mobile-chat-sdk-ios"),
      ],
      cSettings: [
        .headerSearchPath("include/hubspot_mobile_chat"),
      ]
    ),
  ]
)
