# Known Issues & Follow-ups — hubspot_mobile_chat

Running log of open issues to fix later. Status: 🔴 open · 🟡 needs-info · 🟢 resolved.

---

## I-001 🟡 iOS chat: "The system isn't responding to your request right now"

- **Where**: iOS sim, Open Chat (portal `25742216`, hublet `eu1`, env `prod`, flow `qanoniah-mobile`).
- **Symptom**: `HubspotChatView` presents (shell + spinner) then shows
  "The system isn't responding to your request right now. Please try again in a minute."
- **Assessment**: HubSpot **backend/config side**, not the plugin — configure() succeeded,
  chat view presented, SDK connected. Plugin pipeline confirmed working.
- **Suspects**: chat flow `qanoniah-mobile` not published / not assigned to mobile SDK
  channel; hublet/environment mismatch; mobile chat not enabled for portal; transient.
- **Next**: (1) retry; (2) clear chatFlow field → use portal default; (3) verify flow is
  published + targeted to mobile in HubSpot; (4) confirm hublet `eu1` matches portal.
- **2026-06-17 narrowed**: blank chatFlow → SDK shows "Missing Chat Flow"; named
  `qanoniah-mobile` → "system isn't responding". So plugin forwards chatFlow correctly;
  backend rejects the named flow. Cause is HubSpot-side: flow not published / not connected
  to a channel, OR hublet/region mismatch (plist `eu1`). Verify hublet via browser login URL
  (`app.hubspot.com`=na1, `app-eu1.hubspot.com`=eu1) and confirm flow published for mobile.

---

## I-002 🟢 Android API rewritten against real SDK 1.0.8

- **Resolved 2026-06-17**: inspected the real AAR. Correct package is
  `com.hubspot.mobilesdk` (not `com.hubspot.mobilechat`). SDK 1.0.0 lacked
  identity/logout; **1.0.8** has the full API. Rewrote `HubspotMobileChatPlugin.kt`:
  `HubspotManager.getInstance(ctx)`, `configure()` (throws `HubspotConfigError`),
  `setUserIdentity(email, token)`, `setChatProperties(Map<String,String>)`,
  `logout()` + `setPushToken()` are **suspend** (run via coroutine), openChat via
  `Intent(HubspotWebActivity)` with `"chatflow"` extra. Push service uses
  `HubspotManager.isHubspotNotification(map)` + `PushNotificationChatData(map)`.
- **Still pending**: actual Android emulator compile/run (T035) + minSdk 26 set.

---

## I-003 🟢 Android SDK version pinned

- **Resolved**: pinned `mobile-chat-sdk-android:1.0.8` (latest). iOS stays `1.0.7` (no 1.0.8
  tag exists for iOS — each platform pinned to its own latest). Min API raised to 26 (SDK
  requirement) in plugin + example gradle.

---

## I-004 🟡 Confirm iOS SDK signatures used

- **Where**: `ios/.../HubspotMobileChatPlugin.swift`.
- **Open**: `HubspotChatView(manager:chatFlow:)` — add `pushData:` if the init requires it;
  `setPushToken(apnsPushToken: Data)` — currently fed a hex-decoded APNs token string, verify
  the app passes a hex string (not base64/raw). Build succeeded, so signatures compile; verify
  runtime behavior for push.

---

## I-005 🔴 chatFlow parity Android vs iOS

- **Where**: `openChat` Android passes `chatFlow` as an Intent extra (`HubspotWebActivity`);
  unconfirmed the Android SDK honors it. iOS passes it to `HubspotChatView`.
- **Next**: verify Android applies chatFlow; if unsupported, document the platform difference
  (FR-005/FR-009) instead of silently dropping.

---

## I-006 🟢 Config plist filename casing

- **Resolved**: file must be `Hubspot-Info.plist` (capital I, lowercase s). Renamed; gitignore
  matches; templates + README + research.md corrected.
- **Residual**: spec.md / plan.md / quickstart.md / tasks.md still show `HubSpot-Info.plist`
  (cosmetic doc drift — flagged by /speckit-analyze I1). Fix when convenient.

---

## I-007 🔴 Push notifications not end-to-end tested

- **Where**: Android `HubspotPushService`, iOS `PushBridge`.
- **Next**: with FCM (Android) / APNs (iOS) configured, verify token forwarding +
  `onMessagePush` stream + tap-to-open (SC-005). Needs real device for APNs.
