# hubspot_mobile_chat

A federated Flutter plugin that wraps HubSpot's native **Mobile Chat SDKs** for Android and
iOS behind one Dart API: initialize, identify the visitor, set chat properties, open the
chat UI, receive push notifications, and log out.

- Android SDK: <https://github.com/HubSpot/mobile-chat-sdk-android> (`com.hubspot.mobilesdk`, 1.0.8)
- iOS SDK: <https://github.com/HubSpot/mobile-chat-sdk-ios> (`HubspotMobileSDK`, 1.0.7, SPM-only)

The core chat works once you add the HubSpot config file to each native project — no other
native code. Push notifications need a little extra app-side wiring (you own FCM/APNs).

> **Disclaimer**
>
> This is an unofficial Flutter wrapper for HubSpot Mobile Chat SDKs.
> It is not affiliated with, endorsed by, or sponsored by HubSpot, Inc.
> HubSpot is a trademark of HubSpot, Inc.

## Features

- 🔌 One Dart API over the native Android & iOS HubSpot Mobile Chat SDKs.
- ⚙️ Config-file-only setup for the core chat flow — no native code to write.
- 👤 Optional visitor identification (server-generated token, pass-through).
- 🏷️ Custom chat properties, including device-permission keys.
- 💬 Open the native chat UI, optionally targeting a specific chat flow.
- 🔔 Push notifications: forward your FCM/APNs token and observe new-message events.
- 🚪 Logout to clear identity and properties.
- 🧱 Type-safe platform channels generated with [Pigeon](https://pub.dev/packages/pigeon).
- 🛡️ Uniform, catchable error contract (`HubspotConfigError` / `UnsupportedError`).

---

## Requirements

| | Minimum |
|--|---------|
| Flutter | 3.x (Dart 3.x) |
| Android | `minSdk 26` |
| iOS | deployment target `15.0`, Swift Package Manager enabled |
| HubSpot | a portal with **mobile chat enabled** and a **published chat flow** |

---

## 1. Install

```yaml
# pubspec.yaml
dependencies:
  hubspot_mobile_chat: ^0.0.1
```

```bash
flutter pub get
```

---

## 2. Get your HubSpot config values

From your HubSpot portal you need:

- **portalId** — your hub/portal id 
- **hublet** — your data region. Find it from your browser URL after logging in:
  `app.hubspot.com` → `na1`, `app-eu1.hubspot.com` → `eu1`, etc.
- **environment** — usually `prod`
- **defaultChatFlow** — the name of a **published** chat flow targeted to the mobile SDK

> The hublet must match your portal's region or the chat will fail to load
> ("The system isn't responding…"). The chat flow must be published.

---

## 3. Android setup

### 3a. Set `minSdk 26`

```kotlin
// android/app/build.gradle.kts
android {
  defaultConfig {
    minSdk = 26
  }
}
```

### 3b. Add the config file

Place `hubspot-info.json` in **`android/app/src/main/assets/`**:

```json
{
  "portalId": "YOUR_PORTAL_ID",
  "hublet": "na1",
  "environment": "prod",
  "defaultChatFlow": "your-chatflow"
}
```

### 3c. Add the AppCompat theme override (required)

HubSpot's chat screen extends `AppCompatActivity`, so it needs an AppCompat theme. Add this
to **`android/app/src/main/AndroidManifest.xml`**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
  <application ...>
    <!-- your MainActivity ... -->

    <activity
        android:name="com.hubspot.mobilesdk.HubspotWebActivity"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar"
        tools:replace="android:theme" />
  </application>
</manifest>
```

### 3d. (Push only) Firebase

Add `google-services.json` to `android/app/` and configure FCM in your app as usual. See
[Push notifications](#6-push-notifications-optional).

---

## 4. iOS setup

### 4a. Enable Swift Package Manager

HubSpot's iOS SDK ships via SPM, so the plugin uses Flutter's SPM support:

```bash
flutter config --enable-swift-package-manager
```

The plugin already declares the HubSpot SDK in its own `Package.swift`, so Flutter resolves
`HubspotMobileSDK` automatically — you don't add the package manually.

> If the repo is private for your account, sign in to GitHub in
> Xcode → Settings → Accounts so SPM can fetch it.

### 4b. Deployment target 15.0

Set the iOS deployment target to **15.0** (Xcode → Runner target → General, or
`ios/Flutter/AppFrameworkInfo.plist` / project settings).

### 4c. Add the config file to the app target

Add `Hubspot-Info.plist` to your Runner target (note the casing: capital `H`, capital `I`,
lowercase `s`):

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click the **Runner** group → **Add Files to "Runner"…**
3. Select `Hubspot-Info.plist`
4. ✅ Check **Add to targets: Runner**

```xml
<!-- Hubspot-Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>portalId</key>      <string>YOUR_PORTAL_ID</string>
  <key>hublet</key>        <string>na1</string>
  <key>environment</key>   <string>prod</string>
  <key>defaultChatFlow</key><string>your-chatflow</string>
</dict>
</plist>
```

---

## 5. Use the plugin

All access is through the singleton `HubspotMobileChat.instance`. Every method is
`async` (returns `Future<void>`) except the `onMessagePush` stream.

### Call order at a glance

```
app start ─► configure()                [REQUIRED, once, before anything else]
                │
                ├─ setUserIdentity()     [OPTIONAL · before openChat]
                ├─ setChatProperties()   [OPTIONAL · before openChat]
                ├─ registerPushToken()   [OPTIONAL · anytime after configure]
                │
                ▼
            openChat()                   [REQUIRED to show chat · after configure]
                │
                ▼
            logout()                     [OPTIONAL · e.g. on sign-out]
```

Rule of thumb: **`configure()` first, always.** Anything that shapes the conversation
(`setUserIdentity`, `setChatProperties`) must run **before** `openChat()` to take effect
for that session.

### Methods

#### `configure()` — REQUIRED, call first
```dart
await hubspot.configure();
```
Initializes the native SDK from the bundled config file (`hubspot-info.json` /
`Hubspot-Info.plist`). Call **once** at app start (or before first chat use). Every other
method depends on this. Throws `HubspotConfigError` if the config is missing/invalid.

#### `setUserIdentity({email, identityToken})` — OPTIONAL, before `openChat`
```dart
await hubspot.setUserIdentity(
  email: 'visitor@example.com',
  identityToken: serverGeneratedToken,
);
```
Ties the conversation to a known HubSpot contact. `identityToken` is a HubSpot visitor
identification token **generated by your server** — never hardcode it. Skip this for an
**anonymous** chat. Must be called **before** `openChat()` to apply to that session.
*Recommended* if you have logged-in users; otherwise optional.

#### `setChatProperties(Map<ChatPropertyKey, String>)` — OPTIONAL, before `openChat`
```dart
await hubspot.setChatProperties({
  ChatPropertyKey.cameraPermissions: 'granted',
  ChatPropertyKey.notificationPermissions: 'denied',
});
```
Attaches custom context for agents, for the current app session. Keys are
`ChatPropertyKey` values: `cameraPermissions`, `photoPermissions`,
`notificationPermissions`, `locationPermissions`. Call **before** `openChat()`.

#### `openChat({String? chatFlow, PushData? pushData})` — REQUIRED to show chat
```dart
await hubspot.openChat();                       // portal default flow
await hubspot.openChat(chatFlow: 'support');     // specific flow
await hubspot.openChat(pushData: pushFromStream); // open a pushed conversation
```
Presents the native chat UI (full-screen Activity on Android, modal SwiftUI view on iOS).
`chatFlow` is **optional** — omit it to use the portal's default flow. `pushData` is
**optional** — pass a `PushData` from `onMessagePush` to open the conversation a
notification refers to. Must be called **after** `configure()`.

#### `registerPushToken(String token)` — OPTIONAL, for push
```dart
await hubspot.registerPushToken(fcmOrApnsToken);
```
Forwards your app-obtained FCM (Android) / APNs (iOS) token to the SDK so the visitor can
receive chat push notifications. Your app owns push registration; this only hands the
token over. Call any time after `configure()`. See [Push notifications](#6-push-notifications-optional).

#### `onMessagePush` → `Stream<PushData>` — OPTIONAL, for push
```dart
final sub = hubspot.onMessagePush.listen((push) {
  hubspot.openChat(pushData: push); // e.g. open the conversation on tap
});
// ... later: sub.cancel();
```
A broadcast stream of new-message push events. Subscribe once (e.g. in `initState`) and
cancel when done. Pairs with `registerPushToken`.

#### `logout()` — OPTIONAL
```dart
await hubspot.logout();
```
Clears stored identity and chat properties for future sessions (e.g. when the user signs
out). A later `openChat()` starts anonymous again.

### Quick reference

| Method | Status | When | Notes |
|--------|--------|------|-------|
| `configure()` | **Required** | App start, before all | Throws `HubspotConfigError` on bad config |
| `setUserIdentity()` | Optional (recommended if you have users) | Before `openChat` | Server-generated token, pass-through |
| `setChatProperties()` | Optional | Before `openChat` | Session-scoped context |
| `openChat()` | **Required to show chat** | After `configure` | `chatFlow` + `pushData` optional |
| `registerPushToken()` | Optional | After `configure` | App owns FCM/APNs |
| `onMessagePush` | Optional | Subscribe early | Broadcast `Stream<PushData>` |
| `logout()` | Optional | On sign-out | Resets to anonymous |

---

## 6. Push notifications (optional)

Your app owns FCM (Android) / APNs (iOS) registration. The plugin consumes the token and
surfaces new-message events.

```dart
// Observe new-message pushes.
hubspot.onMessagePush.listen((push) {
  // e.g. open the pushed conversation
  hubspot.openChat(pushData: push);
});

// After you obtain the device token from your push setup:
await hubspot.registerPushToken(deviceToken);
```

**Android** — register HubSpot's messaging service (or forward from your own) in the app
manifest:

```xml
<service
    android:name="com.debuggersight.hubspot_mobile_chat.HubspotPushService"
    android:exported="false">
  <intent-filter>
    <action android:name="com.google.firebase.MESSAGING_EVENT" />
  </intent-filter>
</service>
```

**iOS** — forward remote notifications from your `AppDelegate`:

```swift
PushBridge.shared.handleRemoteNotification(userInfo)
```

---

## 7. Errors

Every method reports failures through one contract:

- `HubspotConfigError` — missing/invalid config, or open-before-configure.
- `UnsupportedError` — called on an unsupported platform (web/desktop).

No method crashes the host app.

```dart
try {
  await hubspot.configure();
} on HubspotConfigError catch (e) {
  print('HubSpot config problem: ${e.message}');
}
```

---

## 8. Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `Couldn't find a configuration at the expected path Hubspot-Info.plist` | iOS config not added to the Runner **target** (step 4c), or wrong filename casing (`Hubspot-Info.plist`). |
| `minSdkVersion 24 cannot be smaller than 26` | Set Android `minSdk 26` (step 3a). |
| `You need to use a Theme.AppCompat theme` crash on open chat | Add the `HubspotWebActivity` theme override (step 3c). |
| `The system isn't responding to your request right now` | HubSpot-side: wrong **hublet**/region, or the chat flow isn't **published** / not assigned to the mobile SDK. |
| `Missing Chat Flow` | No `chatFlow` passed and no usable default — set `defaultChatFlow` in the config or pass `chatFlow`. |
| iOS "no versions of mobile-chat-sdk-ios match" | iOS SDK latest is 1.0.7; ensure SPM is enabled (step 4a). |

---

## 9. Security

- Config files (`hubspot-info.json`, `Hubspot-Info.plist`, `google-services.json`) are
  app-supplied — keep them out of version control (gitignored; ship `.example` templates).
- Identity tokens are generated by your server and only passed through; never hardcode them.

---

## Architecture (for contributors)

The Pigeon contract (`pigeons/messages.dart`) is the single source of truth; it generates
`lib/src/messages.g.dart` plus the Kotlin/Swift host-API stubs. The Dart facade does only
marshalling + enum mapping + the push stream; all SDK calls live in the native plugin
classes. Never hand-edit generated files — edit the Pigeon contract and run
`dart run pigeon --input pigeons/messages.dart`.

---

## Complete example

A full, runnable example lives in [`example/`](example/). Minimal end-to-end usage:

```dart
import 'package:flutter/material.dart';
import 'package:hubspot_mobile_chat/hubspot_mobile_chat.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _hubspot = HubspotMobileChat.instance;
  String _status = 'Not initialized';

  Future<void> _initAndOpen() async {
    try {
      await _hubspot.configure();              // required, first
      // await _hubspot.setUserIdentity(...);  // optional, before openChat
      await _hubspot.openChat();               // anonymous chat (portal default flow)
      setState(() => _status = 'Chat opened');
    } on HubspotConfigError catch (e) {
      setState(() => _status = 'Config error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('HubSpot Mobile Chat')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_status),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initAndOpen,
                child: const Text('Open Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## License

Released under the [MIT License](LICENSE). Copyright (c) 2025 Osama Habib.
