## 0.0.1

Initial release.

* Federated Flutter plugin wrapping HubSpot's native Mobile Chat SDKs (Android & iOS).
* Type-safe platform channels generated with Pigeon.
* Public API: `configure`, `setUserIdentity`, `setChatProperties`, `openChat`,
  `registerPushToken`, `onMessagePush` stream, and `logout`.
* Uniform error contract: `HubspotConfigError` for configuration failures and
  `UnsupportedError` on unsupported platforms.
* Android via `com.hubspot.mobilechatsdk:mobile-chat-sdk-android` (1.0.8, minSdk 26).
* iOS via the `HubspotMobileSDK` Swift Package (1.0.7, iOS 15+, Flutter SPM).
* Example app demonstrating every feature.
